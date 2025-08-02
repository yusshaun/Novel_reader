import 'dart:io';
import 'dart:typed_data';
import 'package:epubx/epubx.dart' as epubx;
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/epub_book.dart' as models;

class EpubService {
  final _uuid = const Uuid();

  Future<models.EpubBook?> parseEpubFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final epub = await epubx.EpubReader.readBook(bytes);

      // Copy file to app directory
      final appDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory(path.join(appDir.path, 'books'));
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }

      final fileName = path.basename(file.path);
      final targetFile = File(path.join(booksDir.path, fileName));
      await file.copy(targetFile.path);

      // Use basic metadata
      final title = path.basenameWithoutExtension(fileName);
      final author = 'Unknown Author';

      // Calculate total pages estimate
      int totalPages = 100; // Default estimate

      return models.EpubBook(
        id: _uuid.v4(),
        title: title,
        author: author,
        filePath: targetFile.path,
        lastRead: DateTime.now(),
        totalPages: totalPages,
      );
    } catch (e) {
      throw Exception('Error parsing EPUB: $e');
    }
  }

  Future<models.EpubBook?> loadEpubFromPath(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return null;
    }
    return parseEpubFile(file);
  }

  Future<List<String>> searchInBook(String filePath, String query) async {
    // Simplified search - return empty for now
    return [];
  }

  String extractTextFromHtml(String html) {
    // Basic HTML tag removal
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> paginateText(
    String text, {
    int charactersPerPage = 2000,
    double fontSize = 16.0,
    double screenWidth = 400,
    double screenHeight = 600,
  }) {
    final pages = <String>[];
    final words = text.split(' ');
    final buffer = StringBuffer();
    int currentLength = 0;

    for (final word in words) {
      if (currentLength + word.length > charactersPerPage &&
          buffer.isNotEmpty) {
        pages.add(buffer.toString().trim());
        buffer.clear();
        currentLength = 0;
      }

      if (buffer.isNotEmpty) {
        buffer.write(' ');
        currentLength++;
      }

      buffer.write(word);
      currentLength += word.length;
    }

    if (buffer.isNotEmpty) {
      pages.add(buffer.toString().trim());
    }

    return pages.isEmpty ? [''] : pages;
  }
}
