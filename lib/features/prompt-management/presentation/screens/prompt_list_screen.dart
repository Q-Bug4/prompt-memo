import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:prompt_memo/features/prompt-management/presentation/providers/prompt_providers.dart';
import 'package:prompt_memo/shared/models/prompt.dart';
import 'package:prompt_memo/shared/models/result_sample.dart';
import 'package:logging/logging.dart';

final _logger = Logger('PromptListScreen');

/// Screen displaying list of all prompts
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
    _logger.fine('PromptListScreen: initState');
    // Auto-load prompts when entering screen
    _refreshPromptsAndSamples();
  }

  /// Unified method to refresh prompts and samples - use this for all home screen navigation
  Future<void> _refreshPromptsAndSamples() async {
    _logger.fine('_refreshPromptsAndSamples called');
    // Clear samples cache to force reload
    _promptSamples.clear();
    // Load prompts
    await ref.read(promptListNotifierProvider.notifier).loadPrompts();
  }

  Future<void> _loadAllResultSamples(List<Prompt> prompts) async {
    if (_isLoadingSamples) return;
    _isLoadingSamples = true;

    final repository = ref.read(promptRepositoryProvider);
    final Map<String, List<ResultSample>> samplesMap = {};

    for (final prompt in prompts) {
      // Skip if already loaded (unless cache was cleared)
      if (!_promptSamples.containsKey(prompt.id)) {
        final samples = await repository.getResultSamples(prompt.id);
        samplesMap[prompt.id] = samples;
      }
    }

    if (mounted) {
      setState(() {
        _promptSamples.addAll(samplesMap);
        _isLoadingSamples = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.fine('PromptListScreen: build');
    final prompts = ref.watch(promptListNotifierProvider);
    _logger.fine('PromptListScreen: ${prompts.length} prompts loaded');

    // Load result samples for prompts that don't have them yet
    Future.microtask(() => _loadAllResultSamples(prompts));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prompt Memo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPromptsAndSamples,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'collections') {
                _showCollectionsDialog(context);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'collections',
                child: ListTile(
                  leading: Icon(Icons.folder),
                  title: Text('Collections'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: prompts.isEmpty
          ? _buildEmptyState()
          : _buildPromptList(prompts),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create Prompt',
        onPressed: () async {
          await context.push('/prompt/new');
          // Refresh list when returning from create/edit screen
          if (mounted) {
            _refreshPromptsAndSamples();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
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
            'No prompts yet',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Create your first prompt to get started',
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
        return _buildPromptCard(ctx, prompt);
      },
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
            return const SizedBox.shrink(); // Hide video attachments
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
      _logger.warning('Failed to read file: $path, error: $e');
    }
    return '';
  }

  Widget _buildPromptCard(BuildContext ctx, Prompt prompt) {
    final samples = _promptSamples[prompt.id] ?? [];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () async {
          await ctx.push('/prompt/${prompt.id}');
          // Refresh list when returning from detail/edit screen
          if (mounted) {
            _refreshPromptsAndSamples();
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

  void _showCollectionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Collections'),
        content: const Text('Collections feature coming soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
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
}
