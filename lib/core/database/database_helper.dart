import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

/// Database helper class for managing SQLite database
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  static const String _databaseName = 'prompt_memo.db';
  static const int _databaseVersion = 2;

  // Table names
  static const String tablePrompts = 'prompts';
  static const String tableResultSamples = 'result_samples';
  static const String tableCollections = 'collections';
  static const String tableSearchHistory = 'search_history';

  // Common column names
  static const String colId = 'id';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';

  // Prompts table columns
  static const String colTitle = 'title';
  static const String colContent = 'content';
  static const String colCollectionId = 'collection_id';
  static const String colTags = 'tags';

  // Result samples table columns
  static const String colPromptId = 'prompt_id';
  static const String colFileType = 'file_type';
  static const String colFilePath = 'file_path';
  static const String colFileName = 'file_name';
  static const String colFileSize = 'file_size';
  static const String colMimeType = 'mime_type';
  static const String colWidth = 'width';
  static const String colHeight = 'height';
  static const String colDurationSeconds = 'duration_seconds';

  // Collections table columns
  static const String colName = 'name';
  static const String colDescription = 'description';
  static const String colTagColors = 'tag_colors';

  // Search history table columns
  static const String colQuery = 'query';
  static const String colSearchedAt = 'searched_at';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory directory;
    if (kIsWeb) {
      throw UnimplementedError('Web platform not supported yet');
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      directory = await getApplicationSupportDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    String path = join(directory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create prompts table
    await db.execute('''
      CREATE TABLE $tablePrompts (
        $colId TEXT PRIMARY KEY,
        $colTitle TEXT NOT NULL,
        $colContent TEXT NOT NULL,
        $colCollectionId TEXT,
        $colTags TEXT,
        $colCreatedAt INTEGER NOT NULL,
        $colUpdatedAt INTEGER NOT NULL,
        FOREIGN KEY ($colCollectionId) REFERENCES $tableCollections($colId) ON DELETE SET NULL
      )
    ''');

    // Create result samples table
    await db.execute('''
      CREATE TABLE $tableResultSamples (
        $colId TEXT PRIMARY KEY,
        $colPromptId TEXT NOT NULL,
        $colFileType TEXT NOT NULL,
        $colFilePath TEXT NOT NULL UNIQUE,
        $colFileName TEXT NOT NULL,
        $colFileSize INTEGER NOT NULL,
        $colMimeType TEXT,
        $colWidth INTEGER,
        $colHeight INTEGER,
        $colDurationSeconds INTEGER,
        $colCreatedAt INTEGER NOT NULL,
        FOREIGN KEY ($colPromptId) REFERENCES $tablePrompts($colId) ON DELETE CASCADE
      )
    ''');

    // Create collections table
    await db.execute('''
      CREATE TABLE $tableCollections (
        $colId TEXT PRIMARY KEY,
        $colName TEXT NOT NULL UNIQUE,
        $colDescription TEXT,
        $colTagColors TEXT,
        $colCreatedAt INTEGER NOT NULL,
        $colUpdatedAt INTEGER NOT NULL
      )
    ''');

    // Create search history table
    await db.execute('''
      CREATE TABLE $tableSearchHistory (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colQuery TEXT NOT NULL,
        $colSearchedAt INTEGER NOT NULL
      )
    ''');

    // Create FTS virtual table for full-text search
    await db.execute('''
      CREATE VIRTUAL TABLE ${tablePrompts}_fts USING fts5(
        $colTitle, $colContent,
        content='$tablePrompts',
        content_rowid=rowid
      )
    ''');

    // Create triggers for FTS
    await db.execute('''
      CREATE TRIGGER ${tablePrompts}_ai AFTER INSERT ON $tablePrompts BEGIN
        INSERT INTO ${tablePrompts}_fts(rowid, $colTitle, $colContent)
        VALUES (new.rowid, new.$colTitle, new.$colContent);
      END
    ''');

    await db.execute('''
      CREATE TRIGGER ${tablePrompts}_ad AFTER DELETE ON $tablePrompts BEGIN
        DELETE FROM ${tablePrompts}_fts WHERE rowid = old.rowid;
      END
    ''');

    await db.execute('''
      CREATE TRIGGER ${tablePrompts}_au AFTER UPDATE ON $tablePrompts BEGIN
        DELETE FROM ${tablePrompts}_fts WHERE rowid = old.rowid;
        INSERT INTO ${tablePrompts}_fts(rowid, $colTitle, $colContent)
        VALUES (new.rowid, new.$colTitle, new.$colContent);
      END
    ''');

    // Create indexes for performance
    await db.execute(
      'CREATE INDEX idx_prompts_collection ON $tablePrompts($colCollectionId)');
    await db.execute(
      'CREATE INDEX idx_result_samples_prompt ON $tableResultSamples($colPromptId)');
    await db.execute(
      'CREATE INDEX idx_search_history_query ON $tableSearchHistory($colQuery)');
  }

  Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    // Migration from version 1 to 2
    if (oldVersion < 2) {
      // Add tags column
      await db.execute('ALTER TABLE $tablePrompts ADD COLUMN $colTags TEXT');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Clear all data (for testing purposes)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(tablePrompts);
    await db.delete(tableResultSamples);
    await db.delete(tableCollections);
    await db.delete(tableSearchHistory);
  }
}
