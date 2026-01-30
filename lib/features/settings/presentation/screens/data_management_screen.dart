import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prompt_memo/features/settings/presentation/providers/settings_providers.dart';
import 'package:prompt_memo/features/settings/domain/services/data_export_service.dart';
import 'package:prompt_memo/features/settings/domain/services/cache_service.dart';
import 'package:prompt_memo/features/prompt-management/presentation/providers/prompt_providers.dart';
import 'package:prompt_memo/features/prompt-management/presentation/providers/collection_providers.dart';
import 'package:logging/logging.dart';

class DataManagementScreen extends ConsumerStatefulWidget {
  const DataManagementScreen({super.key});

  @override
  ConsumerState<DataManagementScreen> createState() =>
      _DataManagementScreenState();
}

class _DataManagementScreenState extends ConsumerState<DataManagementScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isClearingCache = false;
  String _lastExportDate = '';
  String _lastImportDate = '';
  final _logger = Logger('DataManagementScreen');
  final _exportService = DataExportService();
  final _cacheService = CacheService();

  @override
  void initState() {
    super.initState();
    _loadDataInfo();
    _updateCacheSize();
  }

  Future<void> _loadDataInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastExportDate = prefs.getString('lastExportDate') ?? 'Never';
      _lastImportDate = prefs.getString('lastImportDate') ?? 'Never';
    });
  }

  Future<void> _updateCacheSize() async {
    final cacheSize = await _cacheService.getCacheSize();
    ref.read(settingsProvider.notifier).updateCacheSize(cacheSize);
  }

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
    });

    try {
      _logger.info('Starting data export');
      final directory = await FilePicker.platform.getDirectoryPath();
      if (directory == null) {
        _logger.info('Export cancelled - no directory selected');
        setState(() {
          _isExporting = false;
        });
        return;
      }

      final promptRepo = ref.read(promptRepositoryProvider);
      final collectionRepo = ref.read(collectionRepositoryProvider);

      await _exportService.exportToFile(directory, promptRepo, collectionRepo);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastExportDate', DateTime.now().toString());

      if (mounted) {
        setState(() {
          _lastExportDate = DateTime.now().toString().substring(0, 16);
          _isExporting = false;
        });

        _logger.info('Data export completed successfully');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data exported successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e, s) {
      _logger.severe('Data export failed', e, s);
      if (mounted) {
        setState(() {
          _isExporting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importData() async {
    setState(() {
      _isImporting = true;
    });

    try {
      _logger.info('Starting data import');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        _logger.info('Import cancelled - no file selected');
        setState(() {
          _isImporting = false;
        });
        return;
      }

      final file = File(result.files.first.path!);
      final jsonData = await file.readAsString();

      final promptRepo = ref.read(promptRepositoryProvider);
      final collectionRepo = ref.read(collectionRepositoryProvider);

      await _exportService.importFromJson(jsonData, promptRepo, collectionRepo);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastImportDate', DateTime.now().toString());

      if (mounted) {
        setState(() {
          _lastImportDate = DateTime.now().toString().substring(0, 16);
          _isImporting = false;
        });

        _logger.info('Data import completed successfully');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data imported successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e, s) {
      _logger.severe('Data import failed', e, s);
      if (mounted) {
        setState(() {
          _isImporting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Cache'),
            content: const Text(
              'Are you sure you want to clear the cache? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Clear'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() {
      _isClearingCache = true;
    });

    try {
      _logger.info('Starting cache clear');
      await _cacheService.clearCache();
      await _updateCacheSize();

      if (mounted) {
        setState(() {
          _isClearingCache = false;
        });

        _logger.info('Cache cleared successfully');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cache cleared successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e, s) {
      _logger.severe('Cache clear failed', e, s);
      if (mounted) {
        setState(() {
          _isClearingCache = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear cache: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Data Management')),
      body: ListView(
        children: [
          _buildSectionHeader('Export & Import'),
          _buildExportCard(),
          const SizedBox(height: 8),
          _buildImportCard(),
          const SizedBox(height: 24),
          _buildSectionHeader('Storage'),
          _buildCacheCard(settings),
          const SizedBox(height: 8),
          _buildStorageInfoCard(),
          const SizedBox(height: 24),
          _buildSectionHeader('Backup'),
          _buildAutoBackupCard(settings),
          const SizedBox(height: 24),
          _buildDangerZone(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildExportCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.file_download, size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export Data',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Export all prompts and collections to a JSON file',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Last export: $_lastExportDate',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isExporting ? null : _exportData,
                icon:
                    _isExporting
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.download),
                label: Text(_isExporting ? 'Exporting...' : 'Export Data'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.file_upload, size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import Data',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Import prompts and collections from a JSON file',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Last import: $_lastImportDate',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isImporting ? null : _importData,
                icon:
                    _isImporting
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.upload),
                label: Text(_isImporting ? 'Importing...' : 'Import Data'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheCard(SettingsState settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage, size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cache',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Temporary files and thumbnails',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Cache size: ${_formatBytes(settings.cacheSize)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isClearingCache ? null : _clearCache,
                icon:
                    _isClearingCache
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.delete_outline),
                label: Text(_isClearingCache ? 'Clearing...' : 'Clear Cache'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageInfoCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info_outline),
        title: const Text('Storage Information'),
        subtitle: const Text('View detailed storage usage'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _showStorageInfoDialog();
        },
      ),
    );
  }

  Widget _buildAutoBackupCard(SettingsState settings) {
    return SwitchListTile(
      secondary: const Icon(Icons.backup),
      title: const Text('Auto Backup'),
      subtitle: const Text('Automatically backup data daily'),
      value: settings.autoSave,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).setAutoSave(value);
      },
    );
  }

  Widget _buildDangerZone() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  'Danger Zone',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'These actions are irreversible. Please be careful.',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  _deleteAllData();
                },
                icon: const Icon(Icons.delete_forever),
                label: const Text('Delete All Data'),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStorageInfoDialog() async {
    final storageInfo = await _cacheService.getStorageInfo();

    if (!mounted) return;

    final dbSize = _cacheService.formatBytes(storageInfo['database'] as int);
    final imagesSize = _cacheService.formatBytes(storageInfo['images'] as int);
    final videosSize = _cacheService.formatBytes(storageInfo['videos'] as int);
    final textsSize = _cacheService.formatBytes(storageInfo['texts'] as int);
    final cacheSize = _cacheService.formatBytes(storageInfo['cache'] as int);

    final totalSize = _cacheService.formatBytes(
      (storageInfo['database'] as int) +
          (storageInfo['images'] as int) +
          (storageInfo['videos'] as int) +
          (storageInfo['texts'] as int) +
          (storageInfo['cache'] as int),
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Storage Information'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StorageInfoRow(label: 'Database', value: dbSize),
                const Divider(),
                _StorageInfoRow(
                  label: 'Images (${storageInfo['imageCount']})',
                  value: imagesSize,
                ),
                const Divider(),
                _StorageInfoRow(
                  label: 'Videos (${storageInfo['videoCount']})',
                  value: videosSize,
                ),
                const Divider(),
                _StorageInfoRow(
                  label: 'Texts (${storageInfo['textCount']})',
                  value: textsSize,
                ),
                const Divider(),
                _StorageInfoRow(label: 'Cache', value: cacheSize),
                const Divider(height: 24),
                Text(
                  'Total: $totalSize',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text('Delete All Data'),
              ],
            ),
            content: const Text(
              'Are you sure you want to delete all data? This action cannot be undone and will permanently remove all prompts and collections.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete All'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        _logger.info('Starting complete data deletion');
        await _cacheService.deleteAllData();
        await _updateCacheSize();

        _logger.info('All data deleted successfully');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All data deleted successfully. App will restart.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }

        await Future.delayed(const Duration(seconds: 2));
      } catch (e, s) {
        _logger.severe('Failed to delete all data', e, s);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _StorageInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _StorageInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
