import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

class CacheService {
  static final _logger = Logger('CacheService');

  static const String _resultsDirName = 'results';

  Future<Directory> _getResultsDirectory() async {
    Directory appDocDir;
    if (kIsWeb) {
      throw UnsupportedError('Web platform not supported');
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      appDocDir = await getApplicationSupportDirectory();
    } else {
      appDocDir = await getApplicationDocumentsDirectory();
    }

    final resultsDir = Directory(p.join(appDocDir.path, _resultsDirName));
    return resultsDir;
  }

  Future<int> getCacheSize() async {
    try {
      int totalSize = 0;

      final resultsDir = await _getResultsDirectory();
      _logger.info('Results directory: ${resultsDir.path}');
      _logger.info('Results directory exists: ${await resultsDir.exists()}');

      if (await resultsDir.exists()) {
        totalSize += _calculateDirectorySize(resultsDir);
        _logger.info('Results directory size: $totalSize bytes');
      }

      final appSupportDir = await getApplicationSupportDirectory();
      final appName = 'com.promptmemo.prompt_memo';
      final appDir = Directory(p.join(appSupportDir.path, appName));
      final dbFile = File(p.join(appDir.path, 'prompt_memo.db'));
      _logger.info('Database file path: ${dbFile.path}');
      _logger.info('Database file exists: ${await dbFile.exists()}');

      if (await dbFile.exists()) {
        final dbSize = await dbFile.length();
        totalSize += dbSize;
        _logger.info('Database file size: $dbSize bytes');
      }

      _logger.info(
        'Total cache size: $totalSize bytes (${formatBytes(totalSize)})',
      );
      return totalSize;
    } catch (e, s) {
      _logger.warning('Failed to calculate cache size', e, s);
      return 0;
    }
  }

  Future<void> clearCache() async {
    try {
      _logger.info('Starting cache clear');

      final resultsDir = await _getResultsDirectory();
      if (await resultsDir.exists()) {
        await resultsDir.delete(recursive: true);
        _logger.info('Results directory deleted');
        await resultsDir.create(recursive: true);
      }

      _logger.info('Cache cleared successfully');
    } catch (e, s) {
      _logger.warning('Failed to clear cache', e, s);
      rethrow;
    }
  }

  Future<void> deleteAllData() async {
    try {
      _logger.info('Starting complete data deletion');

      final appSupportDir = await getApplicationSupportDirectory();
      final appName = 'com.promptmemo.prompt_memo';
      final appDir = Directory(p.join(appSupportDir.path, appName));
      final dbFile = File(p.join(appDir.path, 'prompt_memo.db'));

      if (await dbFile.exists()) {
        await dbFile.delete();
        _logger.info('Database file deleted');
      }

      final resultsDir = Directory(p.join(appDir.path, _resultsDirName));
      if (await resultsDir.exists()) {
        await resultsDir.delete(recursive: true);
        _logger.info('Results directory deleted');
      }

      _logger.info('All data deleted successfully');
    } catch (e, s) {
      _logger.severe('Failed to delete all data', e, s);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      int totalSize = 0;
      int imageCount = 0;
      int videoCount = 0;
      int textCount = 0;
      int dbSize = 0;

      final resultsDir = await _getResultsDirectory();
      if (await resultsDir.exists()) {
        await for (final entity in resultsDir.list(recursive: true)) {
          if (entity is File) {
            final fileSize = await entity.length();
            totalSize += fileSize;
            final fileName = p.basename(entity.path);
            final ext = p.extension(fileName).toLowerCase();

            if ([
              '.jpg',
              '.jpeg',
              '.png',
              '.gif',
              '.webp',
              '.bmp',
            ].contains(ext)) {
              imageCount++;
            } else if ([
              '.mp4',
              '.avi',
              '.mov',
              '.mkv',
              '.webm',
            ].contains(ext)) {
              videoCount++;
            } else if (['.txt', '.md', '.json', '.csv'].contains(ext)) {
              textCount++;
            }
          }
        }
      }

      final appSupportDir = await getApplicationSupportDirectory();
      final appName = 'com.promptmemo.prompt_memo';
      final appDir = Directory(p.join(appSupportDir.path, appName));
      final dbFile = File(p.join(appDir.path, 'prompt_memo.db'));

      if (await dbFile.exists()) {
        dbSize = await dbFile.length();
        totalSize += dbSize;
      }

      final fileSizesTotal = totalSize - dbSize;
      final imagesSize =
          imageCount > 0
              ? (fileSizesTotal * imageCount) ~/
                  (imageCount + videoCount + textCount)
              : 0;
      final videosSize =
          videoCount > 0
              ? (fileSizesTotal * videoCount) ~/
                  (imageCount + videoCount + textCount)
              : 0;
      final textsSize =
          totalSize > 0
              ? (totalSize * textCount) ~/ (imageCount + videoCount + textCount)
              : 0;

      return {
        'database': dbSize,
        'images': imagesSize,
        'videos': videosSize,
        'texts': textsSize,
        'cache': fileSizesTotal,
        'imageCount': imageCount,
        'videoCount': videoCount,
        'textCount': textCount,
      };
    } catch (e, s) {
      _logger.warning('Failed to get storage info', e, s);
      return {
        'database': 0,
        'images': 0,
        'videos': 0,
        'texts': 0,
        'cache': 0,
        'imageCount': 0,
        'videoCount': 0,
        'textCount': 0,
      };
    }
  }

  int _calculateDirectorySize(Directory dir) {
    int size = 0;
    try {
      if (dir.existsSync()) {
        dir.listSync(recursive: true).forEach((FileSystemEntity entity) {
          if (entity is File) {
            size += entity.lengthSync();
          }
        });
      }
    } catch (e, s) {
      _logger.warning(
        'Failed to calculate directory size for ${dir.path}',
        e,
        s,
      );
    }
    return size;
  }

  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
