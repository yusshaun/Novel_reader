import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epubx/epubx.dart' as epubx;
import 'dart:io';
import '../models/epub_book.dart';

class EpubReaderScreen extends ConsumerStatefulWidget {
  final EpubBook book;

  const EpubReaderScreen({
    Key? key,
    required this.book,
  }) : super(key: key);

  @override
  ConsumerState<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends ConsumerState<EpubReaderScreen> {
  int _currentPage = 0;
  final List<String> _pages = ['Loading...'];

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    try {
      print('Loading book from: ${widget.book.filePath}');
      final file = File(widget.book.filePath);
      if (!await file.exists()) {
        setState(() {
          _pages.clear();
          _pages.add('Error: Book file not found at ${widget.book.filePath}');
        });
        return;
      }

      final bytes = await file.readAsBytes();
      print('File size: ${bytes.length} bytes');
      final epub = await epubx.EpubReader.readBook(bytes);
      print('EPUB loaded successfully');
      print('Title: ${epub.Title}');
      print('Author: ${epub.Author}');
      print('Chapters count: ${epub.Chapters?.length ?? 0}');

      setState(() {
        _pages.clear();

        // Method 1: Try chapters first (most reliable)
        bool contentLoaded = false;
        if (epub.Chapters != null && epub.Chapters!.isNotEmpty) {
          print('Loading from Chapters');
          for (int i = 0; i < epub.Chapters!.length; i++) {
            final chapter = epub.Chapters![i];
            print(
                'Chapter $i: "${chapter.Title}" - Content length: ${chapter.HtmlContent?.length ?? 0}');

            if (chapter.HtmlContent != null &&
                chapter.HtmlContent!.isNotEmpty) {
              // Show a preview of the HTML content
              final htmlPreview = chapter.HtmlContent!.length > 200
                  ? chapter.HtmlContent!.substring(0, 200) + '...'
                  : chapter.HtmlContent!;
              print('HTML Preview: $htmlPreview');

              final text = _extractTextFromHtml(chapter.HtmlContent!);
              final textPreview =
                  text.length > 100 ? text.substring(0, 100) + '...' : text;
              print('Extracted text preview: "$textPreview"');
              print('Extracted text length: ${text.length}');

              if (text.trim().isNotEmpty && text.trim().length > 20) {
                // Lower threshold for testing
                final pages = _paginateText(text);
                _pages.addAll(pages);
                contentLoaded = true;
                print('Added ${pages.length} pages from chapter $i');
              } else {
                print(
                    'Chapter $i text too short or empty after extraction (length: ${text.trim().length})');
              }
            } else {
              print('Chapter $i has no HTML content');
            }
          }
        }

        // Method 2: If chapters method failed, show detailed debug info
        if (!contentLoaded) {
          print('Chapters method failed, showing comprehensive debug info');

          final debugLines = <String>[
            '無法讀取 EPUB 內容',
            '',
            '調試信息：',
            '- 標題: ${epub.Title ?? "未知"}',
            '- 作者: ${epub.Author ?? "未知"}',
            '- 章節數量: ${epub.Chapters?.length ?? 0}',
            '- 檔案路徑: ${widget.book.filePath}',
            '',
            '章節詳細信息：'
          ];

          if (epub.Chapters != null && epub.Chapters!.isNotEmpty) {
            for (int i = 0; i < epub.Chapters!.length; i++) {
              final chapter = epub.Chapters![i];
              debugLines.add('章節 $i: "${chapter.Title ?? "無標題"}"');
              debugLines
                  .add('  - HTML內容長度: ${chapter.HtmlContent?.length ?? 0}');
              if (chapter.HtmlContent != null &&
                  chapter.HtmlContent!.isNotEmpty) {
                final preview = chapter.HtmlContent!.length > 100
                    ? chapter.HtmlContent!.substring(0, 100) + '...'
                    : chapter.HtmlContent!;
                debugLines.add('  - 內容預覽: $preview');
              }
            }
          } else {
            debugLines.add('沒有找到章節信息');
          }

          debugLines.addAll([
            '',
            '可能的問題：',
            '1. EPUB檔案結構不標準',
            '2. 內容被DRM保護',
            '3. HTML內容為空或格式異常',
            '4. 編碼問題',
            '',
            '建議：',
            '- 確認檔案是有效的EPUB格式',
            '- 嘗試其他EPUB檔案進行測試',
            '- 檢查檔案是否有DRM保護',
            '',
            '範例內容（供測試）：',
            '━━━━━━━━━━━━━━━━━━━━',
            '',
            '第一章',
            '',
            '這是《${widget.book.title}》的範例內容。',
            '',
            '作者：${widget.book.author}',
            '',
            '這本書的內容無法正常讀取，可能是由於檔案格式或保護機制的問題。',
            '',
            '如果您看到此訊息，表示EPUB解析器無法提取真實內容。',
            '',
            '請嘗試以下解決方案：',
            '1. 確認檔案完整性',
            '2. 使用其他EPUB檔案測試',
            '3. 檢查檔案權限',
            '',
            '━━━━━━━━━━━━━━━━━━━━'
          ]);

          _pages.add(debugLines.join('\n'));
        }

        print('Total pages loaded: ${_pages.length}');
      });
    } catch (e) {
      print('Error loading book: $e');
      setState(() {
        _pages.clear();
        _pages.add('載入書籍時發生錯誤: $e\n\n檔案: ${widget.book.filePath}');
      });
    }
  }

