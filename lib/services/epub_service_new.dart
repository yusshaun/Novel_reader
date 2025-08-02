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

      if (epub == null) {
        throw Exception('Failed to parse EPUB file');
      }

      // Copy file to app directory
      final appDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory(path.join(appDir.path, 'books'));
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }

      final fileName = path.basename(file.path);
      final targetFile = File(path.join(booksDir.path, fileName));
      await file.copy(targetFile.path);

      // Extract metadata - using schema property for metadata
      final title = epub.Schema?.Package?.Metadata?.Titles?.isNotEmpty == true
          ? epub.Schema!.Package!.Metadata!.Titles!.first.Title?.trim()
          : null;
      final author =
          epub.Schema?.Package?.Metadata?.Creators?.isNotEmpty == true
              ? epub.Schema!.Package!.Metadata!.Creators!.first.Creator?.trim()
              : null;

      final finalTitle = title ?? path.basenameWithoutExtension(fileName);
      final finalAuthor = author ?? 'Unknown Author';

      // Try to extract cover image
      Uint8List? coverImage;
      try {
        if (epub.Content?.Images?.isNotEmpty == true) {
          final firstImage = epub.Content!.Images!.values.first;
          if (firstImage.Content != null) {
            coverImage = Uint8List.fromList(firstImage.Content!);
          }
        }
      } catch (e) {
        // Ignore cover extraction errors
      }

      // Calculate total pages estimate
      int totalPages = 0;
      if (epub.Chapters != null) {
        for (final chapter in epub.Chapters!) {
          final content = chapter.HtmlContent ?? '';
          totalPages += (content.length / 1000).ceil(); // Rough estimate
        }
      }

      return models.EpubBook(
        id: _uuid.v4(),
        title: finalTitle,
        author: finalAuthor,
        filePath: targetFile.path,
        lastRead: DateTime.now(),
        coverImage: coverImage,
        description: null, // We'll skip complex metadata for now
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

  Future<List<epubx.EpubChapter>?> getChapters(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final epub = await epubx.EpubReader.readBook(bytes);
      return epub?.Chapters;
    } catch (e) {
      return null;
    }
  }

  Future<String> getChapterContent(epubx.EpubChapter chapter) async {
    return chapter.HtmlContent ?? '';
  }

  Future<List<String>> searchInBook(String filePath, String query) async {
    try {
      final chapters = await getChapters(filePath);
      if (chapters == null) return [];

      final results = <String>[];
      for (final chapter in chapters) {
        final content = await getChapterContent(chapter);
        if (content.toLowerCase().contains(query.toLowerCase())) {
          // Extract context around the match
          final index = content.toLowerCase().indexOf(query.toLowerCase());
          final start = (index - 50).clamp(0, content.length);
          final end = (index + query.length + 50).clamp(0, content.length);
          final context = content.substring(start, end);
          results.add(context);
        }
      }
      return results;
    } catch (e) {
      return [];
    }
  }

  Future<epubx.EpubBookRef?> openEpubForReading(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      return epubx.EpubReader.openBook(bytes);
    } catch (e) {
      return null;
    }
  }

  String extractTextFromHtml(String html) {
    // Basic HTML tag removal - you might want to use a proper HTML parser
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
