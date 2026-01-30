import 'dart:convert';
import 'dart:io';
import 'package:prompt_memo/features/prompt-management/data/repositories/prompt_repository.dart';
import 'package:prompt_memo/features/prompt-management/data/repositories/collection_repository.dart';
import 'package:prompt_memo/shared/models/prompt.dart';
import 'package:prompt_memo/shared/models/collection.dart';
import 'package:prompt_memo/shared/models/result_sample.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

class DataExportService {
  static final _logger = Logger('DataExportService');

  Future<String> exportToJson(
    PromptRepository promptRepo,
    CollectionRepository collectionRepo,
  ) async {
    try {
      _logger.info('Starting data export');

      final prompts = await promptRepo.getAllPrompts();
      final collections = await collectionRepo.getAllCollections();

      List<Map<String, dynamic>> promptSamples = [];
      for (var prompt in prompts) {
        try {
          final samples = await promptRepo.getResultSamples(prompt.id);
          for (var sample in samples) {
            promptSamples.add(sample.toJson());
          }
        } catch (e, s) {
          _logger.warning(
            'Failed to export samples for prompt ${prompt.id}',
            e,
            s,
          );
        }
      }

      final exportData = {
        'version': '1.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'prompts': prompts.map((p) => p.toJson()).toList(),
        'collections': collections.map((c) => c.toJson()).toList(),
        'samples': promptSamples,
      };

      final jsonString = JsonEncoder.withIndent('  ').convert(exportData);
      _logger.info('Data export completed successfully');
      return jsonString;
    } catch (e, s) {
      _logger.severe('Data export failed', e, s);
      rethrow;
    }
  }

  Future<File> exportToFile(
    String directory,
    PromptRepository promptRepo,
    CollectionRepository collectionRepo,
  ) async {
    final jsonData = await exportToJson(promptRepo, collectionRepo);
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('$directory/prompt_memo_backup_$timestamp.json');
    await file.writeAsString(jsonData);
    _logger.info('Exported data to ${file.path}');
    return file;
  }

  Future<void> importFromJson(
    String jsonData,
    PromptRepository promptRepo,
    CollectionRepository collectionRepo,
  ) async {
    try {
      _logger.info('Starting data import');
      final data = jsonDecode(jsonData) as Map<String, dynamic>;

      if (!data.containsKey('version')) {
        throw Exception('Invalid backup file format');
      }

      final samplesData = data['samples'] as List<dynamic>? ?? [];
      final promptsData = data['prompts'] as List<dynamic>? ?? [];
      final collectionsData = data['collections'] as List<dynamic>? ?? [];

      final existingCollections = await collectionRepo.getAllCollections();
      final collectionIdMap = <String, String>{};

      for (var collection in existingCollections) {
        collectionIdMap[collection.name] = collection.id;
      }

      final oldToNewCollectionIds = <String, String>{};
      final oldToNewPromptIds = <String, String>{};

      for (var collectionData in collectionsData) {
        try {
          final collection = Collection.fromJson(collectionData);
          final existingId = collectionIdMap[collection.name];

          if (existingId != null) {
            oldToNewCollectionIds[collection.id] = existingId;
            _logger.fine(
              'Collection "${collection.name}" already exists, using existing ID',
            );
          } else {
            await collectionRepo.createCollection(
              name: collection.name,
              description: collection.description,
            );
            final newCollections = await collectionRepo.getAllCollections();
            final newCollection = newCollections.firstWhere(
              (c) => c.name == collection.name,
            );
            oldToNewCollectionIds[collection.id] = newCollection.id;
            _logger.fine('Imported collection: ${collection.name}');
          }
        } catch (e, s) {
          _logger.warning('Failed to import collection', e, s);
        }
      }

      final existingPrompts = await promptRepo.getAllPrompts();
      final promptTitleMap = <String, Prompt>{};

      for (var prompt in existingPrompts) {
        promptTitleMap[prompt.title] = prompt;
      }

      for (var promptData in promptsData) {
        try {
          final prompt = Prompt.fromJson(promptData);
          final existingPrompt = promptTitleMap[prompt.title];

          if (existingPrompt != null) {
            oldToNewPromptIds[prompt.id] = existingPrompt.id;
            _logger.fine('Prompt "${prompt.title}" already exists, skipping');
          } else {
            final newCollectionId =
                prompt.collectionId != null
                    ? oldToNewCollectionIds[prompt.collectionId]
                    : null;

            final newPrompt = await promptRepo.createPrompt(
              title: prompt.title,
              content: prompt.content,
              collectionId: newCollectionId,
              tags: prompt.tags,
            );

            oldToNewPromptIds[prompt.id] = newPrompt.id;
            _logger.fine('Imported prompt: ${prompt.title}');
          }
        } catch (e, s) {
          _logger.warning('Failed to import prompt', e, s);
        }
      }

      for (var sampleData in samplesData) {
        try {
          final sample = ResultSample.fromJson(sampleData);
          final newPromptId = oldToNewPromptIds[sample.promptId];

          if (newPromptId != null) {
            final file = File(sample.filePath);
            if (await file.exists()) {
              await promptRepo.createResultSample(
                promptId: newPromptId,
                filePath: sample.filePath,
                fileName: sample.fileName,
                fileType: sample.fileType.name,
                fileSize: sample.fileSize,
                mimeType: sample.mimeType,
                width: sample.width,
                height: sample.height,
                durationSeconds: sample.durationSeconds,
              );
              _logger.fine('Imported sample: ${sample.fileName}');
            } else {
              _logger.warning('Sample file not found: ${sample.filePath}');
            }
          }
        } catch (e, s) {
          _logger.warning('Failed to import sample', e, s);
        }
      }

      _logger.info('Data import completed successfully');
    } catch (e, s) {
      _logger.severe('Data import failed', e, s);
      rethrow;
    }
  }
}
