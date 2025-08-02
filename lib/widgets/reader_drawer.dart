import 'package:flutter/material.dart';
import 'package:epubx/epubx.dart';

class ReaderDrawer extends StatelessWidget {
  final List<EpubChapter> chapters;
  final int currentChapterIndex;
  final Function(int) onChapterSelected;

  const ReaderDrawer({
    super.key,
    required this.chapters,
    required this.currentChapterIndex,
    required this.onChapterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.menu_book,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Table of Contents',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                ),
                Text(
                  '${chapters.length} chapters',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                final isCurrentChapter = index == currentChapterIndex;

                return ListTile(
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: isCurrentChapter
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceVariant,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isCurrentChapter
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  title: Text(
                    chapter.Anchor?.split('#').last ?? 'Chapter ${index + 1}',
                    style: isCurrentChapter
                        ? TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  ),
                  selected: isCurrentChapter,
                  onTap: () => onChapterSelected(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
