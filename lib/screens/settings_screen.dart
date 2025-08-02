import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adaptive_theme/adaptive_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSection(
            context,
            'Reading',
            [
              _buildReaderSettingsTile(context),
              _buildSyncSettingsTile(context),
            ],
          ),
          _buildSection(
            context,
            'Appearance',
            [
              _buildThemeSettingsTile(context),
              _buildLanguageSettingsTile(context),
            ],
          ),
          _buildSection(
            context,
            'Storage',
            [
              _buildStorageSettingsTile(context),
              _buildBackupSettingsTile(context),
            ],
          ),
          _buildSection(
            context,
            'About',
            [
              _buildAboutTile(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildReaderSettingsTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.auto_stories),
      title: const Text('Reading Preferences'),
      subtitle: const Text('Font, themes, and reading behavior'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: Navigate to reader settings
      },
    );
  }

  Widget _buildSyncSettingsTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.sync),
      title: const Text('Sync Settings'),
      subtitle: const Text('Cloud sync and offline reading'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: Navigate to sync settings
      },
    );
  }

  Widget _buildThemeSettingsTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.palette),
      title: const Text('Theme'),
      subtitle: const Text('Light, dark, or system'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showThemeSelector(context);
      },
    );
  }

  Widget _buildLanguageSettingsTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.language),
      title: const Text('Language'),
      subtitle: const Text('App language'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: Navigate to language settings
      },
    );
  }

  Widget _buildStorageSettingsTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.storage),
      title: const Text('Storage'),
      subtitle: const Text('Manage downloaded books'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: Navigate to storage settings
      },
    );
  }

  Widget _buildBackupSettingsTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.backup),
      title: const Text('Backup & Restore'),
      subtitle: const Text('Backup your library and settings'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: Navigate to backup settings
      },
    );
  }

  Widget _buildAboutTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.info),
      title: const Text('About'),
      subtitle: const Text('Version info and licenses'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showAboutDialog(context);
      },
    );
  }

  void _showThemeSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<AdaptiveThemeMode>(
              title: const Text('Light'),
              value: AdaptiveThemeMode.light,
              groupValue: AdaptiveTheme.of(context).mode,
              onChanged: (mode) {
                if (mode != null) {
                  AdaptiveTheme.of(context).setThemeMode(mode);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<AdaptiveThemeMode>(
              title: const Text('Dark'),
              value: AdaptiveThemeMode.dark,
              groupValue: AdaptiveTheme.of(context).mode,
              onChanged: (mode) {
                if (mode != null) {
                  AdaptiveTheme.of(context).setThemeMode(mode);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<AdaptiveThemeMode>(
              title: const Text('System'),
              value: AdaptiveThemeMode.system,
              groupValue: AdaptiveTheme.of(context).mode,
              onChanged: (mode) {
                if (mode != null) {
                  AdaptiveTheme.of(context).setThemeMode(mode);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Novel Reader',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.book, size: 48),
      children: [
        const Text('A cross-platform EPUB reader built with Flutter.'),
        const SizedBox(height: 16),
        const Text('Features:'),
        const Text('• EPUB reading with customizable themes'),
        const Text('• Cross-device sync'),
        const Text('• Customizable bookshelves'),
        const Text('• Offline reading support'),
      ],
    );
  }
}