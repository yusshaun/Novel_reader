import 'dart:typed_data';
import 'package:hive/hive.dart';

part 'epub_book.g.dart';

@HiveType(typeId: 0)
class EpubBook extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String author;

  @HiveField(3)
  Uint8List? coverImage;

  @HiveField(4)
  String filePath;

  @HiveField(5)
  DateTime lastRead;

  @HiveField(6)
  String? description;

  @HiveField(7)
  List<String>? genres;

  @HiveField(8)
  String? publisher;

  @HiveField(9)
  DateTime? publishDate;

  @HiveField(10)
  int totalPages;

  @HiveField(11)
  String? language;

  EpubBook({
    required this.id,
    required this.title,
    required this.author,
    this.coverImage,
    required this.filePath,
    required this.lastRead,
    this.description,
    this.genres,
    this.publisher,
    this.publishDate,
    this.totalPages = 0,
    this.language,
  });

  EpubBook copyWith({
    String? id,
    String? title,
    String? author,
    Uint8List? coverImage,
    bool? clearCoverImage,
    String? filePath,
    DateTime? lastRead,
    String? description,
    List<String>? genres,
    String? publisher,
    DateTime? publishDate,
    int? totalPages,
    String? language,
  }) {
    return EpubBook(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverImage:
          clearCoverImage == true ? null : (coverImage ?? this.coverImage),
      filePath: filePath ?? this.filePath,
      lastRead: lastRead ?? this.lastRead,
      description: description ?? this.description,
      genres: genres ?? this.genres,
      publisher: publisher ?? this.publisher,
      publishDate: publishDate ?? this.publishDate,
      totalPages: totalPages ?? this.totalPages,
      language: language ?? this.language,
    );
  }

  @override
  String toString() {
    return 'EpubBook(id: $id, title: $title, author: $author)';
  }
}
