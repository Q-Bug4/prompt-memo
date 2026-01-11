import 'dart:io';
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
    _logger.info('PromptDetailScreen: build - promptId: $promptId');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prompt Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _logger.info('PromptDetailScreen: edit button pressed - navigating to /prompt/$promptId/edit');
              context.push('/prompt/$promptId/edit');
            },
            tooltip: 'Edit',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              _logger.info('PromptDetailScreen: popup menu selected - value: $value');
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
          _logger.finest('PromptDetailScreen: Consumer builder - watching providers');
          final promptAsync = ref.watch(promptProvider(promptId));
          final resultsAsync = ref.watch(resultSamplesProvider(promptId));

          _logger.finest('PromptDetailScreen: promptAsync state: ${promptAsync.runtimeType}');
          _logger.finest('PromptDetailScreen: resultsAsync state: ${resultsAsync.runtimeType}');

          return promptAsync.when(
            data: (prompt) {
              if (prompt == null) {
                _logger.warning('PromptDetailScreen: prompt not found for id: $promptId');
                return _buildNotFound();
              }
              _logger.fine('PromptDetailScreen: displaying prompt: ${prompt.title} with ${resultsAsync.value?.length ?? 0} attachments');
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
              _logger.fine('PromptDetailScreen: loading prompt data');
              return const Center(child: CircularProgressIndicator());
            },
            error: (error, stack) {
              _logger.severe('PromptDetailScreen: error loading prompt', error, stack);
              return _buildError(ctx, error);
            },
          );
        },
      ),
    );
  }
}

Widget _buildNotFound() {
  _logger.warning('PromptDetailScreen: building not found widget');
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
  _logger.severe('PromptDetailScreen: building error widget - error: $error');
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
  _logger.finest('PromptDetailScreen: building header for: ${prompt.title}');
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
  _logger.finest('PromptDetailScreen: building content section');
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
                onPressed: () {
                  _logger.info('PromptDetailScreen: copy button pressed - copying content to clipboard');
                  _copyToClipboard(prompt.content);
                },
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
  try {
    await Clipboard.setData(ClipboardData(text: text));
    _logger.fine('PromptDetailScreen: content copied to clipboard (${text.length} chars)');
  } catch (e, s) {
    _logger.warning('PromptDetailScreen: failed to copy to clipboard', e, s);
  }
}

Widget _buildResultsSection(
  BuildContext ctx,
  AsyncValue<List<ResultSample>> resultsAsync,
) {
  _logger.finest('PromptDetailScreen: building results section');
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
          _logger.finest('PromptDetailScreen: displaying ${results.length} results');
          if (results.isEmpty) {
            _logger.fine('PromptDetailScreen: no results to display');
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
          _logger.fine('PromptDetailScreen: building result cards');
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: results.map((result) => _buildResultCard(ctx, result)).toList(),
          );
        },
        loading: () {
          _logger.fine('PromptDetailScreen: loading results');
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stack) {
          _logger.severe('PromptDetailScreen: error loading results', error, stack);
          return _buildErrorCard(ctx, error);
        },
      ),
    ],
  );
}