  String _extractTextFromHtml(String html) {
    if (html.isEmpty) return '';

    // More comprehensive HTML processing
    String text = html;

    // Remove DOCTYPE and XML declarations
    text =
        text.replaceAll(RegExp(r'<!DOCTYPE[^>]*>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<\?xml[^>]*\?>', caseSensitive: false), '');

    // Remove script and style tags with their content
    text = text.replaceAll(
        RegExp(r'<script[^>]*>.*?</script>',
            caseSensitive: false, dotAll: true),
        '');
    text = text.replaceAll(
        RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true),
        '');

    // Remove HTML comments
    text = text.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

    // Convert common HTML entities
    final entities = {
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&apos;': "'",
      '&nbsp;': ' ',
      '&copy;': '©',
      '&reg;': '®',
      '&trade;': '™',
      '&mdash;': '—',
      '&ndash;': '–',
      '&hellip;': '…',
      '&lsquo;': ''',
      '&rsquo;': ''',
      '&ldquo;': '"',
      '&rdquo;': '"',
    };

    entities.forEach((entity, replacement) {
      text = text.replaceAll(entity, replacement);
    });

    // Convert paragraph tags to line breaks
    text = text.replaceAll(RegExp(r'</?p[^>]*>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'<br[^>]*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</?div[^>]*>', caseSensitive: false), '\n');

    // Convert heading tags to text with extra spacing
    text =
        text.replaceAll(RegExp(r'<h[1-6][^>]*>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n\n');

    // Remove all remaining HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

    // Handle numeric HTML entities (&#123; or &#xAB;)
    text = text.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
      try {
        final code = int.parse(match.group(1)!);
        return String.fromCharCode(code);
      } catch (e) {
        return match.group(0) ?? '';
      }
    });

    text = text.replaceAllMapped(RegExp(r'&#x([0-9A-Fa-f]+);'), (match) {
      try {
        final code = int.parse(match.group(1)!, radix: 16);
        return String.fromCharCode(code);
      } catch (e) {
        return match.group(0) ?? '';
      }
    });

    // Normalize whitespace
    text = text.replaceAll(RegExp(r'\r\n'), '\n');
    text = text.replaceAll(RegExp(r'\r'), '\n');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');

    // Clean up leading/trailing whitespace on each line
    final lines = text.split('\n');
    final cleanLines = lines.map((line) => line.trim()).toList();

    // Remove empty lines at the beginning and end
    while (cleanLines.isNotEmpty && cleanLines.first.isEmpty) {
      cleanLines.removeAt(0);
    }
    while (cleanLines.isNotEmpty && cleanLines.last.isEmpty) {
      cleanLines.removeLast();
    }

    return cleanLines.join('\n').trim();
  }

  List<String> _paginateText(String text, {int charactersPerPage = 1800}) {
    if (text.isEmpty) return [''];

    final pages = <String>[];
    final paragraphs = text.split(RegExp(r'\n{2,}')); // 以兩個以上換行分段
    final buffer = StringBuffer();
    int currentLength = 0;

    for (final para in paragraphs) {
      final paraTrimmed = para.trim();
      if (paraTrimmed.isEmpty) continue;
      // 若加上這個段落會超過一頁，則先分頁
      if (currentLength + paraTrimmed.length > charactersPerPage &&
          buffer.isNotEmpty) {
        pages.add(buffer.toString().trim());
        buffer.clear();
        currentLength = 0;
      }
      if (buffer.isNotEmpty) buffer.write('\n\n');
      buffer.write(paraTrimmed);
      currentLength += paraTrimmed.length + 2; // 加上分段符號長度
    }
    if (buffer.isNotEmpty) {
      pages.add(buffer.toString().trim());
    }
    return pages.isEmpty ? [''] : pages;
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Settings placeholder
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 3) {
            _previousPage();
          } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
            _nextPage();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    _pages.isNotEmpty ? _pages[_currentPage] : 'Loading...',
                    style: const TextStyle(
                      fontSize: 16.0,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Page ${_currentPage + 1} of ${_pages.length}'),
                    Text(
                        '${((_currentPage + 1) / _pages.length * 100).toInt()}%'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _currentPage > 0 ? _previousPage : null,
            ),
            Text('${_currentPage + 1} / ${_pages.length}'),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: _currentPage < _pages.length - 1 ? _nextPage : null,
            ),
          ],
        ),
      ),
    );
  }
}
