import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Widget for viewing image files
class ImageFileViewer extends StatelessWidget {
  final String filePath;
  final String fileName;

  const ImageFileViewer({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () => _showZoomDialog(context),
            tooltip: 'Zoom',
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<Uint8List>(
          future: _loadImageData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return _buildError(context, snapshot.error.toString());
            }

            final imageData = snapshot.data;
            if (imageData == null) {
              return _buildError(context, 'No image data found');
            }

            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(
                imageData,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return _buildError(context, 'Failed to load image');
                },
              ),
            );
          },
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
            Icons.broken_image,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load image',
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

  void _showZoomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zoom Controls'),
        content: const Text(
          'Use pinch gestures to zoom in/out.\n'
          'Scroll to pan around the image.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _loadImageData() async {
    final file = File(filePath);
    return await file.readAsBytes();
  }
}
