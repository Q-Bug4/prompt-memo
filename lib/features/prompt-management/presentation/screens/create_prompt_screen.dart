import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prompt_memo/shared/models/prompt.dart';
import 'package:prompt_memo/features/prompt-management/presentation/providers/prompt_providers.dart';
import 'package:logging/logging.dart';

final _logger = Logger('CreatePromptScreen');

/// Screen for creating or editing a prompt
class CreatePromptScreen extends ConsumerStatefulWidget {
  final String? promptId;

  const CreatePromptScreen({super.key, this.promptId});

  @override
  ConsumerState<CreatePromptScreen> createState() => _CreatePromptScreenState();
}

class _CreatePromptScreenState extends ConsumerState<CreatePromptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _collectionId;
  List<String> _tags = [];
  bool _isLoading = false;
  Prompt? _editingPrompt;

  @override
  void initState() {
    super.initState();
    _logger.info('initState, promptId = ${widget.promptId}');
    if (widget.promptId != null) {
      _logger.fine('Creating new prompt');
    } else {
      _logger.fine('Editing prompt: ${widget.promptId}');
      _loadPrompt();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadPrompt() async {
    _logger.fine('_loadPrompt: loading prompt ${widget.promptId}');
    final repository = ref.read(promptRepositoryProvider);
    _editingPrompt = await repository.getPromptById(widget.promptId!);
    if (_editingPrompt != null && mounted) {
      _logger.fine('_loadPrompt: prompt loaded: ${_editingPrompt!.title}');
      setState(() {
        _titleController.text = _editingPrompt!.title;
        _contentController.text = _editingPrompt!.content;
        _collectionId = _editingPrompt!.collectionId;
        _tags = List.from(_editingPrompt!.tags);
      });
    } else {
      _logger.warning('_loadPrompt: prompt not found for id ${widget.promptId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.promptId == null ? 'New Prompt' : 'Edit Prompt'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      hintText: 'Enter a descriptive title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      labelText: 'Prompt Content *',
                      hintText: 'Enter your prompt text here',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 10,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Prompt content is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _collectionId,
                    decoration: const InputDecoration(
                      labelText: 'Collection',
                      border: OutlineInputBorder(),
                    ),
                    items: const [],
                    onChanged: (value) {
                      setState(() {
                        _collectionId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        onDeleted: () {
                          setState(() {
                            _tags.remove(tag);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _showAddTagDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Tag'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _savePrompt,
                    icon: const Icon(Icons.save),
                    label: Text(widget.promptId == null ? 'Create' : 'Save'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showAddTagDialog() {
    _logger.fine('_showAddTagDialog called, current tags: $_tags');
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter tag name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final tag = controller.text.trim();
              if (tag.isNotEmpty) {
                _logger.fine('_showAddTagDialog: adding tag: $tag');
                setState(() {
                  if (!_tags.contains(tag)) {
                    _tags.add(tag);
                    _logger.fine('_showAddTagDialog: tag added, new count: ${_tags.length}');
                  } else {
                    _logger.fine('_showAddTagDialog: tag already exists');
                  }
                });
              } else {
                _logger.fine('_showAddTagDialog: tag is empty, ignoring');
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePrompt() async {
    _logger.fine('_savePrompt called, isEditing: ${widget.promptId != null}');
    if (!_formKey.currentState!.validate()) {
      _logger.warning('_savePrompt: validation failed');
      return;
    }
    _logger.fine('_savePrompt: validation passed, saving...');

    setState(() {
      _isLoading = true;
    });

    final repository = ref.read(promptRepositoryProvider);

    try {
      if (widget.promptId == null) {
        await repository.createPrompt(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          collectionId: _collectionId,
          tags: List.from(_tags),
        );
        if (mounted) {
          context.pop();
        }
      } else {
        await repository.updatePrompt(
          Prompt(
            id: widget.promptId!,
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            collectionId: _collectionId,
            tags: List.from(_tags),
            createdAt: _editingPrompt?.createdAt ?? DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        _logger.fine('_savePrompt: invalidating prompt provider');
        // Invalidate the prompt provider so detail screen refreshes
        ref.invalidate(promptProvider(widget.promptId!));
        _logger.fine('_savePrompt: invalidating prompts provider');
        // Also invalidate the prompts list to refresh list view
        ref.invalidate(promptsProvider);
        if (mounted) {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving prompt: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
