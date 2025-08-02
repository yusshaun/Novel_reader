import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import '../models/bookshelf.dart';

final bookshelvesBoxProvider = Provider<Box<BookShelf>>((ref) {
  return Hive.box<BookShelf>('bookshelves');
});

final bookshelvesProvider =
    StateNotifierProvider<BookshelvesNotifier, List<BookShelf>>((ref) {
  final box = ref.watch(bookshelvesBoxProvider);
  return BookshelvesNotifier(box);
});

final selectedShelfProvider = StateProvider<BookShelf?>((ref) => null);

class BookshelvesNotifier extends StateNotifier<List<BookShelf>> {
  final Box<BookShelf> _box;
  final _uuid = const Uuid();

  BookshelvesNotifier(this._box) : super(_box.values.toList()) {
    _initializeDefaultShelf();
    // Note: Hive 2.x doesn't have listenable, we'll manually refresh
  }

  Future<void> _initializeDefaultShelf() async {
    if (_box.isEmpty) {
      final defaultShelf = BookShelf(
        id: _uuid.v4(),
        shelfName: 'My Library',
        bookIds: [],
        themeColorValue: Colors.blue.value,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDefault: true,
      );
      await _box.put(defaultShelf.id, defaultShelf);
    }
  }

  Future<void> createShelf({
    required String name,
    Color? themeColor,
    String? description,
  }) async {
    final shelf = BookShelf(
      id: _uuid.v4(),
      shelfName: name,
      bookIds: [],
      themeColorValue: (themeColor ?? Colors.blue).value,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      description: description,
    );

    await _box.put(shelf.id, shelf);
    state = _box.values.toList();
  }

  Future<void> updateShelf(BookShelf shelf) async {
    await _box.put(shelf.id, shelf);
    state = _box.values.toList();
  }

  Future<void> deleteShelf(String shelfId) async {
    final shelf = _box.get(shelfId);
    if (shelf != null && !shelf.isDefault) {
      await _box.delete(shelfId);
      state = _box.values.toList();
    }
  }

  Future<void> addBookToShelf(String shelfId, String bookId) async {
    final shelf = _box.get(shelfId);
    if (shelf != null) {
      shelf.addBook(bookId);
      await _box.put(shelfId, shelf);
      state = _box.values.toList();
    }
  }

  Future<void> removeBookFromShelf(String shelfId, String bookId) async {
    final shelf = _box.get(shelfId);
    if (shelf != null) {
      shelf.removeBook(bookId);
      await _box.put(shelfId, shelf);
      state = _box.values.toList();
    }
  }

  Future<void> reorderBooksInShelf(
      String shelfId, int oldIndex, int newIndex) async {
    final shelf = _box.get(shelfId);
    if (shelf != null) {
      shelf.reorderBooks(oldIndex, newIndex);
      await _box.put(shelfId, shelf);
      state = _box.values.toList();
    }
  }

  BookShelf? getDefaultShelf() {
    return state.firstWhere(
      (shelf) => shelf.isDefault,
      orElse: () => state.isNotEmpty
          ? state.first
          : throw StateError('No shelves available'),
    );
  }

  List<BookShelf> getShelvesContainingBook(String bookId) {
    return state.where((shelf) => shelf.bookIds.contains(bookId)).toList();
  }

  BookShelf? getShelfById(String shelfId) {
    return _box.get(shelfId);
  }
}
