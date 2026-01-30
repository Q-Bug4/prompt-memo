import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:prompt_memo/features/settings/presentation/screens/about_screen.dart';
import 'package:prompt_memo/features/settings/presentation/screens/data_management_screen.dart';
import 'package:prompt_memo/features/settings/presentation/screens/update_screen.dart';
import 'package:prompt_memo/features/settings/presentation/providers/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = packageInfo.version;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildSectionHeader('Appearance'),
          _buildThemeTile(settings),
          _buildThumbnailsTile(settings),
          _buildSectionHeader('Preferences'),
          _buildAutoSaveTile(settings),
          _buildSectionHeader('Data'),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Data Management'),
            subtitle: Text('Cache size: ${_formatBytes(settings.cacheSize)}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/settings/data');
            },
          ),
          _buildSectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: Text('Version $_appVersion'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/settings/about');
            },
          ),
          ListTile(
            leading: const Icon(Icons.system_update),
            title: const Text('Check for Updates'),
            subtitle: const Text('Get the latest version'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/settings/update');
            },
          ),
          _buildFooter(),
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

  Widget _buildThemeTile(SettingsState settings) {
    return ListTile(
      leading: const Icon(Icons.brightness_6),
      title: const Text('Theme'),
      subtitle: Text(_getThemeLabel(settings.themeMode)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showThemeDialog(settings.themeMode);
      },
    );
  }

  Widget _buildThumbnailsTile(SettingsState settings) {
    return SwitchListTile(
      secondary: const Icon(Icons.image),
      title: const Text('Show Thumbnails'),
      subtitle: const Text('Display image thumbnails in list'),
      value: settings.showThumbnails,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).setShowThumbnails(value);
      },
    );
  }

  Widget _buildAutoSaveTile(SettingsState settings) {
    return SwitchListTile(
      secondary: const Icon(Icons.save),
      title: const Text('Auto Save'),
      subtitle: const Text('Automatically save changes'),
      value: settings.autoSave,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).setAutoSave(value);
      },
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Prompt Memo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'A simple prompt management app',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          Text(
            'Made with ❤️',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(AppThemeMode currentMode) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Theme'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  AppThemeMode.values.map((mode) {
                    return RadioListTile<AppThemeMode>(
                      title: Text(_getThemeLabel(mode)),
                      value: mode,
                      groupValue: currentMode,
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(settingsProvider.notifier)
                              .setThemeMode(value);
                          Navigator.pop(context);
                        }
                      },
                    );
                  }).toList(),
            ),
          ),
    );
  }

  String _getThemeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return 'System Default';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
