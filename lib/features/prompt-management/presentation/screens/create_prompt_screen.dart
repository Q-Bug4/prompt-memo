import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prompt_memo/shared/models/prompt.dart';
import 'package:prompt_memo/shared/models/result_sample.dart';
import 'package:prompt_memo/features/prompt-management/presentation/providers/prompt_providers.dart';
import 'package:prompt_memo/features/prompt-management/presentation/providers/collection_providers.dart';
import 'package:prompt_memo/features/prompt-management/presentation/widgets/file_picker_dialog.dart';
import 'package:prompt_memo/features/prompt-management/domain/services/file_picker_service.dart';
import 'package:prompt_memo/core/storage/filesystem_storage.dart';
import 'package:logging/logging.dart';

class PendingSample {
  final String fileName;
  final List<int> bytes;
  final PickedFileType fileType;
  final int size;

  const PendingSample({
    required this.fileName,
    required this.bytes,
    required this.fileType,
    required this.size,
  });
}

final _logger = Logger('CreatePromptScreen');

/// Screen for creating or editing a prompt
class CreatePromptScreen extends ConsumerStatefulWidget {
  final String? promptId;
  final String? initialCollectionId;

  const CreatePromptScreen({
    super.key,
    this.promptId,
    this.initialCollectionId,
  });

  @override
  ConsumerState<CreatePromptScreen> createState() => _CreatePromptScreenState();
}

