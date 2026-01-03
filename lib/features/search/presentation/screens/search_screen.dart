import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prompt_memo/shared/models/prompt.dart';
import 'package:prompt_memo/features/search/data/repositories/search_repository.dart';

/// Screen for searching prompts
class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  List<Prompt> _results = [];
  List<String> _searchHistory = [];
  bool _isSearching = false;
  bool _showFilters = false;
  String? _selectedCollection;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _mostUsedFirst = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
    _loadSearchHistory();
    if (widget.initialQuery != null) {
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

  Future<void> _loadSearchHistory() async {
    final repository = SearchRepository();
    final history = await repository.getSearchHistory();
    if (mounted) {
      setState(() => _searchHistory = history);
    }
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

    try {
      final repository = SearchRepository();
      final results = await repository.searchPrompts(
        query: query,
        collectionId: _selectedCollection,
        startDate: _startDate,
        endDate: _endDate,
        mostUsedFirst: _mostUsedFirst,
      );

      // Save to history
      await repository.saveSearchQuery(query);

      // Reload history
      await _loadSearchHistory();

      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
      }
    } catch (e) {
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
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
            },
            tooltip: 'Filters',
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _results = [];
                  _selectedCollection = null;
                  _startDate = null;
                  _endDate = null;
                  _mostUsedFirst = false;
                });
              },
              tooltip: 'Clear',
            ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilters) _buildFilters(),
          Expanded(
            child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _searchController.text.isEmpty
                      ? _buildSearchHistory()
                      : _results.isEmpty
                          ? _buildEmptyResults()
                          : _buildResults(),
          ),
        ],
      ),
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
      ),
      style: const TextStyle(fontSize: 18),
      textInputAction: TextInputAction.search,
      onSubmitted: (value) => _performSearch(value),
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showCollectionFilter,
                    icon: const Icon(Icons.folder),
                    label: Text(
                      _selectedCollection ?? 'All Collections',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showDateRangePicker,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _getDateRangeText(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Most Used'),
                  selected: _mostUsedFirst,
                  onSelected: (selected) {
                    setState(() => _mostUsedFirst = selected);
                    if (_searchController.text.isNotEmpty) {
                      _performSearch(_searchController.text);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                if (_selectedCollection != null)
                  Chip(
                    label: Text(_selectedCollection!),
                    onDeleted: () {
                      setState(() => _selectedCollection = null);
                      if (_searchController.text.isNotEmpty) {
                        _performSearch(_searchController.text);
                      }
                    },
                  ),
                if (_startDate != null || _endDate != null)
                  Chip(
                    label: Text(_getDateRangeText()),
                    onDeleted: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                      if (_searchController.text.isNotEmpty) {
                        _performSearch(_searchController.text);
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Recent Searches',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ..._searchHistory.map((query) => ListTile(
              leading: const Icon(Icons.history),
              title: Text(query),
              onTap: () {
                _searchController.text = query;
                _performSearch(query);
              },
              trailing: IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () async {
                  final repo = SearchRepository();
                  await repo.clearSearchHistory();
                  await _loadSearchHistory();
                },
                tooltip: 'Clear History',
              ),
            )),
      ],
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
            'Try different keywords or adjust filters',
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Collection'),
        content: const Text('Collection filter coming soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      }
    }
  }

  String _getDateRangeText() {
    if (_startDate == null && _endDate == null) return 'Date Range';
    if (_startDate != null && _endDate != null) {
      return '${_formatDateShort(_startDate!)} - ${_formatDateShort(_endDate!)}';
    }
    return 'Date Range';
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

  String _formatDateShort(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
