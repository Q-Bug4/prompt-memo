import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:prompt_memo/features/prompt-management/presentation/providers/prompt_providers.dart';
import 'package:prompt_memo/features/prompt-management/presentation/providers/collection_providers.dart';
import 'package:prompt_memo/features/search/data/repositories/search_repository.dart';
import 'package:prompt_memo/shared/models/prompt.dart';
import 'package:prompt_memo/shared/models/collection.dart';
import 'package:prompt_memo/shared/models/result_sample.dart';
import 'package:logging/logging.dart';

final _logger = Logger('PromptListScreen');

/// List item type for mixed collections and prompts
enum ItemType { collection, prompt }

/// Mixed list item
class ListItem {
  final ItemType type;
  final DateTime updatedAt;
  final dynamic data;

  ListItem({required this.type, required this.updatedAt, required this.data});
}

/// Screen displaying list of all prompts and collections
class PromptListScreen extends ConsumerStatefulWidget {
  const PromptListScreen({super.key});

  @override
  ConsumerState<PromptListScreen> createState() => _PromptListScreenState();
}

class _PromptListScreenState extends ConsumerState<PromptListScreen> {
  final Map<String, List<ResultSample>> _promptSamples = {};
  bool _isLoadingSamples = false;

  @override
  void initState() {
    super.initState();
    _logger.fine('PromptListScreen: initState - initializing screen');
    // Auto-load prompts when entering screen
    _refreshPromptsAndSamples();
  }

  @override
  void dispose() {
    _logger.fine('PromptListScreen: dispose - cleaning up resources');
    super.dispose();
  }

  /// Unified method to refresh prompts and samples - use this for all home screen navigation
  Future<void> _refreshPromptsAndSamples() async {
    _logger.info('PromptListScreen: _refreshPromptsAndSamples - starting refresh');
    final startTime = DateTime.now();

    try {
      // Clear samples cache to force reload
      final cachedSamplesCount = _promptSamples.length;
      _promptSamples.clear();
      _logger.finer('PromptListScreen: cleared $cachedSamplesCount cached samples');

      // Load prompts and collections
      _logger.finer('PromptListScreen: loading prompts from repository');
      await ref.read(promptListNotifierProvider.notifier).loadPrompts();
      _logger.finer('PromptListScreen: prompts loaded successfully');

      _logger.finer('PromptListScreen: loading collections');
      await ref.read(collectionListProvider.notifier).loadCollections();
      _logger.finer('PromptListScreen: collections loaded successfully');

      final duration = DateTime.now().difference(startTime);
      _logger.info('PromptListScreen: _refreshPromptsAndSamples completed in ${duration.inMilliseconds}ms');
    } catch (e, s) {
      _logger.severe('PromptListScreen: _refreshPromptsAndSamples failed', e, s);
      rethrow;
    }
  }

  Future<void> _loadAllResultSamples(List<Prompt> prompts) async {
    if (_isLoadingSamples) {
      _logger.finer('PromptListScreen: _loadAllResultSamples - already loading, skipping');
      return;
    }

    _logger.fine('PromptListScreen: _loadAllResultSamples - starting to load samples for ${prompts.length} prompts');
    _isLoadingSamples = true;
    final startTime = DateTime.now();

    try {
      final repository = ref.read(promptRepositoryProvider);
      final Map<String, List<ResultSample>> samplesMap = {};
      int loadedCount = 0;
      int skippedCount = 0;

      for (final prompt in prompts) {
        // Skip if already loaded (unless cache was cleared)
        if (_promptSamples.containsKey(prompt.id)) {
          _logger.finest('PromptListScreen: skipping already loaded samples for prompt ${prompt.id}');
          skippedCount++;
          continue;
        }

        try {
          _logger.finest('PromptListScreen: loading samples for prompt ${prompt.id}');
          final samples = await repository.getResultSamples(prompt.id);
          samplesMap[prompt.id] = samples;
          loadedCount++;
          _logger.finest('PromptListScreen: loaded ${samples.length} samples for prompt ${prompt.id}');
        } catch (e, s) {
          _logger.warning('PromptListScreen: failed to load samples for prompt ${prompt.id}', e, s);
          // Continue loading other prompts
        }
      }

      if (mounted) {
        setState(() {
          _promptSamples.addAll(samplesMap);
          _isLoadingSamples = false;
        });

        final duration = DateTime.now().difference(startTime);
        _logger.fine('PromptListScreen: _loadAllResultSamples completed - loaded: $loadedCount, skipped: $skippedCount, took ${duration.inMilliseconds}ms');
      } else {
        _logger.warning('PromptListScreen: _loadAllResultSamples - widget not mounted, skipping setState');
      }
    } catch (e, s) {
      _logger.severe('PromptListScreen: _loadAllResultSamples failed', e, s);
      if (mounted) {
        setState(() {
          _isLoadingSamples = false;
        });
      }
    }
  }

