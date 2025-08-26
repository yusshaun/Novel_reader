import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'epub_book.dart';

part 'bookshelf.g.dart';

@HiveType(typeId: 1)
class BookShelf extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String shelfName;

  @HiveField(2)
  List<String> bookIds;

  @HiveField(3)
  int themeColorValue;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  @HiveField(6)
  String? description;

  @HiveField(7)
  bool isDefault;

  Color get themeColor => Color(themeColorValue);

  set themeColor(Color color) {
    themeColorValue = color.value;
  }

  BookShelf({
    required this.id,
    required this.shelfName,
    required this.bookIds,
    required this.themeColorValue,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.isDefault = false,
  });

  BookShelf copyWith({
    String? id,
    String? shelfName,
    List<String>? bookIds,
    int? themeColorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    bool? isDefault,
  }) {
    return BookShelf(
      id: id ?? this.id,
      shelfName: shelfName ?? this.shelfName,
      bookIds: bookIds ?? List.from(this.bookIds),
      themeColorValue: themeColorValue ?? this.themeColorValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  void addBook(String bookId) {
    if (!bookIds.contains(bookId)) {
      bookIds.add(bookId);
      updatedAt = DateTime.now();
    }
  }

  void removeBook(String bookId) {
    bookIds.remove(bookId);
    updatedAt = DateTime.now();
  }

  void reorderBooks(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final String bookId = bookIds.removeAt(oldIndex);
    bookIds.insert(newIndex, bookId);
    updatedAt = DateTime.now();
  }

  @override
  String toString() {
    return 'BookShelf(id: $id, name: $shelfName, books: ${bookIds.length})';
  }
}