Widget _buildResultCard(BuildContext ctx, ResultSample result) {
  _logger.finest('PromptDetailScreen: building card for attachment: ${result.fileName} (${result.fileType.name})');

  // Don't show video attachments
  if (result.fileType == FileType.video) {
    _logger.finest('PromptDetailScreen: skipping video attachment: ${result.id}');
    return const SizedBox.shrink();
  }

  return Card(
    child: InkWell(
      onTap: () {
        _logger.info('PromptDetailScreen: attachment card tapped - ${result.fileName}');
        _openFileViewer(ctx, result);
      },
      child: Container(
        width: 150,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview area with delete button
            Stack(
              children: [
                _buildPreview(result),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _logger.info('PromptDetailScreen: delete button pressed - attachment: ${result.fileName}');
                        _showDeleteResultDialog(ctx, result);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Filename
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                result.fileName.length > 20
                    ? '${result.fileName.substring(0, 20)}...'
                    : result.fileName,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildPreview(ResultSample result) {
  _logger.finest('PromptDetailScreen: building preview for ${result.fileType.name}');
  switch (result.fileType) {
    case FileType.text:
      return _buildTextPreview(result);
    case FileType.image:
      return _buildImagePreview(result);
    case FileType.video:
      return const SizedBox.shrink(); // Should not reach here due to early return
  }
}

Widget _buildTextPreview(ResultSample result) {
  _logger.finest('PromptDetailScreen: building text preview for ${result.fileName}');
  return FutureBuilder<String>(
    future: _readFileContent(result.filePath, 50),
    builder: (context, snapshot) {
      final content = snapshot.data ?? '';
      if (snapshot.connectionState == ConnectionState.waiting) {
        _logger.finest('PromptDetailScreen: loading text content for ${result.fileName}');
      } else if (snapshot.hasError) {
        _logger.warning('PromptDetailScreen: failed to load text preview for ${result.fileName}: ${snapshot.error}');
      }

      return Container(
        width: 150,
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: Center(
          child: Text(
            content.isEmpty ? '...' : '$content...',
            style: const TextStyle(fontSize: 10, color: Colors.black87),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      );
    },
  );
}

Widget _buildImagePreview(ResultSample result) {
  _logger.finest('PromptDetailScreen: building image preview for ${result.fileName}');
  return Container(
    width: 150,
    height: 100,
    child: ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      child: Image.file(
        File(result.filePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          _logger.warning('PromptDetailScreen: failed to load image preview for ${result.fileName}: $error');
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.broken_image, size: 32, color: Colors.grey),
            ),
          );
        },
      ),
    ),
  );
}

Future<String> _readFileContent(String path, int maxChars) async {
  _logger.finest('PromptDetailScreen: reading file content from $path (max: $maxChars chars)');
  try {
    final file = File(path);
    if (await file.exists()) {
      final content = await file.readAsString();
      final truncatedContent = content.length > maxChars ? content.substring(0, maxChars) : content;
      _logger.finest('PromptDetailScreen: successfully read ${content.length} chars from file');
      return truncatedContent;
    } else {
      _logger.warning('PromptDetailScreen: file does not exist: $path');
    }
  } catch (e, s) {
    _logger.warning('PromptDetailScreen: failed to read file: $path', e, s);
  }
  return '';
}

Widget _buildErrorCard(BuildContext ctx, Object error) {
  _logger.severe('PromptDetailScreen: building error card - error: $error');
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
  _logger.finest('PromptDetailScreen: building add result button');
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
          _logger.info('PromptDetailScreen: add result button pressed');
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
  _logger.info('PromptDetailScreen: opening file viewer - type: ${result.fileType.name}, file: ${result.fileName}');
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
  _logger.fine('PromptDetailScreen: file viewer navigation completed');
}

void _showAddResultDialog(BuildContext ctx, WidgetRef ref, String promptId) {
  _logger.info('PromptDetailScreen: showing add result dialog - promptId: $promptId');
  showDialog(
    context: ctx,
    builder: (dialogCtx) => FilePickerDialog(
      onFileSelected: (file) async {
        _logger.fine('PromptDetailScreen: file selected - ${file?.name ?? "null"}');

        if (file == null) {
          _logger.fine('PromptDetailScreen: file selection cancelled');
          return;
        }

        final startTime = DateTime.now();
        try {
          // Store file to filesystem
          _logger.info('PromptDetailScreen: storing file to filesystem - ${file.name} (${file.size} bytes)');
          final storage = FilesystemStorage();
          final filePath = await storage.storeFile(
            promptId: promptId,
            fileName: file.name,
            bytes: file.bytes!,
          );
          _logger.fine('PromptDetailScreen: file stored at: $filePath');

          // Add to database
          _logger.info('PromptDetailScreen: adding result sample to database');
          final repository = ref.read(promptRepositoryProvider);
          final storage2 = FilesystemStorage();
          final mimeType = storage2.getMimeType(file.name);
          _logger.finer('PromptDetailScreen: detected mime type: $mimeType');

          await repository.createResultSample(
            promptId: promptId,
            filePath: filePath,
            fileName: file.name,
            fileSize: file.size,
            fileType: file.type.name,
            mimeType: mimeType,
          );
          _logger.info('PromptDetailScreen: result sample added to database successfully');

          // Refresh results provider to update UI
          _logger.fine('PromptDetailScreen: invalidating result samples provider');
          ref.invalidate(resultSamplesProvider(promptId));
          _logger.fine('PromptDetailScreen: provider invalidated');

          final duration = DateTime.now().difference(startTime);
          _logger.info('PromptDetailScreen: file upload completed in ${duration.inMilliseconds}ms');
        } catch (e, s) {
          _logger.severe('PromptDetailScreen: failed to save file or add to database', e, s);
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

        // Show success message
        _logger.info('PromptDetailScreen: showing success snackbar');
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Result sample added!'),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(ctx);
          _logger.fine('PromptDetailScreen: closed add result dialog');
        }
      },
    ),
  );
}

void _showDeleteDialog(BuildContext ctx, WidgetRef ref, String promptId) {
  _logger.info('PromptDetailScreen: showing delete prompt dialog - promptId: $promptId');
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
          onPressed: () {
            _logger.fine('PromptDetailScreen: delete prompt cancelled');
            Navigator.pop(dialogCtx);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            _logger.info('PromptDetailScreen: deleting prompt - promptId: $promptId');
            Navigator.pop(dialogCtx);

            try {
              final repository = ref.read(promptRepositoryProvider);
              await repository.deletePrompt(promptId);
              _logger.info('PromptDetailScreen: prompt deleted successfully');

              // Refresh the home page's notifier to clear cache
              ref.read(promptListNotifierProvider.notifier).loadPrompts();
              _logger.fine('PromptDetailScreen: home page refresh triggered');

              if (ctx.mounted) {
                ctx.pop();
                _logger.fine('PromptDetailScreen: navigated back to home screen');
              }
            } catch (e, s) {
              _logger.severe('PromptDetailScreen: failed to delete prompt', e, s);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete prompt: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
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

void _showDeleteResultDialog(BuildContext ctx, ResultSample result) {
  _logger.info('PromptDetailScreen: showing delete attachment dialog - ${result.fileName}');
  showDialog(
    context: ctx,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Delete Attachment'),
      content: Text(
        'Are you sure you want to delete "${result.fileName}"? '
        'This will permanently delete the file.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            _logger.fine('PromptDetailScreen: delete attachment cancelled');
            Navigator.pop(dialogCtx);
          },
          child: const Text('Cancel'),
        ),
        Consumer(
          builder: (context, ref, _) {
            return TextButton(
              onPressed: () async {
                _logger.info('PromptDetailScreen: deleting attachment - ${result.fileName}');
                Navigator.pop(dialogCtx);
                await _deleteResultSample(ref, result);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            );
          },
        ),
      ],
    ),
  );
}

/// Deletes a result sample (attachment) - removes both database record and file
Future<void> _deleteResultSample(WidgetRef ref, ResultSample result) async {
  final startTime = DateTime.now();
  _logger.info('PromptDetailScreen: _deleteResultSample - ${result.fileName} (id: ${result.id})');

  try {
    final repository = ref.read(promptRepositoryProvider);
    await repository.deleteResultSample(result.id);
    _logger.info('PromptDetailScreen: attachment deleted successfully');

    // Refresh results provider to update UI
    _logger.fine('PromptDetailScreen: invalidating result samples provider');
    ref.invalidate(resultSamplesProvider(result.promptId));

    final duration = DateTime.now().difference(startTime);
    _logger.info('PromptDetailScreen: attachment deletion completed in ${duration.inMilliseconds}ms');

    if (ref.context.mounted) {
      ScaffoldMessenger.of(ref.context).showSnackBar(
        const SnackBar(
          content: Text('Attachment deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (e, s) {
    _logger.severe('PromptDetailScreen: failed to delete attachment', e, s);
    if (ref.context.mounted) {
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete attachment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

String _formatDate(DateTime date) {
  return '${date.month}/${date.day}/${date.year}';
}