class _CreatePromptScreenState extends ConsumerState<CreatePromptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _collectionId;
  List<String> _tags = [];
  List<PendingSample> _pendingSamples = [];
  bool _isLoading = false;
  bool _isSavingSamples = false;
  Prompt? _editingPrompt;
  String? _newPromptId;

  @override
  void initState() {
    super.initState();
    final mode = widget.promptId != null ? 'Edit' : 'Create';
    _logger.info(
      'CreatePromptScreen: initState - mode: $mode, promptId: ${widget.promptId ?? "new"}',
    );

    // Initialize collectionId from initialCollectionId (for new prompts) or from existing prompt
    if (widget.promptId == null) {
      _collectionId = widget.initialCollectionId;
      _logger.fine(
        'CreatePromptScreen: initial collectionId set to: $_collectionId',
      );
    }

    if (widget.promptId != null) {
      _logger.fine(
        'CreatePromptScreen: editing existing prompt - loading data',
      );
      _loadPrompt();
    } else {
      _logger.fine('CreatePromptScreen: creating new prompt - no data to load');
    }
  }

  @override
  void dispose() {
    _logger.fine('CreatePromptScreen: dispose - cleaning up controllers');
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadPrompt() async {
    _logger.info(
      'CreatePromptScreen: _loadPrompt - loading prompt ${widget.promptId}',
    );
    final startTime = DateTime.now();

    try {
      final repository = ref.read(promptRepositoryProvider);
      final prompt = await repository.getPromptById(widget.promptId!);

      if (prompt != null) {
        _editingPrompt = prompt;
        if (mounted) {
          _logger.fine('CreatePromptScreen: prompt loaded - ${prompt.title}');
          setState(() {
            _titleController.text = prompt.title;
            _contentController.text = prompt.content;
            _collectionId = prompt.collectionId;
            _tags = List.from(prompt.tags);
          });

          final duration = DateTime.now().difference(startTime);
          _logger.fine(
            'CreatePromptScreen: prompt loaded successfully in ${duration.inMilliseconds}ms',
          );
        }
      } else {
        _logger.warning(
          'CreatePromptScreen: prompt not found for id: ${widget.promptId}',
        );
        if (mounted) {
          _showErrorSnackBar('Prompt not found');
          context.pop();
        }
      }
    } catch (e, s) {
      _logger.severe('CreatePromptScreen: failed to load prompt', e, s);
      if (mounted) {
        _showErrorSnackBar('Failed to load prompt: $e');
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.finest(
      'CreatePromptScreen: build - isLoading: $_isLoading, isEditing: ${widget.promptId != null}',
    );

    // Watch collections for dropdown
    final collectionsAsync = ref.watch(collectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.promptId == null ? 'New Prompt' : 'Edit Prompt'),
        bottom:
            _isSavingSamples
                ? PreferredSize(
                  preferredSize: const Size.fromHeight(4),
                  child: LinearProgressIndicator(minHeight: 4),
                )
                : null,
      ),
      body:
          _isLoading
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
                      maxLength: 100,
                      buildCounter:
                          (
                            context, {
                            required currentLength,
                            required isFocused,
                            maxLength,
                          }) => null,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          _logger.finer(
                            'CreatePromptScreen: title validation failed',
                          );
                          return 'Title is required';
                        }
                        if (value.trim().length > 100) {
                          return 'Title must be 100 characters or less';
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
                      maxLength: 5000,
                      buildCounter:
                          (
                            context, {
                            required currentLength,
                            required isFocused,
                            maxLength,
                          }) => null,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          _logger.finer(
                            'CreatePromptScreen: content validation failed',
                          );
                          return 'Prompt content is required';
                        }
                        if (value.length > 5000) {
                          return 'Content must be 5000 characters or less';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    collectionsAsync.when(
                      data: (collections) {
                        return DropdownButtonFormField<String>(
                          value: _collectionId,
                          decoration: const InputDecoration(
                            labelText: 'Collection',
                            hintText: 'Optional - add to a collection',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('No Collection'),
                            ),
                            ...collections.map(
                              (collection) => DropdownMenuItem(
                                value: collection.id,
                                child: Text(collection.name),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            _logger.finest(
                              'CreatePromptScreen: collection changed to: $value',
                            );
                            setState(() {
                              _collectionId = value;
                            });
                          },
                        );
                      },
                      loading:
                          () => DropdownButtonFormField<String>(
                            value: null,
                            decoration: const InputDecoration(
                              labelText: 'Collection',
                              border: OutlineInputBorder(),
                            ),
                            items: const [],
                            onChanged: null,
                            disabledHint: const Text('Loading collections...'),
                          ),
                      error:
                          (error, stack) => DropdownButtonFormField<String>(
                            value: _collectionId,
                            decoration: const InputDecoration(
                              labelText: 'Collection',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: null,
                                child: Text('No Collection'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _collectionId = value;
                              });
                            },
                          ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _tags.map((tag) {
                            return Chip(
                              label: Text(tag),
                              onDeleted: () {
                                _logger.finest(
                                  'CreatePromptScreen: removing tag: $tag',
                                );
                                setState(() {
                                  _tags.remove(tag);
                                  _logger.finest(
                                    'CreatePromptScreen: tag removed, remaining: ${_tags.length}',
                                  );
                                });
                              },
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Result Samples Section
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Result Samples',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_pendingSamples.length} ${_pendingSamples.length == 1 ? "sample" : "samples"}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_pendingSamples.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.attach_file,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No samples added yet',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ..._pendingSamples.asMap().entries.map((entry) {
                        final index = entry.key;
                        final sample = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              sample.fileType == PickedFileType.image
                                  ? Icons.image
                                  : sample.fileType == PickedFileType.video
                                  ? Icons.videocam
                                  : Icons.description,
                            ),
                            title: Text(sample.fileName),
                            subtitle: Text('${_formatFileSize(sample.size)}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _logger.finest(
                                  'CreatePromptScreen: removing sample at index $index',
                                );
                                setState(() {
                                  _pendingSamples.removeAt(index);
                                });
                              },
                            ),
                          ),
                        );
                      }).toList(),

                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _showAddSampleDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Sample'),
                    ),

                    const SizedBox(height: 24),
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

  void _showAddSampleDialog() {
    _logger.info('CreatePromptScreen: showing add sample dialog');
    showDialog(
      context: context,
      builder:
          (ctx) => FilePickerDialog(
            onFileSelected: (file) {
              _logger.fine(
                'CreatePromptScreen: file selected - ${file?.name ?? "null"}',
              );

              if (file == null) {
                _logger.fine('CreatePromptScreen: file selection cancelled');
                return;
              }

              _logger.info(
                'CreatePromptScreen: adding pending sample - ${file.name}',
              );
              setState(() {
                _pendingSamples.add(
                  PendingSample(
                    fileName: file.name,
                    bytes: file.bytes!,
                    fileType: file.type,
                    size: file.size,
                  ),
                );
                _logger.fine(
                  'CreatePromptScreen: pending samples count: ${_pendingSamples.length}',
                );
              });
            },
          ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  FileType _pickedFileTypeToFileType(PickedFileType type) {
    switch (type) {
      case PickedFileType.text:
        return FileType.text;
      case PickedFileType.image:
        return FileType.image;
      case PickedFileType.video:
        return FileType.video;
    }
  }

  void _showAddTagDialog() {
    _logger.info(
      'CreatePromptScreen: showing add tag dialog - current tags: $_tags',
    );
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Add Tag'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Enter tag name'),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _logger.fine('CreatePromptScreen: add tag dialog cancelled');
                  Navigator.pop(ctx);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final tag = controller.text.trim();
                  if (tag.isNotEmpty) {
                    if (_tags.contains(tag)) {
                      _logger.fine(
                        'CreatePromptScreen: tag already exists: $tag',
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tag already exists'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    } else {
                      _logger.info('CreatePromptScreen: adding new tag: $tag');
                      setState(() {
                        _tags.add(tag);
                        _logger.fine(
                          'CreatePromptScreen: tag added, new count: ${_tags.length}',
                        );
                      });
                    }
                  } else {
                    _logger.finer('CreatePromptScreen: tag is empty, ignoring');
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
    final isEditing = widget.promptId != null;
    _logger.info(
      'CreatePromptScreen: _savePrompt - mode: ${isEditing ? "Edit" : "Create"}',
    );

    if (!_formKey.currentState!.validate()) {
      _logger.warning('CreatePromptScreen: form validation failed');
      return;
    }

    _logger.fine('CreatePromptScreen: validation passed, preparing to save...');
    _logger.finest(
      'CreatePromptScreen: title: ${_titleController.text.trim()}',
    );
    _logger.finest(
      'CreatePromptScreen: content length: ${_contentController.text.trim().length} chars',
    );
    _logger.finest('CreatePromptScreen: tags: $_tags');
    _logger.finest('CreatePromptScreen: collectionId: $_collectionId');

    setState(() {
      _isLoading = true;
    });

    final startTime = DateTime.now();
    final repository = ref.read(promptRepositoryProvider);

    try {
      if (!isEditing) {
        // Create new prompt
        _logger.info('CreatePromptScreen: creating new prompt');
        final newPrompt = await repository.createPrompt(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          collectionId: _collectionId,
          tags: List.from(_tags),
        );
        _logger.info(
          'CreatePromptScreen: new prompt created successfully - ${newPrompt.id}',
        );
        _newPromptId = newPrompt.id;

        // Save result samples if any
        if (_pendingSamples.isNotEmpty) {
          _logger.info(
            'CreatePromptScreen: saving ${_pendingSamples.length} samples',
          );
          setState(() {
            _isSavingSamples = true;
          });

          final storage = FilesystemStorage();
          for (final sample in _pendingSamples) {
            try {
              _logger.fine(
                'CreatePromptScreen: saving sample - ${sample.fileName}',
              );
              final filePath = await storage.storeFile(
                promptId: newPrompt.id,
                fileName: sample.fileName,
                bytes: sample.bytes,
              );

              final mimeType = storage.getMimeType(sample.fileName);
              await repository.createResultSample(
                promptId: newPrompt.id,
                filePath: filePath,
                fileName: sample.fileName,
                fileSize: sample.size,
                fileType: _pickedFileTypeToFileType(sample.fileType).name,
                mimeType: mimeType,
              );
              _logger.fine('CreatePromptScreen: sample saved');
            } catch (e, s) {
              _logger.severe('CreatePromptScreen: failed to save sample', e, s);
            }
          }

          setState(() {
            _isSavingSamples = false;
          });
        }

        final duration = DateTime.now().difference(startTime);
        _logger.info(
          'CreatePromptScreen: prompt creation completed in ${duration.inMilliseconds}ms',
        );

        if (mounted) {
          context.pop();
          _logger.fine('CreatePromptScreen: navigated back to home screen');
        }
      } else {
        // Update existing prompt
        _logger.info(
          'CreatePromptScreen: updating existing prompt - ${widget.promptId}',
        );
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
        _logger.info('CreatePromptScreen: prompt updated successfully');

        // Invalidate providers to refresh UI
        _logger.fine('CreatePromptScreen: invalidating prompt provider');
        ref.invalidate(promptProvider(widget.promptId!));

        _logger.fine('CreatePromptScreen: invalidating prompts provider');
        ref.invalidate(promptsProvider);

        _logger.fine('CreatePromptScreen: invalidating collections provider');
        ref.invalidate(collectionListProvider);

        _logger.fine('CreatePromptScreen: reloading prompts list');
        await ref.read(promptListNotifierProvider.notifier).loadPrompts();

        final duration = DateTime.now().difference(startTime);
        _logger.info(
          'CreatePromptScreen: prompt update completed in ${duration.inMilliseconds}ms',
        );

        if (mounted) {
          context.pop();
          _logger.fine('CreatePromptScreen: navigated back to detail screen');
        }
      }
    } catch (e, s) {
      _logger.severe('CreatePromptScreen: failed to save prompt', e, s);
      if (mounted) {
        _showErrorSnackBar('Error saving prompt: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    _logger.warning('CreatePromptScreen: showing error snackbar - $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
