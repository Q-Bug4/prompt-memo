import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:go_router/go_router.dart';
import 'package:prompt_memo/shared/models/prompt.dart';
import 'package:prompt_memo/shared/models/result_sample.dart';
import 'package:prompt_memo/features/prompt-management/presentation/providers/prompt_providers.dart';
import 'package:prompt_memo/features/prompt-management/presentation/widgets/file_picker_dialog.dart';
import 'package:prompt_memo/features/prompt-management/presentation/widgets/text_file_viewer.dart';
import 'package:prompt_memo/features/prompt-management/presentation/widgets/image_file_viewer.dart';
import 'package:prompt_memo/features/prompt-management/presentation/widgets/video_file_viewer.dart';
import 'package:prompt_memo/core/storage/filesystem_storage.dart';

final _logger = Logger('PromptDetailScreen');

/// Screen displaying prompt details and result samples
class PromptDetailScreen extends ConsumerWidget {
  final String promptId;

  const PromptDetailScreen({super.key, required this.promptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _logger.info('build, promptId = $promptId');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prompt Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _logger.info('edit button pressed, navigating to /prompt/$promptId/edit');
              context.push('/prompt/$promptId/edit');
            },
            tooltip: 'Edit',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              _logger.fine('PopupMenuButton onSelected, value = $value');
              if (value == 'delete') {
                _showDeleteDialog(context, ref, promptId);
              }
            },
            itemBuilder: (menuCtx) => [
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer(
        builder: (ctx, ref, _) {
          _logger.fine('Consumer body builder');
          final promptAsync = ref.watch(promptProvider(promptId));
          final resultsAsync = ref.watch(resultSamplesProvider(promptId));

          _logger.finer('promptAsync value = ${promptAsync.value}');
          _logger.finer('resultsAsync value = ${resultsAsync.value}');

          return promptAsync.when(
            data: (prompt) {
              _logger.info('prompt data, prompt = $prompt');
              if (prompt == null) {
                _logger.warning('prompt is null, showing not found');
                return _buildNotFound();
              }
              _logger.info('prompt exists, showing content');
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPromptHeader(prompt),
                          const SizedBox(height: 16),
                          _buildPromptContent(prompt),
                          const SizedBox(height: 24),
                          _buildResultsSection(ctx, resultsAsync),
                        ],
                      ),
                    ),
                  ),
                  _buildAddResultButton(ctx, ref, promptId),
                ],
              );
            },
            loading: () {
              _logger.fine('prompt loading');
              return const Center(child: CircularProgressIndicator());
            },
            error: (error, stack) {
              _logger.severe('prompt error, error = $error', error, stack);
              return _buildError(ctx, error);
            },
          );
        },
      ),
    );
  }
}

Widget _buildNotFound() {
  _logger.warning('_buildNotFound called');
  return const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          'Prompt not found',
          style: TextStyle(fontSize: 18),
        ),
      ],
    ),
  );
}

Widget _buildError(BuildContext ctx, Object error) {
  _logger.severe('_buildError called, error = $error');
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error, size: 64, color: Colors.red),
        const SizedBox(height: 16),
        Text(
          'Error loading prompt',
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(
          'Please try again',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    ),
  );
}

Widget _buildPromptHeader(Prompt prompt) {
  _logger.fine('_buildPromptHeader called, prompt = ${prompt.title}');
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        prompt.title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildChip(Icons.calendar_today, _formatDate(prompt.createdAt)),
          if (prompt.collectionId != null)
            _buildChip(Icons.folder, 'In Collection'),
          ...prompt.tags.map((tag) => _buildChip(Icons.tag, tag)),
        ],
      ),
    ],
  );
}

Widget _buildChip(IconData icon, String label) {
  return Chip(
    avatar: Icon(icon, size: 16),
    label: Text(label),
    labelStyle: const TextStyle(fontSize: 12),
  );
}

Widget _buildPromptContent(Prompt prompt) {
  _logger.fine('_buildPromptContent called');
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Prompt Content',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () => _copyToClipboard(prompt.content),
                tooltip: 'Copy',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(prompt.content),
        ],
      ),
    ),
  );
}

Future<void> _copyToClipboard(String text) async {
  await Clipboard.setData(ClipboardData(text: text));
}

