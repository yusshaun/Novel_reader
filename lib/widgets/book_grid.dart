import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../models/epub_book.dart';
import '../models/reading_progress.dart';
import '../providers/reading_progress_provider.dart';
import '../providers/bookshelves_provider.dart';
import '../providers/books_provider.dart';

class BookGrid extends ConsumerWidget {
  final List<EpubBook> books;
  final Function(String) onBookTap;
  final int crossAxisCount;

  const BookGrid({
    super.key,
    required this.books,
    required this.onBookTap,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (books.isEmpty) {
      return const Center(
        child: Text('No books to display'),
      );
    }

    return GridView.extent(
      maxCrossAxisExtent: 200,
      childAspectRatio: 0.7,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      padding: const EdgeInsets.all(16),
      children: books
          .map((book) => BookCard(
                book: book,
                onTap: () => onBookTap(book.id),
                progress: ref.watch(readingProgressProvider)[book.id],
              ))
          .toList(),
    );
  }
}

class BookCard extends ConsumerWidget {
  final EpubBook book;
  final VoidCallback onTap;
  final ReadingProgress? progress;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.progress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showBookOptions(context, ref),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                ),
                child: book.coverImage != null
                    ? Image.memory(
                        book.coverImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderCover(context);
                        },
                      )
                    : _buildPlaceholderCover(context),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    LinearProgressIndicator(
                      value: progress?.progressPercentage != null
                          ? (progress!.progressPercentage / 100).clamp(0.0, 1.0)
                          : 0.0,
                      backgroundColor: Theme.of(context).colorScheme.outline,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => BookOptionsSheet(book: book),
    );
  }

  Widget _buildPlaceholderCover(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.3),
            Theme.of(context).colorScheme.secondary.withOpacity(0.3),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book,
            size: 32,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              book.title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class BookOptionsSheet extends ConsumerWidget {
  final EpubBook book;

  const BookOptionsSheet({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookshelves = ref.watch(bookshelvesProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Book Options',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            book.title,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            'by ${book.author}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          const Text('Add to Bookshelf:'),
          const SizedBox(height: 8),
          ...bookshelves.map((shelf) => ListTile(
                leading: Icon(
                  Icons.bookmark,
                  color: Color(shelf.themeColorValue),
                ),
                title: Text(shelf.shelfName),
                onTap: () async {
                  await ref
                      .read(bookshelvesProvider.notifier)
                      .addBookToShelf(shelf.id, book.id);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added to ${shelf.shelfName}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              )),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text('Actions:'),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
            title: const Text(
              'Delete Book',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('Remove from library and delete file'),
            onTap: () => _showDeleteConfirmation(context, ref),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Book'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete "${book.title}"?'),
              const SizedBox(height: 8),
              const Text(
                'This will:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Remove the book from your library'),
              const Text('• Delete the book file from storage'),
              const Text('• Remove from all bookshelves'),
              const Text('• Delete reading progress'),
              const SizedBox(height: 8),
              const Text(
                'This action cannot be undone.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close confirmation dialog
                Navigator.of(context).pop(); // Close options sheet
                await _deleteBook(context, ref);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteBook(BuildContext context, WidgetRef ref) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Deleting book...'),
            ],
          ),
        ),
      );

      // Delete the physical file
      final file = File(book.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Remove from books database
      await ref.read(booksProvider.notifier).removeBook(book.id);

      // Remove from all bookshelves
      final bookshelves = ref.read(bookshelvesProvider);
      for (final shelf in bookshelves) {
        if (shelf.bookIds.contains(book.id)) {
          await ref
              .read(bookshelvesProvider.notifier)
              .removeBookFromShelf(shelf.id, book.id);
        }
      }

      // Remove reading progress
      await ref.read(readingProgressProvider.notifier).deleteProgress(book.id);

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully deleted "${book.title}"'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting book: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
