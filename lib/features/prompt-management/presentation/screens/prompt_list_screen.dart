import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:prompt_memo/features/prompt-management/presentation/providers/prompt_providers.dart';
import 'package:prompt_memo/shared/models/prompt.dart';

/// Screen displaying list of all prompts
class PromptListScreen extends ConsumerStatefulWidget {
  const PromptListScreen({super.key});

  @override
  ConsumerState<PromptListScreen> createState() => _PromptListScreenState();
}

class _PromptListScreenState extends ConsumerState<PromptListScreen> {
  @override
  Widget build(BuildContext context) {
    final prompts = ref.watch(promptListNotifierProvider);

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
            onPressed: () {
              ref.read(promptListNotifierProvider.notifier).loadPrompts();
            },
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
        onPressed: () => context.push('/prompt/new'),
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

  Widget _buildPromptCard(BuildContext ctx, Prompt prompt) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () {
          ctx.push('/prompt/${prompt.id}');
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
