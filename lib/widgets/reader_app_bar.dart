import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/epub_book.dart';
import '../providers/reader_theme_provider.dart';

class ReaderAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final EpubBook book;
  final int currentChapter;
  final int totalChapters;
  final VoidCallback onMenuPressed;

  const ReaderAppBar({
    super.key,
    required this.book,
    required this.currentChapter,
    required this.totalChapters,
    required this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.9),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            book.title,
            style: Theme.of(context).textTheme.titleMedium,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Chapter $currentChapter of $totalChapters',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.bookmark_border),
          onPressed: () {
            // TODO: Add bookmark functionality
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            _showReaderSettings(context);
          },
        ),
        IconButton(
          icon: const Icon(Icons.menu),
          onPressed: onMenuPressed,
        ),
      ],
    );
  }

  void _showReaderSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const ReaderSettingsPanel(),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class ReaderSettingsPanel extends ConsumerWidget {
  const ReaderSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reading Settings',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),

          // Font Size Slider
          Consumer(
            builder: (context, ref, child) {
              final readerTheme = ref.watch(readerThemeProvider);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Font Size',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Slider(
                    value: readerTheme.fontSize,
                    min: 12.0,
                    max: 32.0,
                    divisions: 20,
                    label: readerTheme.fontSize.round().toString(),
                    onChanged: (value) {
                      ref
                          .read(readerThemeProvider.notifier)
                          .updateFontSize(value);
                    },
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // Font Family
          Consumer(
            builder: (context, ref, child) {
              final readerTheme = ref.watch(readerThemeProvider);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Font Family',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children:
                        ['System Default', 'Serif', 'Sans Serif'].map((font) {
                      return ChoiceChip(
                        label: Text(font),
                        selected: readerTheme.fontFamily == font,
                        onSelected: (selected) {
                          if (selected) {
                            ref
                                .read(readerThemeProvider.notifier)
                                .updateFontFamily(font);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // Theme Toggle
          Consumer(
            builder: (context, ref, child) {
              final readerTheme = ref.watch(readerThemeProvider);
              return SwitchListTile(
                title: const Text('Dark Mode'),
                value: readerTheme.darkMode,
                onChanged: (value) {
                  ref.read(readerThemeProvider.notifier).toggleDarkMode();
                },
              );
            },
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
