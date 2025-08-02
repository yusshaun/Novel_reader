import 'package:flutter/material.dart';
import '../models/epub_book.dart';

class ReaderAppBar extends StatelessWidget implements PreferredSizeWidget {
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
  Widget build(BuildContext context) {
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

class ReaderSettingsPanel extends StatelessWidget {
  const ReaderSettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
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
          Text(
            'Font Size',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: 16.0, // TODO: Connect to reader theme
            min: 12.0,
            max: 32.0,
            divisions: 20,
            label: '16', // TODO: Connect to actual value
            onChanged: (value) {
              // TODO: Update font size
            },
          ),
          
          const SizedBox(height: 16),
          
          // Font Family
          Text(
            'Font Family',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('NotoSans'),
                selected: true, // TODO: Connect to actual selection
                onSelected: (selected) {
                  // TODO: Update font family
                },
              ),
              ChoiceChip(
                label: const Text('Roboto'),
                selected: false,
                onSelected: (selected) {
                  // TODO: Update font family
                },
              ),
              ChoiceChip(
                label: const Text('OpenSans'),
                selected: false,
                onSelected: (selected) {
                  // TODO: Update font family
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Theme Toggle
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: false, // TODO: Connect to theme
            onChanged: (value) {
              // TODO: Toggle dark mode
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