import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/epub_book.dart';
import '../services/epub_service.dart';

final booksBoxProvider = Provider<Box<EpubBook>>((ref) {
  return Hive.box<EpubBook>('books');
});

final booksProvider =
    StateNotifierProvider<BooksNotifier, List<EpubBook>>((ref) {
  final box = ref.watch(booksBoxProvider);
  return BooksNotifier(box);
});

final epubServiceProvider = Provider<EpubService>((ref) {
  return EpubService();
});

final selectedBookProvider = StateProvider<EpubBook?>((ref) => null);

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredBooksProvider = Provider<List<EpubBook>>((ref) {
  final books = ref.watch(booksProvider);
  final query = ref.watch(searchQueryProvider);

  if (query.isEmpty) {
    return books;
  }

  return books.where((book) {
    return book.title.toLowerCase().contains(query.toLowerCase()) ||
        book.author.toLowerCase().contains(query.toLowerCase());
  }).toList();
});

class BooksNotifier extends StateNotifier<List<EpubBook>> {
  final Box<EpubBook> _box;

  BooksNotifier(this._box) : super(_box.values.toList()) {
    // Note: Hive 2.x doesn't have listenable, we'll manually refresh
  }

  Future<void> addBook(EpubBook book) async {
    await _box.put(book.id, book);
    state = _box.values.toList();
  }

  Future<void> removeBook(String bookId) async {
    await _box.delete(bookId);
    state = _box.values.toList();
  }

  Future<void> updateBook(EpubBook book) async {
    await _box.put(book.id, book);
    state = _box.values.toList();
  }

  List<EpubBook> getRecentBooks({int limit = 10}) {
    final books = List<EpubBook>.from(state);
    books.sort((a, b) => b.lastRead.compareTo(a.lastRead));
    return books.take(limit).toList();
  }

  List<EpubBook> getBooksByAuthor(String author) {
    return state.where((book) => book.author == author).toList();
  }

  List<String> getAllAuthors() {
    return state.map((book) => book.author).toSet().toList()..sort();
  }

  List<String> getAllGenres() {
    final genres = <String>{};
    for (final book in state) {
      if (book.genres != null) {
        genres.addAll(book.genres!);
      }
    }
    return genres.toList()..sort();
  }
}
