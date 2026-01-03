import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:prompt_memo/core/storage/file_storage_interface.dart';

/// Filesystem-based storage provider for result samples
class FilesystemStorage implements FileStorageInterface {
  static const String _resultsDirName = 'results';

  // Supported file extensions
  static const Map<String, String> _textExtensions = {
    '.txt': 'text/plain',
  };

  static const Map<String, String> _imageExtensions = {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.gif': 'image/gif',
    '.webp': 'image/webp',
  };

  static const Map<String, String> _videoExtensions = {
    '.mp4': 'video/mp4',
    '.webm': 'video/webm',
    '.mov': 'video/quicktime',
  };

  @override
  Future<String> getStorageDirectory() async {
    Directory appDocDir;
    if (kIsWeb) {
      throw UnsupportedError('Web platform not supported');
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      appDocDir = await getApplicationSupportDirectory();
    } else {
      appDocDir = await getApplicationDocumentsDirectory();
    }

    final resultsDir = Directory(p.join(appDocDir.path, _resultsDirName));
    if (!await resultsDir.exists()) {
      await resultsDir.create(recursive: true);
    }
    return resultsDir.path;
  }

  @override
  bool isSupportedFileType(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    return _textExtensions.containsKey(ext) ||
        _imageExtensions.containsKey(ext) ||
        _videoExtensions.containsKey(ext);
  }

  @override
  String getFileType(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    if (_textExtensions.containsKey(ext)) return 'text';
    if (_imageExtensions.containsKey(ext)) return 'image';
    if (_videoExtensions.containsKey(ext)) return 'video';
    return 'unknown';
  }

  String? getMimeType(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    return _textExtensions[ext] ??
        _imageExtensions[ext] ??
        _videoExtensions[ext];
  }

  @override
  Future<String> storeFile({
    required String promptId,
    required String fileName,
    required List<int> bytes,
  }) async {
    if (!isSupportedFileType(fileName)) {
      throw UnsupportedError('Unsupported file type: $fileName');
    }

    final storageDir = await getStorageDirectory();
    final promptDir = Directory(p.join(storageDir, promptId));

    if (!await promptDir.exists()) {
      await promptDir.create(recursive: true);
    }

    final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final filePath = p.join(promptDir.path, uniqueName);

    final file = File(filePath);
    await file.writeAsBytes(bytes);

    await onFileStored(filePath);

    return filePath;
  }

  @override
  Future<List<int>> getFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found: $filePath');
    }
    return await file.readAsBytes();
  }

  @override
  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
      await onFileDeleted(filePath);
    }
  }

  @override
  Future<void> cleanupPromptFiles(String promptId) async {
    final storageDir = await getStorageDirectory();
    final promptDir = Directory(p.join(storageDir, promptId));

    if (await promptDir.exists()) {
      await promptDir.delete(recursive: true);
    }
  }

  @override
  Future<void> onFileStored(String filePath) async {
    // Hook for future Git sync implementation
    // This can be extended to track file changes
  }

  @override
  Future<void> onFileDeleted(String filePath) async {
    // Hook for future Git sync implementation
    // This can be extended to track file deletions
  }
}
