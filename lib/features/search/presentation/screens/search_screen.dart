import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prompt_memo/shared/models/prompt.dart';
import 'package:prompt_memo/features/search/data/repositories/search_repository.dart';
import 'package:prompt_memo/features/prompt-management/presentation/providers/collection_providers.dart';
import 'package:logging/logging.dart';

final _logger = Logger('SearchScreen');

/// Screen for searching prompts
class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  List<Prompt> _results = [];
  bool _isSearching = false;
  String? _selectedCollectionId;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
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
    _logger.info('SearchScreen: searching for "$query" in collection $_selectedCollectionId');

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
        _logger.info('SearchScreen: found ${results.length} results');
      }
    } catch (e, s) {
      _logger.severe('SearchScreen: search failed', e, s);
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
    return Scaffold(
      appBar: AppBar(
        title: _buildSearchBar(),
        actions: [
          if (_selectedCollectionId != null || _searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _results = [];
                  _selectedCollectionId = null;
                });
              },
              tooltip: 'Clear',
            ),
        ],
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _searchController.text.isEmpty
              ? _buildEmptyState()
              : _results.isEmpty
                  ? _buildEmptyResults()
                  : _buildResults(),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: 'Search prompts...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey.shade500),
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
      style: const TextStyle(fontSize: 18),
      textInputAction: TextInputAction.search,
      onSubmitted: (value) => _performSearch(value),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Search for prompts',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter keywords to find prompts by title or content',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords or clear the collection filter',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final prompt = _results[index];
        return _buildResultCard(context, prompt);
      },
    );
  }

  Widget _buildResultCard(BuildContext context, Prompt prompt) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () {
          _logger.info('SearchScreen: result tapped - ${prompt.id}');
          context.push('/prompt/${prompt.id}');
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(prompt.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) return 'Just now';
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return '${date.month}/${date.day}/${date.year}';
  }
}
