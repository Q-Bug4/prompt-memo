import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:prompt_memo/features/prompt-management/presentation/providers/collection_providers.dart';
import 'package:prompt_memo/features/prompt-management/presentation/providers/prompt_providers.dart';
import 'package:prompt_memo/shared/models/collection.dart';
import 'package:prompt_memo/shared/models/prompt.dart';
import 'package:prompt_memo/shared/models/result_sample.dart';
import 'package:logging/logging.dart';

final _logger = Logger('CollectionDetailScreen');

/// Screen displaying details of a collection and its prompts
class CollectionDetailScreen extends ConsumerStatefulWidget {
  /// The ID of the collection to display
  final String collectionId;

  const CollectionDetailScreen({super.key, required this.collectionId});

  @override
  ConsumerState<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends ConsumerState<CollectionDetailScreen> {
  final Map<String, List<ResultSample>> _promptSamples = {};
  bool _isLoadingSamples = false;

  @override
  void initState() {
    super.initState();
    _logger.info('CollectionDetailScreen: initState - collectionId: ${widget.collectionId}');
  }

  @override
  void dispose() {
    _logger.fine('CollectionDetailScreen: dispose');
    super.dispose();
  }

  Future<void> _loadAllResultSamples(List<Prompt> prompts) async {
    if (_isLoadingSamples) {
      return;
    }

    _isLoadingSamples = true;
    final startTime = DateTime.now();

    try {
      final repository = ref.read(promptRepositoryProvider);
      final Map<String, List<ResultSample>> samplesMap = {};

      for (final prompt in prompts) {
        if (_promptSamples.containsKey(prompt.id)) {
          continue;
        }

        try {
          final samples = await repository.getResultSamples(prompt.id);
          samplesMap[prompt.id] = samples;
        } catch (e, s) {
          _logger.warning('CollectionDetailScreen: failed to load samples for prompt ${prompt.id}', e, s);
        }
      }

      if (mounted) {
        setState(() {
          _promptSamples.addAll(samplesMap);
          _isLoadingSamples = false;
        });

        final duration = DateTime.now().difference(startTime);
        _logger.fine('CollectionDetailScreen: loaded samples in ${duration.inMilliseconds}ms');
      }
    } catch (e, s) {
      _logger.severe('CollectionDetailScreen: failed to load result samples', e, s);
      if (mounted) {
        setState(() {
          _isLoadingSamples = false;
        });
      }
    }
  }

  Future<void> _refreshCollection() async {
    _logger.info('CollectionDetailScreen: refreshing collection');
    ref.invalidate(collectionProvider(widget.collectionId));
    ref.invalidate(promptsByCollectionProvider(widget.collectionId));
    _promptSamples.clear();
  }

  @override
  Widget build(BuildContext context) {
    _logger.finest('CollectionDetailScreen: build - collectionId: ${widget.collectionId}');

    final collectionAsync = ref.watch(collectionProvider(widget.collectionId));
    final promptsAsync = ref.watch(promptsByCollectionProvider(widget.collectionId));

    return Scaffold(
      body: collectionAsync.when(
        data: (collection) {
          if (collection == null) {
            return _buildNotFound();
          }
          return _buildContent(collection, promptsAsync);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildError(error, stack),
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Symbols.folder_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Collection not found', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object error, StackTrace stack) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Symbols.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Failed to load collection', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text(error.toString(), style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Collection collection, AsyncValue<List<Prompt>> promptsAsync) {
    // Load samples when prompts are available
    promptsAsync.whenData((prompts) {
      Future.microtask(() => _loadAllResultSamples(prompts));
    });

    final promptCount = promptsAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(collection.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            onPressed: () => _showAddPromptDialog(collection),
            tooltip: 'Add Existing Prompt',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _logger.info('CollectionDetailScreen: edit button pressed');
              context.push('/collection/${collection.id}/edit');
            },
            tooltip: 'Edit Collection',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(collection),
            tooltip: 'Delete Collection',
          ),
        ],
      ),
      body: Column(
        children: [
          // Collection header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.folder, size: 32, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            collection.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (collection.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              collection.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.note, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '$promptCount prompt${promptCount == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const Spacer(),
                    Text(
                      'Created ${_formatDate(collection.createdAt)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Prompts list
          Expanded(
            child: promptsAsync.when(
              data: (prompts) {
                if (prompts.isEmpty) {
                  return _buildEmptyState(collection);
                }
                return _buildPromptList(prompts);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Symbols.error, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Failed to load prompts'),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _refreshCollection,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Prompt to Collection',
        onPressed: () async {
          _logger.info('CollectionDetailScreen: FAB pressed - adding prompt to collection');
          await context.push('/prompt/new?collectionId=${collection.id}');
          if (mounted) {
            _refreshCollection();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(Collection collection) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No prompts in "${collection.name}"',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + to add your first prompt',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptList(List<Prompt> prompts) {
    return ListView.builder(
      itemCount: prompts.length,
      itemBuilder: (ctx, index) {
        final prompt = prompts[index];
        return _buildPromptCard(prompt);
      },
    );
  }

  Widget _buildPromptCard(Prompt prompt) {
    final samples = _promptSamples[prompt.id] ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () async {
          _logger.info('CollectionDetailScreen: prompt card tapped - ${prompt.id}');
          await context.push('/prompt/${prompt.id}');
          if (mounted) {
            _refreshCollection();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                prompt.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                prompt.content.length > 150
                    ? '${prompt.content.substring(0, 150)}...'
                    : prompt.content,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (samples.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildAttachmentThumbnails(samples.take(3).toList()),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(prompt.updatedAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentThumbnails(List<ResultSample> samples) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: samples.map((sample) {
        switch (sample.fileType) {
          case FileType.text:
            return _buildTextThumbnail(sample);
          case FileType.image:
            return _buildImageThumbnail(sample);
          case FileType.video:
            return const SizedBox.shrink();
        }
      }).toList(),
    );
  }

  Widget _buildTextThumbnail(ResultSample sample) {
    return FutureBuilder<String>(
      future: _readFileContent(sample.filePath, 20),
      builder: (context, snapshot) {
        final content = snapshot.data ?? '';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            content.isEmpty ? '...' : '$content...',
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }

  Widget _buildImageThumbnail(ResultSample sample) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(sample.filePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
            );
          },
        ),
      ),
    );
  }

  Future<String> _readFileContent(String path, int maxChars) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        return content.length > maxChars ? content.substring(0, maxChars) : content;
      }
    } catch (e) {
      // Ignore errors
    }
    return '';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  void _showDeleteDialog(Collection collection) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Collection'),
        content: Text(
          'Are you sure you want to delete "${collection.name}"?\n\n'
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
              await _deleteCollection(collection.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCollection(String id) async {
    _logger.info('CollectionDetailScreen: deleting collection $id');
    try {
      final repository = ref.read(collectionRepositoryProvider);
      await repository.deleteCollection(id);
      _logger.info('CollectionDetailScreen: collection deleted');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collection deleted'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e, s) {
      _logger.severe('CollectionDetailScreen: failed to delete collection', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete collection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddPromptDialog(Collection collection) {
    _logger.info('CollectionDetailScreen: showing add prompt dialog for ${collection.id}');
    showDialog(
      context: context,
      builder: (ctx) => _AddPromptDialog(collectionId: collection.id),
    );
  }
}

/// Dialog for adding existing prompts to a collection
class _AddPromptDialog extends ConsumerStatefulWidget {
  final String collectionId;

  const _AddPromptDialog({required this.collectionId});

  @override
  ConsumerState<_AddPromptDialog> createState() => _AddPromptDialogState();
}

class _AddPromptDialogState extends ConsumerState<_AddPromptDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    _logger.finest('_AddPromptDialog: build - collectionId: ${widget.collectionId}');

    // Get all prompts and current collection prompts
    final allPromptsAsync = ref.watch(promptsProvider);
    final collectionPromptsAsync = ref.watch(promptsByCollectionProvider(widget.collectionId));

    return AlertDialog(
      title: const Text('Add Existing Prompt'),
      content: SizedBox(
        width: double.maxFinite,
        child: allPromptsAsync.when(
          data: (allPrompts) {
            return collectionPromptsAsync.when(
              data: (collectionPrompts) {
                // Filter out prompts that are already in this collection
                final collectionPromptIds = collectionPrompts.map((p) => p.id).toSet();
                final availablePrompts = allPrompts.where((p) => !collectionPromptIds.contains(p.id)).toList();

                if (availablePrompts.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No available prompts to add'),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: availablePrompts.length,
                  itemBuilder: (context, index) {
                    final prompt = availablePrompts[index];
                    return ListTile(
                      title: Text(prompt.title),
                      subtitle: Text(
                        prompt.content.length > 50
                            ? '${prompt.content.substring(0, 50)}...'
                            : prompt.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: prompt.collectionId != null
                          ? Chip(
                              label: Text(
                                ref.read(collectionProvider(prompt.collectionId!)).value?.name ?? 'Other',
                                style: const TextStyle(fontSize: 12),
                              ),
                              avatar: const Icon(Icons.folder, size: 16),
                            )
                          : null,
                      onTap: _isLoading ? null : () => _addPromptToCollection(prompt),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Future<void> _addPromptToCollection(Prompt prompt) async {
    setState(() => _isLoading = true);
    _logger.info('_AddPromptDialog: adding prompt ${prompt.id} to collection ${widget.collectionId}');

    try {
      final repository = ref.read(promptRepositoryProvider);
      await repository.updatePrompt(
        prompt.copyWith(
          collectionId: widget.collectionId,
          updatedAt: DateTime.now(),
        ),
      );

      _logger.info('_AddPromptDialog: prompt added successfully');

      // Invalidate providers to refresh UI
      ref.invalidate(promptsByCollectionProvider(widget.collectionId));

      // Important: Also invalidate the prompt's original collection list (if it was in one)
      if (prompt.collectionId != null && prompt.collectionId != widget.collectionId) {
        ref.invalidate(promptsByCollectionProvider(prompt.collectionId!));
      }

      ref.invalidate(collectionListProvider);
      ref.invalidate(promptsProvider);
      ref.invalidate(promptProvider(prompt.id)); // Invalidate the specific prompt to update its collection info

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prompt added to collection'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e, s) {
      _logger.severe('_AddPromptDialog: failed to add prompt', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add prompt: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }
}
