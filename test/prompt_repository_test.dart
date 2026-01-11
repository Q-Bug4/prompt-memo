import 'package:flutter_test/flutter_test.dart';
import 'package:prompt_memo/shared/models/prompt.dart';
import 'package:prompt_memo/features/prompt-management/data/repositories/prompt_repository.dart';
import 'package:prompt_memo/core/database/database_helper.dart';
import 'package:mocktail/mocktail.dart';

class FakeDatabaseHelper extends Fake implements DatabaseHelper {
  final List<Map<String, dynamic>> _prompts = [];
  final List<Map<String, dynamic>> _resultSamples = [];

  @override
  Future<int> insert({required String tableName, required Map<String, dynamic> values}) async {
    if (tableName == 'prompts') {
      _prompts.add(values);
    } else {
      _resultSamples.add(values);
    }
    return 1;
  }

  @override
  Future<int> update({
    required String tableName,
    required Map<String, dynamic> values,
    String? where,
    List<Object?>? whereArgs,
  }) async => 1;

  @override
  Future<List<Map<String, dynamic>>> query({
    required String tableName,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    if (tableName == 'prompts') {
      return _prompts;
    } else {
      return _resultSamples;
    }
  }

  @override
  Future<int> delete({
    required String tableName,
    String? where,
    List<Object?>? whereArgs,
  }) async => 1;

  @override
  Future<void> close() async {}

  @override
  Future<void> clearAllData() async {
    _prompts.clear();
    _resultSamples.clear();
  }
}

void main() {
  group('PromptRepository', () {
    test('createPrompt', () async {
      final fakeDb = FakeDatabaseHelper();
      final repository = PromptRepository(dbHelper: fakeDb);

      final result = await repository.createPrompt(
        title: 'Test Title',
        content: 'Test Content',
        tags: ['tag1', 'tag2'],
      );

      expect(result.title, equals('Test Title'));
      expect(result.content, equals('Test Content'));
      expect(result.tags, equals(['tag1', 'tag2']));
    });

    test('updatePrompt', () async {
      final fakeDb = FakeDatabaseHelper();
      final repository = PromptRepository(dbHelper: fakeDb);
      final existingPrompt = Prompt(
        id: 'test-id',
        title: 'Old Title',
        content: 'Old Content',
        tags: ['old'],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      await repository.updatePrompt(existingPrompt.copyWith(
        title: 'New Title',
        content: 'New Content',
        tags: ['new'],
      ));
    });

    test('deletePrompt', () async {
      final fakeDb = FakeDatabaseHelper();
      final repository = PromptRepository(dbHelper: fakeDb);

      await repository.deletePrompt('test-id');
    });

    test('getPromptById', () async {
      final fakeDb = FakeDatabaseHelper();
      final repository = PromptRepository(dbHelper: fakeDb);

      final result = await repository.getPromptById('test-id');
      expect(result, isNull);
    });

    test('getAllPrompts', () async {
      final fakeDb = FakeDatabaseHelper();
      final repository = PromptRepository(dbHelper: fakeDb);

      final result = await repository.getAllPrompts();
      expect(result, isEmpty);
    });

    test('createResultSample', () async {
      final fakeDb = FakeDatabaseHelper();
      final repository = PromptRepository(dbHelper: fakeDb);

      final result = await repository.createResultSample(
        promptId: 'test-prompt-id',
        filePath: '/test/path/file.txt',
        fileName: 'file.txt',
        fileSize: 1024,
        fileType: 'text',
      );

      expect(result.promptId, equals('test-prompt-id'));
      expect(result.filePath, equals('/test/path/file.txt'));
      expect(result.fileName, equals('file.txt'));
      expect(result.fileSize, equals(1024));
    });

    test('deleteResultSample', () async {
      final fakeDb = FakeDatabaseHelper();
      final repository = PromptRepository(dbHelper: fakeDb);

      await repository.deleteResultSample('result-id');
    });
  });
}
