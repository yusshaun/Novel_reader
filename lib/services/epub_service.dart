import 'dart:io';
import 'dart:typed_data';
import 'package:epubx/epubx.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/epub_book.dart';

class EpubService {
  final _uuid = const Uuid();

  Future<EpubBook?> parseEpubFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final epub = EpubReader.readBook(bytes);
      
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
      final newPath = path.join(booksDir.path, fileName);
      final copiedFile = await file.copy(newPath);

      // Extract metadata
      final title = epub.Title?.trim() ?? path.basenameWithoutExtension(fileName);
      final author = epub.Author?.trim() ?? 'Unknown Author';
      final description = epub.Description?.trim();
      final publisher = epub.Publisher?.trim();
      final language = epub.Language?.trim();

      // Extract cover image
      Uint8List? coverImage;
      try {
        final coverKey = epub.Content?.Images?.keys.firstWhere(
          (key) => key.toLowerCase().contains('cover'),
          orElse: () => '',
        );
        
        if (coverKey?.isNotEmpty == true) {
          coverImage = epub.Content?.Images?[coverKey]?.Content;
        } else if (epub.Content?.Images?.isNotEmpty == true) {
          // Use first available image as cover
          coverImage = epub.Content?.Images?.values.first.Content;
        }
      } catch (e) {
        // Cover extraction failed, continue without cover
      }

      // Calculate total pages (estimate based on text content)
      int totalPages = 0;
      if (epub.Chapters != null) {
        for (final chapter in epub.Chapters!) {
          final content = chapter.HtmlContent ?? '';
          // Rough estimation: 500 words per page, average 5 chars per word
          final wordCount = content.length ~/ 5;
          totalPages += (wordCount / 500).ceil();
        }
      }

      final book = EpubBook(
        id: _uuid.v4(),
        title: title,
        author: author,
        filePath: copiedFile.path,
        lastRead: DateTime.now(),
        coverImage: coverImage,
        description: description,
        publisher: publisher,
        language: language,
        totalPages: totalPages > 0 ? totalPages : 1,
      );

      return book;
    } catch (e) {
      print('Error parsing EPUB file: $e');
      return null;
    }
  }

  Future<EpubBook?> loadEpubFromPath(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }
      return await parseEpubFile(file);
    } catch (e) {
      print('Error loading EPUB from path: $e');
      return null;
    }
  }

  Future<List<EpubChapter>?> getChapters(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final epub = EpubReader.readBook(bytes);
      return epub?.Chapters;
    } catch (e) {
      print('Error getting chapters: $e');
      return null;
    }
  }

  Future<String?> getChapterContent(String filePath, int chapterIndex) async {
    try {
      final chapters = await getChapters(filePath);
      if (chapters != null && chapterIndex < chapters.length) {
        return chapters[chapterIndex].HtmlContent;
      }
      return null;
    } catch (e) {
      print('Error getting chapter content: $e');
      return null;
    }
  }

  Future<EpubBookRef?> openEpubForReading(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      return EpubReader.openBook(bytes);
    } catch (e) {
      print('Error opening EPUB for reading: $e');
      return null;
    }
  }

  Future<bool> deleteEpubFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting EPUB file: $e');
      return false;
    }
  }

  Future<List<String>> searchInBook(String filePath, String query) async {
    try {
      final chapters = await getChapters(filePath);
      if (chapters == null) return [];

      final results = <String>[];
      for (int i = 0; i < chapters.length; i++) {
        final content = chapters[i].HtmlContent ?? '';
        final lowerContent = content.toLowerCase();
        final lowerQuery = query.toLowerCase();
        
        if (lowerContent.contains(lowerQuery)) {
          // Extract context around the found text
          final index = lowerContent.indexOf(lowerQuery);
          final start = (index - 50).clamp(0, content.length);
          final end = (index + query.length + 50).clamp(0, content.length);
          final context = content.substring(start, end);
          results.add('Chapter ${i + 1}: ...$context...');
        }
      }
      return results;
    } catch (e) {
      print('Error searching in book: $e');
      return [];
    }
  }
}