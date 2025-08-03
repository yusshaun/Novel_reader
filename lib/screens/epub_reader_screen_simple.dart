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
  List<epubx.EpubChapter> _chapters = [];
  Map<int, int> _chapterPageMapping = {}; // 章節到頁面的映射
  int _currentChapterIndex = 0;
  Size? _lastScreenSize; // 記錄上次的螢幕尺寸
  String _originalText = ''; // 保存原始文本用於重新分頁

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 檢查螢幕尺寸是否改變
    final currentSize = MediaQuery.of(context).size;
    if (_lastScreenSize != null &&
        _lastScreenSize != currentSize &&
        _originalText.isNotEmpty) {
      print('Screen size changed, re-paginating...');
      _repaginateContent();
    }
    _lastScreenSize = currentSize;
  }

  void _repaginateContent() {
    if (_originalText.isEmpty) return;

    final currentPageRatio =
        _pages.isNotEmpty ? _currentPage / _pages.length : 0.0;

    setState(() {
      _pages.clear();
      _chapterPageMapping.clear();

      // 重新分頁
      final newPages = _paginateText(_originalText);
      _pages.addAll(newPages);

      // 嘗試保持相對位置
      _currentPage = (newPages.length * currentPageRatio)
          .round()
          .clamp(0, newPages.length - 1);

      // 重新計算章節映射（簡化版本）
      if (_chapters.isNotEmpty) {
        _chapterPageMapping[0] = 0;
        _updateCurrentChapter();
      }
    });

    print('Re-paginated: ${_pages.length} pages, current page: $_currentPage');
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
        _chapters.clear();
        _chapterPageMapping.clear();

        // Method 1: Try chapters first (most reliable)
        bool contentLoaded = false;
        if (epub.Chapters != null && epub.Chapters!.isNotEmpty) {
          print('Loading from Chapters');
          _chapters = epub.Chapters!;

          for (int i = 0; i < epub.Chapters!.length; i++) {
            final chapter = epub.Chapters![i];
            print(
                'Chapter $i: "${chapter.Title}" - Content length: ${chapter.HtmlContent?.length ?? 0}');

            // 記錄這個章節開始的頁面位置
            _chapterPageMapping[i] = _pages.length;

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

    // 如果有 context，嘗試基於螢幕尺寸計算
    if (mounted && context.mounted) {
      return _paginateTextByScreenSize(text);
    }

    // 備用方案：基於字符數
    return _paginateTextByCharacterCount(text, charactersPerPage);
  }

  List<String> _paginateTextByScreenSize(String text) {
    final screenSize = MediaQuery.of(context).size;

    // 考慮 AppBar、底部導航欄和 padding 的高度
    const appBarHeight = 56.0;
    const bottomNavHeight = 56.0;
    const verticalPadding = 32.0; // 上下各16
    const pageInfoHeight = 50.0; // 頁面信息區域

    final availableHeight = screenSize.height -
        appBarHeight -
        bottomNavHeight -
        verticalPadding -
        pageInfoHeight;

    // 字體設定
    const fontSize = 16.0;
    const lineHeight = 1.5;
    const actualLineHeight = fontSize * lineHeight;

    // 計算每頁可顯示的行數
    final linesPerPage = (availableHeight / actualLineHeight).floor();

    // 估算每行平均字符數（基於螢幕寬度）
    const horizontalPadding = 32.0; // 左右各16
    final availableWidth = screenSize.width - horizontalPadding;
    final avgCharWidth = fontSize * 0.6; // 估算中文字符寬度
    final charsPerLine = (availableWidth / avgCharWidth).floor();

    // 計算每頁字符數
    final charsPerPage =
        (linesPerPage * charsPerLine * 0.8).floor(); // 0.8是安全係數

    print(
        'Screen-based pagination: ${linesPerPage} lines/page, ${charsPerLine} chars/line, ${charsPerPage} chars/page');

    return _paginateTextByCharacterCount(text, charsPerPage);
  }

  List<String> _paginateTextByCharacterCount(
      String text, int charactersPerPage) {
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
        _updateCurrentChapter();
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
        _updateCurrentChapter();
      });
    }
  }

  void _updateCurrentChapter() {
    // 根據當前頁面找到對應的章節
    for (int i = _chapters.length - 1; i >= 0; i--) {
      final startPage = _chapterPageMapping[i] ?? 0;
      if (_currentPage >= startPage) {
        _currentChapterIndex = i;
        break;
      }
    }
  }

  void _goToChapter(int chapterIndex) {
    if (chapterIndex >= 0 && chapterIndex < _chapters.length) {
      final startPage = _chapterPageMapping[chapterIndex] ?? 0;
      setState(() {
        _currentPage = startPage;
        _currentChapterIndex = chapterIndex;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '跳轉到：${_chapters[chapterIndex].Title ?? "第 ${chapterIndex + 1} 章"}'),
          duration: const Duration(seconds: 2),
        ),
      );
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
            tooltip: '設置',
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.book,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.book.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.book.author.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.book.author,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // 閱讀進度
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '閱讀進度',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _pages.isNotEmpty
                        ? (_currentPage + 1) / _pages.length
                        : 0,
                    backgroundColor: Colors.grey[300],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Page ${_currentPage + 1} of ${_pages.length}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        '${((_currentPage + 1) / _pages.length * 100).toInt()}%',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            // 章節目錄
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Icon(Icons.list_alt, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '章節目錄',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _chapters.isEmpty
                        ? const Center(
                            child: Text(
                              '沒有章節資訊',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _chapters.length,
                            itemBuilder: (context, index) {
                              final chapter = _chapters[index];
                              final isCurrentChapter =
                                  index == _currentChapterIndex;

                              return ListTile(
                                dense: true,
                                leading: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isCurrentChapter
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isCurrentChapter
                                            ? Colors.white
                                            : Colors.black54,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  chapter.Title ?? '第 ${index + 1} 章',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isCurrentChapter
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isCurrentChapter
                                        ? Theme.of(context).primaryColor
                                        : null,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                selected: isCurrentChapter,
                                onTap: () {
                                  _goToChapter(index);
                                  Navigator.pop(context); // 關閉 drawer
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // 導航控制
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.first_page),
                    onPressed: _currentPage > 0
                        ? () {
                            setState(() {
                              _currentPage = 0;
                            });
                            _updateCurrentChapter();
                            Navigator.pop(context);
                          }
                        : null,
                    tooltip: '第一頁',
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _currentPage > 0
                        ? () {
                            _previousPage();
                            Navigator.pop(context);
                          }
                        : null,
                    tooltip: '上一頁',
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _currentPage < _pages.length - 1
                        ? () {
                            _nextPage();
                            Navigator.pop(context);
                          }
                        : null,
                    tooltip: '下一頁',
                  ),
                  IconButton(
                    icon: const Icon(Icons.last_page),
                    onPressed: _currentPage < _pages.length - 1
                        ? () {
                            setState(() {
                              _currentPage = _pages.length - 1;
                            });
                            _updateCurrentChapter();
                            Navigator.pop(context);
                          }
                        : null,
                    tooltip: '最後一頁',
                  ),
                ],
              ),
            ),
          ],
        ),
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
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.topLeft,
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
    );
  }
}
