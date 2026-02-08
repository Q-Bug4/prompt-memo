import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:prompt_memo/features/prompt-management/data/repositories/prompt_repository.dart';
import 'package:prompt_memo/features/prompt-management/data/repositories/collection_repository.dart';
import 'package:prompt_memo/shared/models/prompt.dart';
import 'package:prompt_memo/shared/models/collection.dart';
import 'package:prompt_memo/shared/models/result_sample.dart';
import 'package:logging/logging.dart';

class DataExportService {
  static final _logger = Logger('DataExportService');

  Future<ExportResult> exportWithData(
    PromptRepository promptRepo,
    CollectionRepository collectionRepo,
  ) async {
    try {
      _logger.info('Starting data export with attachments');

      final prompts = await promptRepo.getAllPrompts();
      final collections = await collectionRepo.getAllCollections();

      final allSampleFiles = <ResultSample>[];

      for (var prompt in prompts) {
        try {
          final samples = await promptRepo.getResultSamples(prompt.id);
          for (var sample in samples) {
            allSampleFiles.add(sample);
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
        'version': '1.1.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'prompts': prompts.map((p) => p.toJson()).toList(),
        'collections': collections.map((c) => c.toJson()).toList(),
        'samples': allSampleFiles.map((s) => s.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      _logger.info('Data export completed successfully');

      return ExportResult(
        jsonString: jsonString,
        exportedFiles: allSampleFiles.map((s) => s.filePath).toList(),
        totalFiles: allSampleFiles.length,
      );
    } catch (e, s) {
      _logger.severe('Data export failed', e, s);
      rethrow;
    }
  }

  Future<File> exportAllToDirectory(
    String directory,
    PromptRepository promptRepo,
    CollectionRepository collectionRepo,
  ) async {
    final exportResult = await exportWithData(promptRepo, collectionRepo);
    final exportBasePath = await getExportDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .substring(0, 19);
    final backupFolderName = 'prompt_memo_backup_$timestamp';
    final backupDir = Directory('$exportBasePath/$backupFolderName');

    // Create backup folder
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final jsonFile = File('${backupDir.path}/data.json');
    await jsonFile.writeAsString(exportResult.jsonString);

    final attachmentsDir = Directory('${backupDir.path}/attachments');
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    int copiedFiles = 0;
    int totalSize = 0;

    for (var filePath in exportResult.exportedFiles) {
      try {
        final sourceFile = File(filePath);
        if (await sourceFile.exists()) {
          final fileName = p.basename(filePath);
          final destFile = File('${attachmentsDir.path}/$fileName');

          await sourceFile.copy(destFile.path);
          copiedFiles++;

          final fileSize = await sourceFile.length();
          totalSize += fileSize;

          _logger.fine('Copied: $fileName');
        }
      } catch (e, s) {
        _logger.warning('Failed to copy file: $filePath', e, s);
      }
    }

    _logger.info(
      'Export completed: $copiedFiles files, ${_formatBytes(totalSize)}',
    );

    // Create zip file
    final zipFile = File('$exportBasePath/${backupFolderName}.zip');
    await createZip(backupDir, zipFile);

    // Delete backup folder after zip is created
    await backupDir.delete(recursive: true);

    _logger.info('Zip created: ${zipFile.path}');

    return zipFile;
  }

  Future<void> createZip(Directory sourceDir, File zipFile) async {
    final archive = Archive();

    await for (final entity in sourceDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = p.relative(entity.path, from: sourceDir.path);
        final fileBytes = await entity.readAsBytes();
        final file = ArchiveFile(relativePath, fileBytes.length, fileBytes);
        archive.addFile(file);
      }
    }

    final zipBytes = ZipEncoder().encode(archive);
    await zipFile.writeAsBytes(zipBytes!);
  }

  Future<String> getExportDirectory() async {
    print('=== getExportDirectory called ===');

    if (kIsWeb) {
      throw UnsupportedError('Web platform not supported');
    }

    _logger.info(
      'Getting export directory for platform: ${Platform.operatingSystem}',
    );
    print('Platform: ${Platform.operatingSystem}');

    Directory? dir;

    if (Platform.isAndroid) {
      print('Android platform detected');
      // Use public Downloads directory instead of app-specific directory
      dir = Directory('/storage/emulated/0/Download');
      _logger.info('Android public Downloads directory: ${dir.path}');
      print('Downloads directory: ${dir.path}');
      print('Using Downloads directory');
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      print('Desktop platform detected');
      final supportDir = await getApplicationSupportDirectory();
      _logger.info('Desktop Support directory: $supportDir');
      print('Support directory: $supportDir');
      dir = supportDir;
    } else {
      print('Other platform detected');
      final docsDir = await getApplicationDocumentsDirectory();
      _logger.info('Other platform Documents directory: $docsDir');
      print('Documents directory: $docsDir');
      dir = docsDir;
    }

    if (dir == null) {
      _logger.severe('Failed to get export directory');
      print('ERROR: dir is null!');
      throw Exception('Failed to get export directory');
    }

    _logger.info('Final export directory: ${dir.path}');
    print('Final export directory: ${dir.path}');
    return dir.path;
  }

  Future<ImportResult> importFromJson(
    String jsonData,
    PromptRepository promptRepo,
    CollectionRepository collectionRepo, {
    String? attachmentsBasePath,
  }) async {
    try {
      _logger.info('Starting data import with attachments');

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
            // Try to copy file from attachments directory if provided
            File? targetFile;

            if (attachmentsBasePath != null) {
              final attachmentsDir = Directory(
                '$attachmentsBasePath/attachments',
              );
              final fileName = sample.filePath.split('/').last;
              final sourceFile = File('${attachmentsDir.path}/$fileName');

              if (await sourceFile.exists()) {
                // Copy to app's results directory
                final appSupportDir = await getApplicationSupportDirectory();
                final resultsDir = Directory('${appSupportDir.path}/results');
                if (!await resultsDir.exists()) {
                  await resultsDir.create(recursive: true);
                }

                targetFile = File('${resultsDir.path}/$fileName');
                await sourceFile.copy(targetFile.path);
                _logger.fine('Copied sample file: $fileName');
              }
            }

            // Use copied file or check if original file exists
            final file = targetFile ?? File(sample.filePath);
            if (await file.exists()) {
              await promptRepo.createResultSample(
                promptId: newPromptId,
                filePath: file.path,
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

      return ImportResult(
        importedCollections: oldToNewCollectionIds.length,
        importedPrompts: oldToNewPromptIds.length,
        importedSamples: samplesData.length,
      );
    } catch (e, s) {
      _logger.severe('Data import failed', e, s);
      rethrow;
    }
  }

  Future<ImportResult> importFromZip(
    String zipPath,
    PromptRepository promptRepo,
    CollectionRepository collectionRepo,
  ) async {
    print('=== IMPORT FROM ZIP ===');
    _logger.info('Importing from zip: $zipPath');

    // Extract zip
    final extractDir = await extractZip(zipPath);

    // Find data.json file
    final jsonFile = File('${extractDir.path}/data.json');
    if (!await jsonFile.exists()) {
      // Try alternative location
      final altJsonFile = File(
        '${extractDir.path}/prompt_memo_backup/data.json',
      );
      if (!await altJsonFile.exists()) {
        throw Exception('Invalid backup file: data.json not found');
      }
    }

    final jsonData = await jsonFile.readAsString();

    // Import with attachments from extracted directory
    final result = await importFromJson(
      jsonData,
      promptRepo,
      collectionRepo,
      attachmentsBasePath: extractDir.path,
    );

    // Cleanup
    await extractDir.delete(recursive: true);

    return result;
  }

  Future<Directory> extractZip(String zipPath) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final tempDir = await getTemporaryDirectory();
    final extractDir = Directory(
      '${tempDir.path}/import_${DateTime.now().millisecondsSinceEpoch}',
    );
    await extractDir.create(recursive: true);

    for (final file in archive) {
      final filePath = '${extractDir.path}/${file.name}';
      if (file.isFile) {
        final outputFile = File(filePath);
        await outputFile.create(recursive: true);
        await outputFile.writeAsBytes(file.content as List<int>);
      }
    }

    _logger.info('Extracted zip to: ${extractDir.path}');
    return extractDir;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class ExportResult {
  final String jsonString;
  final List<String> exportedFiles;
  final int totalFiles;

  const ExportResult({
    required this.jsonString,
    required this.exportedFiles,
    required this.totalFiles,
  });

  int get exportedFilesCount => exportedFiles.length;
  int get totalFilesCount => totalFiles;
}

class ImportResult {
  final int importedCollections;
  final int importedPrompts;
  final int importedSamples;

  const ImportResult({
    required this.importedCollections,
    required this.importedPrompts,
    required this.importedSamples,
  });
}
