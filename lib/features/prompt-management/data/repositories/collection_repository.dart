import 'package:uuid/uuid.dart';
import 'package:prompt_memo/core/database/database_helper.dart';
import 'package:prompt_memo/shared/models/collection.dart';

/// Repository for managing collections
class CollectionRepository {
  /// Creates a new collection
  Future<Collection> createCollection({
    required String name,
    String description = '',
  }) async {
    final db = await DatabaseHelper().database;
    final id = const Uuid().v4();
    final now = DateTime.now();

    try {
      await db.insert(
        DatabaseHelper.tableCollections,
        {
          DatabaseHelper.colId: id,
          DatabaseHelper.colName: name,
          DatabaseHelper.colDescription: description,
          DatabaseHelper.colTagColors: '[]',
          DatabaseHelper.colCreatedAt: now.millisecondsSinceEpoch,
          DatabaseHelper.colUpdatedAt: now.millisecondsSinceEpoch,
        },
      );

      return Collection(
        id: id,
        name: name,
        description: description,
        tagColors: const [],
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      throw Exception('Collection with this name already exists');
    }
  }

  /// Gets all collections
  Future<List<Collection>> getAllCollections() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableCollections,
      orderBy: '${DatabaseHelper.colUpdatedAt} DESC',
    );
    return maps.map((map) => _mapToCollection(map)).toList();
  }

  /// Gets collection by ID
  Future<Collection?> getCollectionById(String id) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableCollections,
      where: '${DatabaseHelper.colId} = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return _mapToCollection(maps.first);
  }

  /// Updates a collection
  Future<void> updateCollection(Collection collection) async {
    final db = await DatabaseHelper().database;
    final now = DateTime.now();

    await db.update(
      DatabaseHelper.tableCollections,
      {
        DatabaseHelper.colName: collection.name,
        DatabaseHelper.colDescription: collection.description,
        DatabaseHelper.colUpdatedAt: now.millisecondsSinceEpoch,
      },
      where: '${DatabaseHelper.colId} = ?',
      whereArgs: [collection.id],
    );
  }

  /// Deletes a collection
  Future<void> deleteCollection(String id) async {
    final db = await DatabaseHelper().database;
    await db.delete(
      DatabaseHelper.tableCollections,
      where: '${DatabaseHelper.colId} = ?',
      whereArgs: [id],
    );
  }

  /// Maps database row to Collection object
  Collection _mapToCollection(Map<String, dynamic> map) {
    return Collection(
      id: map[DatabaseHelper.colId] as String,
      name: map[DatabaseHelper.colName] as String,
      description: map[DatabaseHelper.colDescription] as String? ?? '',
      tagColors: const [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map[DatabaseHelper.colCreatedAt] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map[DatabaseHelper.colUpdatedAt] as int),
    );
  }
}
