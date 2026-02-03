import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:prompt_memo/features/settings/presentation/screens/about_screen.dart';
import 'package:prompt_memo/features/settings/presentation/screens/data_management_screen.dart';
import 'package:prompt_memo/features/settings/presentation/screens/update_screen.dart';
import 'package:prompt_memo/features/settings/presentation/providers/settings_providers.dart';
import 'package:prompt_memo/core/config/app_info.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Appearance'),
          _buildThemeTile(context, ref),
          _buildSectionHeader(context, 'Data'),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Data Management'),
            subtitle: _buildCacheSize(ref),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/settings/data');
            },
          ),
          _buildSectionHeader(context, 'About'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: Text('Version ${AppInfo.appVersion}'),
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
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
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

  Widget _buildThemeTile(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final currentModeLabel = _getThemeLabel(settings.themeMode);

    return ListTile(
      leading: const Icon(Icons.brightness_6),
      title: const Text('Theme'),
      subtitle: Text(currentModeLabel),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showThemeDialog(context, ref, settings.themeMode);
      },
    );
  }

  Widget _buildCacheSize(WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return Text('Cache size: ${_formatBytes(settings.cacheSize)}');
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Text(
            AppInfo.appName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppInfo.appDescription,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          Text(
            'Made with ❤',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(
    BuildContext ctx,
    WidgetRef ref,
    AppThemeMode currentMode,
  ) {
    showDialog(
      context: ctx,
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
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
