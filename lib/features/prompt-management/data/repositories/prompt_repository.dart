import 'package:uuid/uuid.dart';
import 'package:prompt_memo/core/database/database_helper.dart';
import 'package:prompt_memo/core/storage/filesystem_storage.dart';
import 'package:prompt_memo/shared/models/prompt.dart';
import 'package:prompt_memo/shared/models/result_sample.dart';

/// Repository for managing prompts
class PromptRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Creates a new prompt
  Future<Prompt> createPrompt({
    required String title,
    required String content,
    String? collectionId,
    List<String> tags = const [],
  }) async {
    final db = await _dbHelper.database;
    final id = const Uuid().v4();
    final now = DateTime.now();

    await db.insert(
      DatabaseHelper.tablePrompts,
      {
        DatabaseHelper.colId: id,
        DatabaseHelper.colTitle: title,
        DatabaseHelper.colContent: content,
        DatabaseHelper.colCollectionId: collectionId,
        DatabaseHelper.colUsageCount: 0,
        DatabaseHelper.colCreatedAt: now.millisecondsSinceEpoch,
        DatabaseHelper.colUpdatedAt: now.millisecondsSinceEpoch,
      },
    );

    return Prompt(
      id: id,
      title: title,
      content: content,
      collectionId: collectionId,
      usageCount: 0,
      tags: tags,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Gets all prompts
  Future<List<Prompt>> getAllPrompts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tablePrompts,
      orderBy: '${DatabaseHelper.colUpdatedAt} DESC',
    );
    return maps.map((map) => _mapToPrompt(map)).toList();
  }

  /// Gets prompt by ID
  Future<Prompt?> getPromptById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tablePrompts,
      where: '${DatabaseHelper.colId} = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return _mapToPrompt(maps.first);
  }

  /// Gets prompts by collection ID
  Future<List<Prompt>> getPromptsByCollection(String collectionId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tablePrompts,
      where: '${DatabaseHelper.colCollectionId} = ?',
      whereArgs: [collectionId],
      orderBy: '${DatabaseHelper.colUpdatedAt} DESC',
    );
    return maps.map((map) => _mapToPrompt(map)).toList();
  }

  /// Updates a prompt
  Future<void> updatePrompt(Prompt prompt) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    await db.update(
      DatabaseHelper.tablePrompts,
      {
        DatabaseHelper.colTitle: prompt.title,
        DatabaseHelper.colContent: prompt.content,
        DatabaseHelper.colCollectionId: prompt.collectionId,
        DatabaseHelper.colUpdatedAt: now.millisecondsSinceEpoch,
      },
      where: '${DatabaseHelper.colId} = ?',
      whereArgs: [prompt.id],
    );
  }

  /// Deletes a prompt and all its result samples
  Future<void> deletePrompt(String id) async {
    final db = await _dbHelper.database;

    // Get result samples to delete files
    final results = await getResultSamples(id);
    for (final result in results) {
      await deleteResultSample(result.id);
    }

    await db.delete(
      DatabaseHelper.tablePrompts,
      where: '${DatabaseHelper.colId} = ?',
      whereArgs: [id],
    );
  }

  /// Increments usage count for a prompt
  Future<void> incrementUsageCount(String id) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE ${DatabaseHelper.tablePrompts} '
      'SET ${DatabaseHelper.colUsageCount} = ${DatabaseHelper.colUsageCount} + 1 '
      'WHERE ${DatabaseHelper.colId} = ?',
      [id],
    );
  }

  /// Creates a result sample
  Future<ResultSample> createResultSample({
    required String promptId,
    required String filePath,
    required String fileName,
    required int fileSize,
    required String fileType,
    String? mimeType,
    int? width,
    int? height,
    int? durationSeconds,
  }) async {
    final db = await _dbHelper.database;
    final id = const Uuid().v4();
    final now = DateTime.now();

    await db.insert(
      DatabaseHelper.tableResultSamples,
      {
        DatabaseHelper.colId: id,
        DatabaseHelper.colPromptId: promptId,
        DatabaseHelper.colFileType: fileType,
        DatabaseHelper.colFilePath: filePath,
        DatabaseHelper.colFileName: fileName,
        DatabaseHelper.colFileSize: fileSize,
        DatabaseHelper.colMimeType: mimeType,
        DatabaseHelper.colWidth: width,
        DatabaseHelper.colHeight: height,
        DatabaseHelper.colDurationSeconds: durationSeconds,
        DatabaseHelper.colCreatedAt: now.millisecondsSinceEpoch,
      },
    );

    return ResultSample(
      id: id,
      promptId: promptId,
      fileType: _parseFileType(fileType),
      filePath: filePath,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      width: width,
      height: height,
      durationSeconds: durationSeconds,
      createdAt: now,
    );
  }

  /// Creates a result sample (simplified version)
  Future<ResultSample> createResultSampleSimple({
    required String promptId,
    required String filePath,
    required String fileName,
    required int fileSize,
    required String fileType,
  }) async {
    return createResultSample(
      promptId: promptId,
      filePath: filePath,
      fileName: fileName,
      fileSize: fileSize,
      fileType: fileType,
    );
  }

  /// Gets all result samples for a prompt
  Future<List<ResultSample>> getResultSamples(String promptId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableResultSamples,
      where: '${DatabaseHelper.colPromptId} = ?',
      whereArgs: [promptId],
      orderBy: '${DatabaseHelper.colCreatedAt} DESC',
    );
    return maps.map((map) => _mapToResultSample(map)).toList();
  }

  /// Gets a result sample by ID
  Future<ResultSample?> getResultSampleById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableResultSamples,
      where: '${DatabaseHelper.colId} = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return _mapToResultSample(maps.first);
  }

  /// Deletes a result sample
  Future<void> deleteResultSample(String id) async {
    final db = await _dbHelper.database;
    final result = await getResultSampleById(id);
    if (result != null) {
      // Delete file from filesystem
      final storage = FilesystemStorage();
      await storage.deleteFile(result.filePath);
    }

    await db.delete(
      DatabaseHelper.tableResultSamples,
      where: '${DatabaseHelper.colId} = ?',
      whereArgs: [id],
    );
  }

  /// Maps database row to Prompt object
  Prompt _mapToPrompt(Map<String, dynamic> map) {
    return Prompt(
      id: map[DatabaseHelper.colId] as String,
      title: map[DatabaseHelper.colTitle] as String,
      content: map[DatabaseHelper.colContent] as String,
      collectionId: map[DatabaseHelper.colCollectionId] as String?,
      usageCount: map[DatabaseHelper.colUsageCount] as int,
      tags: const [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map[DatabaseHelper.colCreatedAt] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map[DatabaseHelper.colUpdatedAt] as int),
    );
  }

  /// Maps database row to ResultSample object
  ResultSample _mapToResultSample(Map<String, dynamic> map) {
    return ResultSample(
      id: map[DatabaseHelper.colId] as String,
      promptId: map[DatabaseHelper.colPromptId] as String,
      fileType: _parseFileType(map[DatabaseHelper.colFileType] as String),
      filePath: map[DatabaseHelper.colFilePath] as String,
      fileName: map[DatabaseHelper.colFileName] as String,
      fileSize: map[DatabaseHelper.colFileSize] as int,
      mimeType: map[DatabaseHelper.colMimeType] as String?,
      width: map[DatabaseHelper.colWidth] as int?,
      height: map[DatabaseHelper.colHeight] as int?,
      durationSeconds: map[DatabaseHelper.colDurationSeconds] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map[DatabaseHelper.colCreatedAt] as int),
    );
  }

  /// Parses string to FileType enum
  FileType _parseFileType(String type) {
    switch (type.toLowerCase()) {
      case 'text':
        return FileType.text;
      case 'image':
        return FileType.image;
      case 'video':
        return FileType.video;
      default:
        return FileType.text;
    }
  }
}
