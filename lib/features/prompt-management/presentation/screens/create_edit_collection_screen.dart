import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prompt_memo/features/prompt-management/presentation/providers/collection_providers.dart';
import 'package:prompt_memo/shared/models/collection.dart';
import 'package:logging/logging.dart';

final _logger = Logger('CreateEditCollectionScreen');

/// Screen for creating or editing a collection
class CreateEditCollectionScreen extends ConsumerStatefulWidget {
  /// Collection ID to edit, null for creating a new collection
  final String? collectionId;

  const CreateEditCollectionScreen({super.key, this.collectionId});

  @override
  ConsumerState<CreateEditCollectionScreen> createState() => _CreateEditCollectionScreenState();
}

class _CreateEditCollectionScreenState extends ConsumerState<CreateEditCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  Collection? _collection;

  @override
  void initState() {
    super.initState();
    _logger.info('CreateEditCollectionScreen: initState - collectionId: ${widget.collectionId}');

    if (widget.collectionId != null) {
      // Edit mode: load existing collection
      _loadCollection();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCollection() async {
    _logger.info('CreateEditCollectionScreen: loading collection ${widget.collectionId}');
    final collectionAsync = ref.read(collectionProvider(widget.collectionId!));

    collectionAsync.when(
      data: (collection) {
        if (collection != null) {
          setState(() {
            _collection = collection;
            _nameController.text = collection.name;
            _descriptionController.text = collection.description;
          });
        } else {
          _logger.warning('CreateEditCollectionScreen: collection not found');
          _showErrorSnackBar('Collection not found');
          context.pop();
        }
      },
      loading: () {
        setState(() => _isLoading = true);
      },
      error: (error, stack) {
        _logger.severe('CreateEditCollectionScreen: failed to load collection', error, stack);
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to load collection');
        context.pop();
      },
    );
  }

  Future<void> _saveCollection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    _logger.info('CreateEditCollectionScreen: saving collection');

    try {
      final repository = ref.read(collectionRepositoryProvider);

      if (widget.collectionId == null) {
        // Create new collection
        _logger.info('CreateEditCollectionScreen: creating new collection');
        final collection = await repository.createCollection(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
        );
        _logger.info('CreateEditCollectionScreen: collection created - ${collection.id}');
      } else {
        // Update existing collection
        _logger.info('CreateEditCollectionScreen: updating collection ${widget.collectionId}');
        await repository.updateCollection(Collection(
          id: widget.collectionId!,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          createdAt: _collection!.createdAt,
          updatedAt: DateTime.now(),
        ));
        _logger.info('CreateEditCollectionScreen: collection updated');
      }

      // Invalidate providers to refresh data
      ref.invalidate(collectionListProvider);

      if (mounted) {
        _showSuccessSnackBar(widget.collectionId == null ? 'Collection created' : 'Collection updated');
        context.pop();
      }
    } catch (e, s) {
      _logger.severe('CreateEditCollectionScreen: failed to save collection', e, s);
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to save collection: ${e.toString()}');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.finest('CreateEditCollectionScreen: build - collectionId: ${widget.collectionId}');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.collectionId == null ? 'New Collection' : 'Edit Collection'),
        actions: [
          if (widget.collectionId != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _showDeleteDialog,
              tooltip: 'Delete Collection',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Collection Name *',
                        hintText: 'e.g., Work Prompts, Personal Ideas',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 100,
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a collection name';
                        }
                        if (value.trim().length > 100) {
                          return 'Collection name must be 100 characters or less';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Optional description for this collection',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      maxLength: 500,
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _saveCollection,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(widget.collectionId == null ? 'Create Collection' : 'Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Collection'),
        content: Text(
          'Are you sure you want to delete "${_nameController.text}"?\n\n'
          'The prompts inside will not be deleted, but they will no longer be in this collection.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteCollection();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCollection() async {
    setState(() => _isLoading = true);
    _logger.info('CreateEditCollectionScreen: deleting collection ${widget.collectionId}');

    try {
      final repository = ref.read(collectionRepositoryProvider);
      await repository.deleteCollection(widget.collectionId!);
      _logger.info('CreateEditCollectionScreen: collection deleted');

      // Invalidate providers to refresh data
      ref.invalidate(collectionListProvider);

      if (mounted) {
        _showSuccessSnackBar('Collection deleted');
        context.pop(); // Return to previous screen
      }
    } catch (e, s) {
      _logger.severe('CreateEditCollectionScreen: failed to delete collection', e, s);
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to delete collection: ${e.toString()}');
    }
  }
}
