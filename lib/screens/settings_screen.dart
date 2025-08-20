import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adaptive_theme/adaptive_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          _buildSection(
            context,
            '閱讀',
            [
              _buildReaderSettingsTile(context),
              _buildSyncSettingsTile(context),
            ],
          ),
          _buildSection(
            context,
            '外觀',
            [
              _buildThemeSettingsTile(context),
              _buildLanguageSettingsTile(context),
            ],
          ),
          _buildSection(
            context,
            '儲存',
            [
              _buildStorageSettingsTile(context),
              _buildBackupSettingsTile(context),
            ],
          ),
          _buildSection(
            context,
            '關於',
            [
              _buildAboutTile(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<Widget> children) {
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
      title: const Text('閱讀偏好'),
      subtitle: const Text('字體、主題和閱讀行為'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: Navigate to reader settings
      },
    );
  }

  Widget _buildSyncSettingsTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.sync),
      title: const Text('同步設定'),
      subtitle: const Text('雲端同步和離線閱讀'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: Navigate to sync settings
      },
    );
  }

  Widget _buildThemeSettingsTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.palette),
      title: const Text('主題'),
      subtitle: const Text('淺色、深色或跟隨系統'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showThemeSelector(context);
      },
    );
  }

  Widget _buildLanguageSettingsTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.language),
      title: const Text('語言'),
      subtitle: const Text('應用程式語言'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: Navigate to language settings
      },
    );
  }

  Widget _buildStorageSettingsTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.storage),
      title: const Text('儲存空間'),
      subtitle: const Text('管理已下載的書籍'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: Navigate to storage settings
      },
    );
  }

  Widget _buildBackupSettingsTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.backup),
      title: const Text('備份與還原'),
      subtitle: const Text('備份您的書庫和設定'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: Navigate to backup settings
      },
    );
  }

  Widget _buildAboutTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.info),
      title: const Text('關於'),
      subtitle: const Text('版本資訊和授權'),
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
        title: const Text('選擇主題'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<AdaptiveThemeMode>(
              title: const Text('淺色'),
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
              title: const Text('深色'),
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
              title: const Text('跟隨系統'),
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
        const Text('一個使用 Flutter 開發的跨平台 EPUB 閱讀器。'),
        const SizedBox(height: 16),
        const Text('功能：'),
        const Text('• 支援自訂主題的 EPUB 閱讀'),
        const Text('• 跨裝置同步'),
        const Text('• 可自訂書架'),
        const Text('• 離線閱讀支援'),
      ],
    );
  }
}
