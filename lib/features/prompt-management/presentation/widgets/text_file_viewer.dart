import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

/// Widget for viewing text files
class TextFileViewer extends StatelessWidget {
  final String filePath;
  final String fileName;

  const TextFileViewer({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _loadFileContent(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return _buildError(context, snapshot.error.toString());
        }

        final content = snapshot.data ?? '';
        return _buildContent(context, content);
      },
    );
  }

  Widget _buildContent(BuildContext context, String content) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          content,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load file',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<String> _loadFileContent() async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    return utf8.decode(bytes);
  }
}
