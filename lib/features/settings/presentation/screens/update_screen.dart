import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

final _logger = Logger('UpdateScreen');

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  bool _isLoading = false;
  bool _hasUpdate = false;
  bool _isChecking = false;
  String _currentVersion = '';
  String _latestVersion = '';
  String _releaseNotes = '';
  String _errorMessage = '';
  String _downloadUrl = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
  }

  Future<void> _loadCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _currentVersion = info.version;
      });
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isChecking = true;
      _errorMessage = '';
    });

    try {
      _logger.info('Checking for updates');
      final dio = Dio();
      final response = await dio.get(
        'https://api.github.com/repos/Q-Bug4/prompt-memo/releases/latest',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final latestVersion = data['tag_name'] as String? ?? '';
        final versionNumber = latestVersion.replaceFirst('v', '');

        if (versionNumber.isNotEmpty && versionNumber != _currentVersion) {
          setState(() {
            _latestVersion = versionNumber;
            _hasUpdate = true;
            _releaseNotes =
                data['body'] as String? ?? 'No release notes available.';
            final assets = data['assets'] as List?;
            _downloadUrl =
                (assets != null && assets.isNotEmpty)
                    ? assets[0]['browser_download_url'] as String? ?? ''
                    : '';
            _isChecking = false;
          });

          if (mounted) {
            _showUpdateAvailableDialog();
          }
        } else {
          setState(() {
            _isChecking = false;
            _hasUpdate = false;
          });

          if (mounted) {
            _showNoUpdateDialog();
          }
        }
      } else {
        throw Exception('Failed to check for updates: ${response.statusCode}');
      }
    } catch (e, s) {
      _logger.warning('Failed to check for updates', e, s);
      setState(() {
        _errorMessage =
            'Failed to check for updates. Please check your internet connection.';
        _isChecking = false;
        _hasUpdate = false;
      });
    }
  }

  void _showUpdateAvailableDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.new_releases, color: Colors.green),
                SizedBox(width: 8),
                Text('Update Available'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Version $_latestVersion is available!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Release Notes:'),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(child: Text(_releaseNotes)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Later'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _downloadUpdate();
                },
                child: const Text('Download Update'),
              ),
            ],
          ),
    );
  }

  void _showNoUpdateDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Up to Date'),
              ],
            ),
            content: Text(
              'You are using the latest version ($_currentVersion).',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _downloadUpdate() async {
    if (_downloadUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download URL not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _logger.info('Downloading update from $_downloadUrl');
      final uri = Uri.parse(_downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _logger.info('Opened download URL in browser');
      } else {
        throw Exception('Could not launch URL');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        _showDownloadStartedDialog();
      }
    } catch (e, s) {
      _logger.severe('Download failed', e, s);
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open download link: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDownloadStartedDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.download, color: Colors.blue),
                SizedBox(width: 8),
                Text('Download Started'),
              ],
            ),
            content: const Text(
              'The download has started in your browser. '
              'Please install the update manually after downloading.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check for Updates')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentVersionCard(),
            const SizedBox(height: 16),
            _buildUpdateButton(),
            const SizedBox(height: 16),
            if (_isChecking) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
            ],
            if (_errorMessage.isNotEmpty) _buildErrorCard(),
            if (_hasUpdate && !_isLoading && !_isChecking)
              _buildUpdateAvailableCard(),
            _buildRecentUpdatesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentVersionCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info),
        title: const Text('Current Version'),
        subtitle: Text(
          _currentVersion.isEmpty ? 'Loading...' : _currentVersion,
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _isChecking ? null : _checkForUpdates,
        icon:
            _isChecking
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : const Icon(Icons.system_update),
        label: const Text('Check for Updates'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateAvailableCard() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.new_releases, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'New Version Available: $_latestVersion',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Release Notes:'),
            const SizedBox(height: 8),
            Text(_releaseNotes),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _downloadUpdate,
                icon: const Icon(Icons.download),
                label: const Text('Download Update'),
                style: FilledButton.styleFrom(backgroundColor: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentUpdatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('Recent Updates', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _buildVersionCard('0.2.0', 'Dec 15, 2024', [
          'Added collection support',
          'Improved search functionality',
          'Bug fixes and performance improvements',
        ]),
        const SizedBox(height: 8),
        _buildVersionCard('0.1.0', 'Nov 20, 2024', [
          'Initial release',
          'Basic prompt management',
          'File attachment support',
        ]),
      ],
    );
  }

  Widget _buildVersionCard(String version, String date, List<String> features) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Version $version',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  date,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Row(
                  children: [const Text('• '), Expanded(child: Text(feature))],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