  /// Merge collections and prompts into a single sorted list
  /// Only shows uncategorized prompts (collectionId is null)
  List<ListItem> _mergeAndSortItems(List<Collection> collections, List<Prompt> prompts) {
    final items = <ListItem>[];

    for (final collection in collections) {
      items.add(ListItem(
        type: ItemType.collection,
        updatedAt: collection.updatedAt,
        data: collection,
      ));
    }

    for (final prompt in prompts) {
      // Only show prompts that are not in any collection
      if (prompt.collectionId == null) {
        items.add(ListItem(
          type: ItemType.prompt,
          updatedAt: prompt.updatedAt,
          data: prompt,
        ));
      }
    }

    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    _logger.finest('PromptListScreen: build - building widget tree');

    // Watch collections and prompts
    final collectionsAsync = ref.watch(collectionListProvider);
    final prompts = ref.watch(promptListNotifierProvider);
    _logger.finest('PromptListScreen: build - displaying ${prompts.length} prompts');

    // Load result samples for prompts that don't have them yet
    Future.microtask(() => _loadAllResultSamples(prompts));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prompt Memo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _logger.info('PromptListScreen: search button pressed - showing search dialog');
              _showSearchDialog();
            },
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _logger.info('PromptListScreen: refresh button pressed');
              _refreshPromptsAndSamples();
            },
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              _logger.info('PromptListScreen: popup menu selected - value: $value');
              if (value == 'create_collection') {
                context.push('/collection/new');
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'create_collection',
                child: ListTile(
                  leading: Icon(Icons.create_new_folder),
                  title: Text('New Collection'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildMixedList(collectionsAsync, prompts),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create Prompt',
        onPressed: () async {
          _logger.info('PromptListScreen: FAB pressed - navigating to /prompt/new');
          await context.push('/prompt/new');
          // Refresh list when returning from create/edit screen
          if (mounted) {
            _logger.info('PromptListScreen: returned from create/edit screen - refreshing list');
            _refreshPromptsAndSamples();
          } else {
            _logger.warning('PromptListScreen: FAB navigation returned but widget not mounted');
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    _logger.finer('PromptListScreen: building empty state widget');
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.note_stack,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No prompts or collections yet',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Create your first prompt or collection to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentThumbnails(List<ResultSample> samples) {
    _logger.finest('PromptListScreen: building ${samples.length} attachment thumbnails');
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
            _logger.finest('PromptListScreen: skipping video attachment ${sample.id}');
            return const SizedBox.shrink(); // Hide video attachments
        }
      }).toList(),
    );
  }

  Widget _buildTextThumbnail(ResultSample sample) {
    _logger.finest('PromptListScreen: building text thumbnail for ${sample.fileName}');
    return FutureBuilder<String>(
      future: _readFileContent(sample.filePath, 20),
      builder: (context, snapshot) {
        final content = snapshot.data ?? '';
        if (snapshot.connectionState == ConnectionState.waiting) {
          _logger.finest('PromptListScreen: loading text content for ${sample.fileName}');
        } else if (snapshot.hasError) {
          _logger.warning('PromptListScreen: failed to load text content for ${sample.fileName}: ${snapshot.error}');
        }
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
    _logger.finest('PromptListScreen: building image thumbnail for ${sample.fileName}');
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
            _logger.warning('PromptListScreen: failed to load image thumbnail for ${sample.fileName}: $error');
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
    _logger.finest('PromptListScreen: reading file content from $path (max: $maxChars chars)');
    try {
      final file = File(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        final truncatedContent = content.length > maxChars ? content.substring(0, maxChars) : content;
        _logger.finest('PromptListScreen: successfully read ${content.length} chars from file');
        return truncatedContent;
      } else {
        _logger.warning('PromptListScreen: file does not exist: $path');
      }
    } catch (e, s) {
      _logger.warning('PromptListScreen: failed to read file: $path', e, s);
    }
    return '';
  }

  Widget _buildPromptCard(BuildContext ctx, Prompt prompt) {
    final samples = _promptSamples[prompt.id] ?? [];
    _logger.finest('PromptListScreen: building card for prompt ${prompt.id} (${prompt.title}) with ${samples.length} samples');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () async {
          _logger.info('PromptListScreen: prompt card tapped - promptId: ${prompt.id}, title: ${prompt.title}');
          await ctx.push('/prompt/${prompt.id}');
          // Refresh list when returning from detail/edit screen
          if (mounted) {
            _logger.info('PromptListScreen: returned from detail screen for prompt ${prompt.id} - refreshing list');
            _refreshPromptsAndSamples();
          } else {
            _logger.warning('PromptListScreen: returned from detail screen but widget not mounted');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      prompt.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
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
                  const Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(prompt.updatedAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  if (prompt.tags.isNotEmpty) ...[
                    ...prompt.tags.take(3).map((tag) => Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(229, 231, 235, 1.0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        )),
                    if (prompt.tags.length > 3)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(229, 231, 235, 1.0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+${prompt.tags.length - 3}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMixedList(List<Collection> collections, List<Prompt> prompts) {
    _logger.finest('PromptListScreen: building mixed list - ${collections.length} collections, ${prompts.length} prompts');

    final items = _mergeAndSortItems(collections, prompts);

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (ctx, index) {
        final item = items[index];
        if (item.type == ItemType.collection) {
          return _buildCollectionCard(item.data as Collection);
        } else {
          return _buildPromptCard(ctx, item.data as Prompt);
        }
      },
    );
  }

  Widget _buildCollectionCard(Collection collection) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.blue.shade50,
      child: InkWell(
        onTap: () async {
          _logger.info('PromptListScreen: collection card tapped - ${collection.id}');
          await context.push('/collection/${collection.id}');
          // Refresh list when returning from collection screen
          if (mounted) {
            _logger.info('PromptListScreen: returned from collection screen - refreshing list');
            _refreshPromptsAndSamples();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.folder, size: 40, color: Colors.blue.shade700),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.name,
                      style: const TextStyle(
                        fontSize: 18,
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.note, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Collection',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const Spacer(),
                        Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(collection.updatedAt),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
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

  void _showSearchDialog() {
    _logger.info('PromptListScreen: showing search dialog');
    showDialog(
      context: context,
      builder: (ctx) => const _SearchDialog(),
    );
  }
}

/// Dialog for searching prompts across all collections
class _SearchDialog extends ConsumerStatefulWidget {
  const _SearchDialog();

  @override
  ConsumerState<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends ConsumerState<_SearchDialog> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  List<Prompt> _results = [];
  bool _isSearching = false;
  String? _selectedCollectionId;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _logger.info('_SearchDialog: searching for "$query" in collection $_selectedCollectionId');

    try {
      final repository = SearchRepository();
      final results = await repository.searchPrompts(
        query: query,
        collectionId: _selectedCollectionId,
      );

      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
        _logger.info('_SearchDialog: found ${results.length} results');
      }
    } catch (e, s) {
      _logger.severe('_SearchDialog: search failed', e, s);
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Search Prompts'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Search prompts...',
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedCollectionId != null)
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: _showCollectionFilter,
                        tooltip: 'Filter by collection',
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => _performSearch(_searchController.text),
                        tooltip: 'Search',
                      ),
                  ],
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => _performSearch(value),
            ),
            const SizedBox(height: 16),
            // Results
            Flexible(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _searchController.text.isEmpty
                      ? _buildEmptyState()
                      : _results.isEmpty
                          ? _buildEmptyResults()
                          : _buildResults(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Enter keywords to search'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            const Text('No results found'),
            if (_selectedCollectionId != null)
              TextButton(
                onPressed: () {
                  setState(() => _selectedCollectionId = null);
                  if (_searchController.text.isNotEmpty) {
                    _performSearch(_searchController.text);
                  }
                },
                child: const Text('Clear collection filter'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final prompt = _results[index];
        return ListTile(
          title: Text(prompt.title),
          subtitle: Text(
            prompt.content.length > 50
                ? '${prompt.content.substring(0, 50)}...'
                : prompt.content,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            _logger.info('_SearchDialog: result tapped - ${prompt.id}');
            Navigator.pop(context);
            context.push('/prompt/${prompt.id}');
          },
        );
      },
    );
  }

  void _showCollectionFilter() {
    final collectionsAsync = ref.watch(collectionsProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Collection'),
        content: SizedBox(
          width: double.maxFinite,
          child: collectionsAsync.when(
            data: (collections) {
              return ListView.builder(
                shrinkWrap: true,
                itemCount: collections.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      leading: const Icon(Icons.folder_open),
                      title: const Text('All Collections'),
                      onTap: () {
                        setState(() => _selectedCollectionId = null);
                        Navigator.pop(ctx);
                        if (_searchController.text.isNotEmpty) {
                          _performSearch(_searchController.text);
                        }
                      },
                    );
                  }
                  final collection = collections[index - 1];
                  return ListTile(
                    leading: const Icon(Icons.folder),
                    title: Text(collection.name),
                    onTap: () {
                      setState(() => _selectedCollectionId = collection.id);
                      Navigator.pop(ctx);
                      if (_searchController.text.isNotEmpty) {
                        _performSearch(_searchController.text);
                      }
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        ),
      ),
    );
  }
}
