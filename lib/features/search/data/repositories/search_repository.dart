import 'dart:convert';
import 'package:prompt_memo/core/database/database_helper.dart';
import 'package:prompt_memo/core/service_locator.dart';
import 'package:prompt_memo/shared/models/prompt.dart';

/// Repository for search functionality
class SearchRepository {
  final DatabaseHelper _dbHelper;

  /// Creates a new SearchRepository
  /// Uses singleton DatabaseHelper from service locator
  SearchRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? getIt<DatabaseHelper>();

  static const int _maxHistoryItems = 50;

  /// Searches prompts using full-text search
  Future<List<Prompt>> searchPrompts({
    required String query,
    String? collectionId,
    List<String>? tags,
    DateTime? startDate,
    DateTime? endDate,
    bool mostUsedFirst = false,
  }) async {
    final db = await _dbHelper.database;

    // Build base FTS query
    var ftsQuery = query.isEmpty
        ? 'SELECT rowid, * FROM ${DatabaseHelper.tablePrompts}'
        : 'SELECT p.rowid, p.* FROM ${DatabaseHelper.tablePrompts} p '
          'INNER JOIN ${DatabaseHelper.tablePrompts}_fts fts ON p.rowid = fts.rowid '
          'WHERE ${DatabaseHelper.tablePrompts}_fts MATCH ?';

    List<dynamic> args = query.isEmpty ? [] : [query];

    // Add collection filter
    if (collectionId != null) {
      final where = query.isEmpty ? 'WHERE' : 'AND';
      ftsQuery += ' $where ${DatabaseHelper.colCollectionId} = ?';
      args.add(collectionId);
    }

    // Add date range filter
    if (startDate != null) {
      final where = query.isEmpty && collectionId == null
          ? 'WHERE'
          : (query.isEmpty || collectionId == null) ? 'WHERE' : 'AND';
      final startMs = startDate.millisecondsSinceEpoch;
      ftsQuery += ' $where ${DatabaseHelper.colCreatedAt} >= ?';
      args.add(startMs);
    }

    if (endDate != null) {
      final where =
          (query.isEmpty && collectionId == null && startDate == null)
              ? 'WHERE'
              : 'AND';
      final endMs = endDate.millisecondsSinceEpoch;
      ftsQuery += ' $where ${DatabaseHelper.colCreatedAt} <= ?';
      args.add(endMs);
    }

    // Order by relevance (most used first removed since usageCount is removed)
    final orderBy = 'rank ASC';
    ftsQuery += ' ORDER BY $orderBy';

    final List<Map<String, dynamic>> maps =
        await db.rawQuery(ftsQuery, args);

    return maps.map((map) => _mapToPrompt(map)).toList();
  }

  /// Saves search query to history
  Future<void> saveSearchQuery(String query) async {
    if (query.trim().isEmpty) return;

    final db = await _dbHelper.database;
    final now = DateTime.now();

    // Check if query already exists
    final existing = await db.query(
      DatabaseHelper.tableSearchHistory,
      where: '${DatabaseHelper.colQuery} = ?',
      whereArgs: [query],
      orderBy: '${DatabaseHelper.colSearchedAt} DESC',
      limit: 1,
    );

    if (existing.isNotEmpty) {
      // Update timestamp
      await db.update(
        DatabaseHelper.tableSearchHistory,
        {DatabaseHelper.colSearchedAt: now.millisecondsSinceEpoch},
        where: '${DatabaseHelper.colId} = ?',
        whereArgs: [existing.first[DatabaseHelper.colId]],
      );
    } else {
      // Insert new
      await db.insert(
        DatabaseHelper.tableSearchHistory,
        {
          DatabaseHelper.colQuery: query,
          DatabaseHelper.colSearchedAt: now.millisecondsSinceEpoch,
        },
      );

      // Cleanup old history
      await _cleanupOldHistory();
    }
  }

  /// Gets recent search history
  Future<List<String>> getSearchHistory({int limit = 20}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableSearchHistory,
      orderBy: '${DatabaseHelper.colSearchedAt} DESC',
      limit: limit,
    );
    return maps.map((map) => map[DatabaseHelper.colQuery] as String).toList();
  }

  /// Clears search history
  Future<void> clearSearchHistory() async {
    final db = await _dbHelper.database;
    await db.delete(DatabaseHelper.tableSearchHistory);
  }

  /// Gets prompts with specific tag
  Future<List<Prompt>> getPromptsByTag(String tag) async {
    final db = await _dbHelper.database;
    // Note: Tags will be stored in separate table in future
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tablePrompts,
      orderBy: '${DatabaseHelper.colUpdatedAt} DESC',
    );

    // Filter by tag (placeholder - will be implemented with tag table)
    return maps.map((map) => _mapToPrompt(map)).toList();
  }

  /// Gets popular tags
  Future<List<String>> getPopularTags({int limit = 10}) async {
    // Placeholder - will be implemented with tag table
    return [];
  }

  /// Cleans up old search history
  Future<void> _cleanupOldHistory() async {
    final db = await _dbHelper.database;
    await db.rawQuery('''
      DELETE FROM ${DatabaseHelper.tableSearchHistory}
      WHERE ${DatabaseHelper.colId} NOT IN (
        SELECT ${DatabaseHelper.colId} FROM ${DatabaseHelper.tableSearchHistory}
        ORDER BY ${DatabaseHelper.colSearchedAt} DESC
        LIMIT ?
      )
    ''', [_maxHistoryItems]);
  }

  /// Maps database row to Prompt object
  Prompt _mapToPrompt(Map<String, dynamic> map) {
    List<String> tags = [];
    final tagsJson = map[DatabaseHelper.colTags];
    if (tagsJson != null && tagsJson is String && tagsJson.isNotEmpty) {
      try {
        tags = (jsonDecode(tagsJson) as List).map((e) => e.toString()).toList();
      } catch (e) {
        tags = [];
      }
    }

    return Prompt(
      id: map[DatabaseHelper.colId] as String,
      title: map[DatabaseHelper.colTitle] as String,
      content: map[DatabaseHelper.colContent] as String,
      collectionId: map[DatabaseHelper.colCollectionId] as String?,
      tags: tags,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map[DatabaseHelper.colCreatedAt] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map[DatabaseHelper.colUpdatedAt] as int),
    );
  }
}
