import 'dart:io';
import 'package:epubx/epubx.dart' as epubx;
import '../models/epub_book.dart';

/// 負責EPUB內容的載入、解析和處理
class EpubContentManager {
  List<epubx.EpubChapter> _chapters = [];
  String _originalText = '';

  List<epubx.EpubChapter> get chapters => _chapters;
  String get originalText => _originalText;

  /// 載入EPUB書籍內容
  Future<LoadResult> loadBook(EpubBook book) async {
    try {
      print('Loading book from: ${book.filePath}');
      final file = File(book.filePath);

      if (!await file.exists()) {
        return LoadResult.error('Book file not found at ${book.filePath}');
      }

      final bytes = await file.readAsBytes();
      print('File size: ${bytes.length} bytes');

      final epub = await epubx.EpubReader.readBook(bytes);
      print('EPUB loaded successfully');
      print('Title: ${epub.Title}');
      print('Author: ${epub.Author}');
      print('Chapters count: ${epub.Chapters?.length ?? 0}');

      _chapters.clear();
      final allChapterTexts = <String>[];

      // 載入章節內容
      bool contentLoaded = false;

      if (epub.Chapters != null && epub.Chapters!.isNotEmpty) {
        for (int i = 0; i < epub.Chapters!.length; i++) {
          final chapter = epub.Chapters![i];
          if (chapter.HtmlContent != null && chapter.HtmlContent!.isNotEmpty) {
            final text = extractTextFromHtml(chapter.HtmlContent!);

            if (text.trim().isNotEmpty && text.trim().length > 20) {
              _chapters.add(chapter);
              allChapterTexts.add(text);
              contentLoaded = true;
              print('Added chapter $i with ${text.length} characters');
            } else {
              print(
                  'Chapter $i text too short or empty after extraction (length: ${text.trim().length})');
            }
          } else {
            print('Chapter $i has no HTML content');
          }
        }

        if (contentLoaded) {
          _originalText = allChapterTexts.join('\n\n\n'); // 章節間用三個換行分隔
          print(
              '✅ Method 1 successful: Loaded ${_chapters.length} chapters with ${_originalText.length} total characters');
          return LoadResult.success(_chapters, _originalText);
        }
      }

      // 如果章節載入失敗，嘗試其他方法
      print('❌ Method 1 failed, trying Method 2: Reading from HTML files');

      // Method 2: 從HTML文件讀取
      if (epub.Content?.Html != null) {
        for (final htmlFile in epub.Content!.Html!.values) {
          if (htmlFile.Content != null) {
            final htmlString = htmlFile.Content.toString();
            final text = extractTextFromHtml(htmlString);
            if (text.trim().isNotEmpty && text.trim().length > 50) {
              allChapterTexts.add(text);
              contentLoaded = true;
            }
          }
        }

        if (contentLoaded) {
          _originalText = allChapterTexts.join('\n\n\n');
          print(
              '✅ Method 2 successful: Loaded ${allChapterTexts.length} HTML sections');
          return LoadResult.success(_chapters, _originalText);
        }
      }

      return LoadResult.error('No readable content found in the EPUB file');
    } catch (e) {
      print('Error loading book: $e');
      return LoadResult.error('Failed to load book: $e');
    }
  }

  /// 從HTML中提取純文字內容
  String extractTextFromHtml(String html) {
    if (html.isEmpty) return '';

    String text = html;

    // 移除常見的HTML標籤
    final htmlTags = [
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true),
      RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true),
      RegExp(r'<[^>]+>'),
    ];

    for (final regex in htmlTags) {
      text = text.replaceAll(regex, ' ');
    }

    // 解碼HTML實體
    final entities = {
      '&nbsp;': ' ',
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&#39;': "'",
      '&apos;': "'",
      '&mdash;': '—',
      '&ndash;': '–',
      '&ldquo;': '"',
      '&rdquo;': '"',
      '&lsquo;': ''',
      '&rsquo;': ''',
      '&hellip;': '…',
    };

    entities.forEach((entity, replacement) {
      text = text.replaceAll(entity, replacement);
    });

    // 清理空白和格式
    text = text
        .replaceAll(RegExp(r'\s+'), ' ') // 合併多個空白
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n') // 保留段落分隔
        .trim();

    return text;
  }

  /// 清理資源
  void dispose() {
    _chapters.clear();
    _originalText = '';
  }
}

/// 載入結果類型
class LoadResult {
  final bool isSuccess;
  final String? errorMessage;
  final List<epubx.EpubChapter>? chapters;
  final String? content;

  LoadResult.success(this.chapters, this.content)
      : isSuccess = true,
        errorMessage = null;

  LoadResult.error(this.errorMessage)
      : isSuccess = false,
        chapters = null,
        content = null;
}
