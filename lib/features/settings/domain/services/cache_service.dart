import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:prompt_memo/core/database/database_helper.dart';
import 'package:logging/logging.dart';

class CacheService {
  static final _logger = Logger('CacheService');

  Future<int> getCacheSize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/cache');

      if (!await cacheDir.exists()) {
        return 0;
      }

      return _calculateDirectorySize(cacheDir);
    } catch (e, s) {
      _logger.warning('Failed to calculate cache size', e, s);
      return 0;
    }
  }

  Future<void> clearCache() async {
    try {
      _logger.info('Starting cache clear');
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/cache');

      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        _logger.info('Cache directory deleted');
      }

      final dbHelper = DatabaseHelper();
      await dbHelper.clearAllData();
      _logger.info('Database cleared');
    } catch (e, s) {
      _logger.warning('Failed to clear cache', e, s);
      rethrow;
    }
  }

  Future<void> deleteAllData() async {
    try {
      _logger.info('Starting complete data deletion');
      final appDir = await getApplicationDocumentsDirectory();

      final dbFile = File('${appDir.path}/prompt_memo.db');
      if (await dbFile.exists()) {
        await dbFile.delete();
        _logger.info('Database file deleted');
      }

      final cacheDir = Directory('${appDir.path}/cache');
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        _logger.info('Cache directory deleted');
      }

      final uploadsDir = Directory('${appDir.path}/uploads');
      if (await uploadsDir.exists()) {
        await uploadsDir.delete(recursive: true);
        _logger.info('Uploads directory deleted');
      }

      _logger.info('All data deleted successfully');
    } catch (e, s) {
      _logger.severe('Failed to delete all data', e, s);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dbFile = File('${appDir.path}/prompt_memo.db');
      final cacheDir = Directory('${appDir.path}/cache');
      final uploadsDir = Directory('${appDir.path}/uploads');

      final dbSize = await dbFile.exists() ? await dbFile.length() : 0;
      final cacheSize =
          await cacheDir.exists() ? _calculateDirectorySize(cacheDir) : 0;
      final uploadsSize =
          await uploadsDir.exists() ? _calculateDirectorySize(uploadsDir) : 0;

      int imageCount = 0;
      int videoCount = 0;
      int textCount = 0;

      if (await uploadsDir.exists()) {
        await for (final entity in uploadsDir.list(recursive: true)) {
          if (entity is File) {
            final extension = entity.path.toLowerCase().split('.').last;
            if ([
              'jpg',
              'jpeg',
              'png',
              'gif',
              'webp',
              'bmp',
            ].contains(extension)) {
              imageCount++;
            } else if ([
              'mp4',
              'avi',
              'mov',
              'mkv',
              'webm',
            ].contains(extension)) {
              videoCount++;
            } else if (['txt', 'md', 'json', 'csv'].contains(extension)) {
              textCount++;
            }
          }
        }
      }

      return {
        'database': dbSize,
        'images':
            uploadsSize * imageCount ~/ (imageCount + videoCount + textCount),
        'videos':
            uploadsSize * videoCount ~/ (imageCount + videoCount + textCount),
        'texts':
            uploadsSize * textCount ~/ (imageCount + videoCount + textCount),
        'cache': cacheSize,
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