Widget _buildResultsSection(
  BuildContext ctx,
  AsyncValue<List<ResultSample>> resultsAsync,
) {
  _logger.fine('_buildResultsSection called');
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Text(
            'Result Samples',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          resultsAsync.when(
            data: (results) {
              _logger.finer('results data, count = ${results.length}');
              return Text('${results.length} ${results.length == 1 ? 'result' : 'results'}');
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      const SizedBox(height: 12),
      resultsAsync.when(
        data: (results) {
          _logger.finer('results async data, count = ${results.length}');
          if (results.isEmpty) {
            _logger.fine('results is empty, showing empty state');
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.attach_file, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No result samples yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          _logger.fine('building result cards, count = ${results.length}');
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: results.map((result) => _buildResultCard(ctx, result)).toList(),
          );
        },
        loading: () {
          _logger.fine('results loading');
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, _) {
          _logger.severe('results error, error = $error');
          return _buildErrorCard(ctx, error);
        },
      ),
    ],
  );
}

Widget _buildResultCard(BuildContext ctx, ResultSample result) {
  _logger.fine('_buildResultCard called, file = ${result.fileName}');
  IconData icon = Icons.description;
  Color color = Colors.blue;

  switch (result.fileType) {
    case FileType.text:
      icon = Icons.description;
      color = Colors.blue;
    case FileType.image:
      icon = Icons.image;
      color = Colors.green;
    case FileType.video:
      icon = Icons.videocam;
      color = Colors.purple;
  }

  return Card(
    child: InkWell(
      onTap: () {
        _logger.fine('_buildResultCard: onTap, file = ${result.fileName}');
        _openFileViewer(ctx, result);
      },
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              result.fileName.length > 20
                  ? '${result.fileName.substring(0, 20)}...'
                  : result.fileName,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildErrorCard(BuildContext ctx, Object error) {
  _logger.severe('_buildErrorCard called, error = $error');
  return Card(
    color: Colors.red.shade50,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Error loading results: $error',
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildAddResultButton(BuildContext ctx, WidgetRef ref, String promptId) {
  _logger.fine('_buildAddResultButton called, promptId = $promptId');
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(ctx).colorScheme.surface,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: SafeArea(
      child: ElevatedButton.icon(
        onPressed: () {
          _showAddResultDialog(ctx, ref, promptId);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Result Sample'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    ),
  );
}

void _openFileViewer(BuildContext ctx, ResultSample result) {
  _logger.fine('_openFileViewer called, file = ${result.fileName}');
  Widget viewer;

  switch (result.fileType) {
    case FileType.text:
      viewer = TextFileViewer(filePath: result.filePath, fileName: result.fileName);
    case FileType.image:
      viewer = ImageFileViewer(filePath: result.filePath, fileName: result.fileName);
    case FileType.video:
      viewer = VideoFileViewer(filePath: result.filePath, fileName: result.fileName);
  }

  Navigator.of(ctx).push(
    MaterialPageRoute(builder: (context) => viewer),
  );
}

void _showAddResultDialog(BuildContext ctx, WidgetRef ref, String promptId) {
  _logger.info('_showAddResultDialog called, promptId = $promptId');
  showDialog(
    context: ctx,
    builder: (dialogCtx) => FilePickerDialog(
      onFileSelected: (file) async {
        _logger.fine('FilePickerDialog onFileSelected, file = ${file?.name ?? "null"}');

        if (file == null) {
          _logger.fine('file is null, returning');
          return;
        }

        try {
          _logger.info('storing file to filesystem...');
          final storage = FilesystemStorage();
          final filePath = await storage.storeFile(
            promptId: promptId,
            fileName: file.name,
            bytes: file.bytes!,
          );
          _logger.info('file stored at $filePath');

          // Add to database
          _logger.info('adding to database...');
          final repository = ref.read(promptRepositoryProvider);
          final storage2 = FilesystemStorage();
          final mimeType = storage2.getMimeType(file.name);
          _logger.fine('mimeType = $mimeType');

          await repository.createResultSample(
            promptId: promptId,
            filePath: filePath,
            fileName: file.name,
            fileSize: file.size,
            fileType: file.type.name,
            mimeType: mimeType,
          );
          _logger.info('added to database successfully');

          // Refresh results provider to update UI
          _logger.fine('invalidating result samples provider...');
          ref.invalidate(resultSamplesProvider(promptId));
          _logger.fine('provider invalidated');
        } catch (e, s) {
          _logger.severe('ERROR storing file or adding to database: $e', e, s);
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text('Failed to save file: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // For now, just show file was added
        _logger.info('showing success snackbar');
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Result sample added!'),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(ctx);
        }
      },
    ),
  );
}

void _showDeleteDialog(BuildContext ctx, WidgetRef ref, String promptId) {
  _logger.info('_showDeleteDialog called, promptId = $promptId');
  showDialog(
    context: ctx,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Delete Prompt'),
      content: const Text(
        'Are you sure you want to delete this prompt? '
        'This will also delete all associated result samples.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(dialogCtx);
            final repository = ref.read(promptRepositoryProvider);
            await repository.deletePrompt(promptId);
            // Refresh the home page's notifier to clear cache
            ref.read(promptListNotifierProvider.notifier).loadPrompts();
            if (ctx.mounted) {
              ctx.pop();
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

String _formatDate(DateTime date) {
  return '${date.month}/${date.day}/${date.year}';
}
