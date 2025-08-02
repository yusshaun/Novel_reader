import 'package:flutter_test/flutter_test.dart';
import 'package:novel_reader/models/epub_book.dart';
import 'package:novel_reader/models/bookshelf.dart';
import 'package:novel_reader/models/reader_theme.dart';
import 'package:novel_reader/models/reading_progress.dart';

void main() {
  group('Data Models Tests', () {
    test('EpubBook model creation and copyWith', () {
      final book = EpubBook(
        id: 'test-id',
        title: 'Test Book',
        author: 'Test Author',
        filePath: '/path/to/book.epub',
        lastRead: DateTime.now(),
      );

      expect(book.id, 'test-id');
      expect(book.title, 'Test Book');
      expect(book.author, 'Test Author');

      final updatedBook = book.copyWith(title: 'Updated Title');
      expect(updatedBook.title, 'Updated Title');
      expect(updatedBook.author, 'Test Author'); // Should remain unchanged
    });

    test('BookShelf model book management', () {
      final shelf = BookShelf(
        id: 'shelf-id',
        shelfName: 'My Books',
        bookIds: [],
        themeColorValue: 0xFF2196F3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(shelf.bookIds.length, 0);

      shelf.addBook('book-1');
      expect(shelf.bookIds.length, 1);
      expect(shelf.bookIds.contains('book-1'), true);

      shelf.addBook('book-1'); // Should not add duplicate
      expect(shelf.bookIds.length, 1);

      shelf.removeBook('book-1');
      expect(shelf.bookIds.length, 0);
    });

    test('ReaderTheme font size validation', () {
      final theme = ReaderTheme();
      expect(theme.isValidFontSize, true); // Default 16.0 should be valid

      final smallTheme = theme.copyWith(fontSize: 10.0);
      expect(smallTheme.isValidFontSize, false); // Below minimum

      final largeTheme = theme.copyWith(fontSize: 35.0);
      expect(largeTheme.isValidFontSize, false); // Above maximum

      final validTheme = theme.copyWith(fontSize: 20.0);
      expect(validTheme.isValidFontSize, true); // Within range
    });

    test('ReadingProgress updates correctly', () {
      final progress = ReadingProgress(
        id: 'progress-id',
        bookId: 'book-id',
        timestamp: DateTime.now(),
      );

      expect(progress.progressPercentage, 0.0);

      progress.updateProgress(
        page: 50,
        additionalReadingTime: const Duration(minutes: 30),
      );

      expect(progress.lastPage, 50);
      expect(progress.readingTime, const Duration(minutes: 30));
    });

    test('ReadingProgress calculates percentage correctly', () {
      final progress = ReadingProgress(
        id: 'progress-id',
        bookId: 'book-id',
        timestamp: DateTime.now(),
        totalPages: 100,
      );

      progress.updateProgress(page: 25);
      expect(progress.progressPercentage, 25.0);

      progress.updateProgress(page: 75);
      expect(progress.progressPercentage, 75.0);
    });
  });
}