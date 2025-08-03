import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epubx/epubx.dart' as epubx;
import 'dart:io';
import '../models/epub_book.dart';
import '../providers/reading_progress_provider.dart';

class EpubReaderScreen extends ConsumerStatefulWidget {
  final EpubBook book;

  const EpubReaderScreen({
    Key? key,
    required this.book,
  }) : super(key: key);

  @override
  ConsumerState<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends ConsumerState<EpubReaderScreen>
    with WidgetsBindingObserver {
  int _currentPage = 0;
  final List<String> _pages = ['Loading...'];
  List<epubx.EpubChapter> _chapters = [];
  Map<int, int> _chapterPageMapping = {}; // 章節到頁面的映射
  int _currentChapterIndex = 0;
  Size? _lastScreenSize; // 記錄上次的螢幕尺寸
  String _originalText = ''; // 保存原始文本用於重新分頁
  late PageController _pageController; // PageView 控制器

  @override
  void initState() {
    super.initState();
    // 註冊應用狀態監聽器
    WidgetsBinding.instance.addObserver(this);
    // 先載入閱讀進度來獲取正確的起始頁面
    _loadInitialProgress();
    _pageController = PageController(initialPage: _currentPage);
    _loadBook();
  }

  // 載入初始閱讀進度（僅設置初始頁面，真正跳轉在書本載入後）
  void _loadInitialProgress() {
    print('Loading initial progress for bookId: ${widget.book.id}');

    // 延遲讀取避免在 widget 生命週期中修改 provider
    Future(() {
      final progressMap = ref.read(readingProgressProvider);
      final progress = progressMap[widget.book.id];

      print('Available progress records: ${progressMap.keys.toList()}');

      if (progress != null && mounted) {
        // 設置初始頁面為上次閱讀的頁面，實際跳轉會在 _loadReadingProgress 中發生
        final lastReadPage = (progress.lastPage - 1).clamp(0, 999999);
        if (mounted) {
          setState(() {
            _currentPage = lastReadPage;
          });
        }
        print(
            'Set initial page: last read display page ${progress.lastPage}, same page index $_currentPage');
      } else {
        print('No initial progress found for bookId: ${widget.book.id}');
      }
    });
  }

  @override
  void dispose() {
    // 移除應用狀態監聽器
    WidgetsBinding.instance.removeObserver(this);
    // 在銷毀前最後一次保存進度（但要檢查 mounted 狀態）
    if (mounted) {
      _saveReadingProgressSync();
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 當應用進入後台或非活躍狀態時保存進度
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _saveReadingProgressSync();
    }
  }

  // 同步保存進度（用於 dispose 和應用狀態變化時）
  void _saveReadingProgressSync() {
    if (_pages.isEmpty || _currentPage < 0 || !mounted) {
      return;
    }

    try {
      // 保存顯示頁面（從1開始），與用戶看到的一致
      ref.read(readingProgressProvider.notifier).updateProgressSync(
            bookId: widget.book.id,
            page: _currentPage + 1, // 保存顯示頁面
            totalPages: _pages.length,
            chapterId: _currentChapterIndex.toString(),
            chapterTitle:
                _chapters.isNotEmpty && _currentChapterIndex < _chapters.length
                    ? _chapters[_currentChapterIndex].Title
                    : null,
          );
      print(
          '✅ Saved reading progress on exit: page ${_currentPage + 1} of ${_pages.length}');
    } catch (e) {
      print('❌ Failed to save reading progress on exit: $e');
    }
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

      // 重新初始化 PageController 以確保正確的頁面狀態
      _pageController.dispose();
      _pageController = PageController(initialPage: _currentPage);
    });

    print('Re-paginated: ${_pages.length} pages, current page: $_currentPage');
  }

  // 載入閱讀進度
  void _loadReadingProgress() {
    print('Loading progress for bookId: ${widget.book.id}');

    // 延遲執行避免在 widget 生命週期中修改 provider，並確保 PageController 準備好
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      // 先刷新 provider 確保數據是最新的
      ref.read(readingProgressProvider.notifier).refresh();

      final progressMap = ref.read(readingProgressProvider);
      final progress = progressMap[widget.book.id];

      if (progress != null && _pages.isNotEmpty && mounted) {
        // progress.lastPage 是保存的顯示頁面（從1開始）
        // 載入到上次閱讀的確切頁面
        final lastReadPage = progress.lastPage - 1; // 轉換為索引（從0開始）
        final targetPage = lastReadPage.clamp(0, _pages.length - 1);

        print(
            '📖 Progress found: last display page ${progress.lastPage}, loading same page ${targetPage + 1} (index: $targetPage)');
        print('📖 Current page before jump: $_currentPage');

        // 更新當前頁面並跳轉（即使頁面相同也要跳轉以確保 UI 更新）
        setState(() {
          _currentPage = targetPage;
        });

        // 確保 PageController 準備好後再跳轉
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients && mounted) {
            print('📖 Jumping to page: $targetPage');
            _pageController.animateToPage(
              _currentPage,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          } else {
            print('❌ PageController not ready for jump');
          }
        });

        _updateCurrentChapter();

        print(
            '✅ Loaded reading progress: last read display page ${progress.lastPage}, continuing from same page ${_currentPage + 1} (index: $_currentPage)');
      } else {
        print(
            '❌ No progress found for bookId: ${widget.book.id}, available keys: ${progressMap.keys.toList()}');
        print('❌ Pages available: ${_pages.length}, mounted: $mounted');
      }
    });
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
        print('📊 Page distribution:');
        if (_pages.isNotEmpty) {
          final firstPagePreview = _pages[0].length > 50
              ? _pages[0].substring(0, 50).replaceAll('\n', ' ')
              : _pages[0].replaceAll('\n', ' ');
          print('  - First page preview: $firstPagePreview...');
        }
        if (_pages.length > 1) {
          final lastPage = _pages[_pages.length - 1];
          final lastPagePreview = lastPage.length > 50
              ? lastPage.substring(0, 50).replaceAll('\n', ' ')
              : lastPage.replaceAll('\n', ' ');
          print('  - Last page preview: $lastPagePreview...');
          print('  - Last page length: ${lastPage.length} characters');
        }
        print('  - Total accessible pages: 0 to ${_pages.length - 1}');

        // 載入並恢復閱讀進度
        _loadReadingProgress();
      });
    } catch (e) {
      print('Error loading book: $e');
      setState(() {
        _pages.clear();
        _pages.add('載入書籍時發生錯誤: $e\n\n檔案: ${widget.book.filePath}');

        // 重新初始化 PageController
        _pageController.dispose();
        _pageController = PageController(initialPage: 0);
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
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      _updateCurrentChapter();
    });

    // 特殊檢查：是否到達最後一頁
    if (page == _pages.length - 1) {
      print('🏁 Reached last page: $page (total: ${_pages.length})');
    }

    // 不在每次翻頁時保存進度，只在退出時保存
    // _saveReadingProgress(); // 已移除
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

      // 使用 PageController 跳轉到指定頁面
      _pageController.animateToPage(
        startPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      // 移除干擾性的 SnackBar 通知
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            // 返回按鈕
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // 在返回前保存進度
                    _saveReadingProgressSync();
                    Navigator.of(context).pop(); // 先關閉 Drawer
                    Navigator.of(context).pop(); // 再返回到上一個頁面
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('返回書架'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const Divider(),
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
            // 頁面導航控制
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.first_page),
                    onPressed: _currentPage > 0
                        ? () {
                            _pageController.animateToPage(
                              0,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
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
                            _pageController.animateToPage(
                              _pages.length - 1,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
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
      body: Stack(
        children: [
          // EPUB 閱讀內容
          Listener(
            onPointerSignal: (pointerSignal) {
              if (pointerSignal is PointerScrollEvent) {
                // 向下滾動 (scrollDelta.dy > 0) = 下一頁
                // 向上滾動 (scrollDelta.dy < 0) = 上一頁
                if (pointerSignal.scrollDelta.dy > 0) {
                  _nextPage();
                } else if (pointerSignal.scrollDelta.dy < 0) {
                  _previousPage();
                }
              }
            },
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                // 確保索引在有效範圍內
                if (index >= _pages.length) {
                  print('⚠️ Invalid page index: $index >= ${_pages.length}');
                  return Container(
                    padding: const EdgeInsets.all(16.0),
                    child: const Center(
                      child: Text(
                        '頁面索引錯誤',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  );
                }

                // 顯示調試資訊（僅在最後幾頁）
                if (index >= _pages.length - 3) {
                  print(
                      '📖 Rendering page $index of ${_pages.length - 1} (total: ${_pages.length})');
                }

                return GestureDetector(
                  onTapUp: (details) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    if (details.globalPosition.dx < screenWidth / 3) {
                      _previousPage();
                    } else if (details.globalPosition.dx >
                        screenWidth * 2 / 3) {
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 在最後一頁顯示額外資訊
                                if (index == _pages.length - 1)
                                  Container(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text(
                                      '--- 最後一頁 (${index + 1}/${_pages.length}) ---',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    index < _pages.length
                                        ? _pages[index]
                                        : 'Loading...',
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // 底部完整導航控制區域
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // 章節選單按鈕
                              Builder(
                                builder: (context) => InkWell(
                                  onTap: () {
                                    Scaffold.of(context).openDrawer();
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.list,
                                      color: Colors.grey[600],
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                              // 第一頁
                              InkWell(
                                onTap: _currentPage > 0
                                    ? () {
                                        _pageController.animateToPage(
                                          0,
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.first_page,
                                    color: _currentPage > 0
                                        ? Colors.grey[600]
                                        : Colors.grey[400],
                                    size: 16,
                                  ),
                                ),
                              ),
                              // 上一頁
                              InkWell(
                                onTap: _currentPage > 0 ? _previousPage : null,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.chevron_left,
                                    color: _currentPage > 0
                                        ? Colors.grey[600]
                                        : Colors.grey[400],
                                    size: 16,
                                  ),
                                ),
                              ),
                              // 頁碼顯示
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${index + 1}/${_pages.length}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              // 下一頁
                              InkWell(
                                onTap: _currentPage < _pages.length - 1
                                    ? _nextPage
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.chevron_right,
                                    color: _currentPage < _pages.length - 1
                                        ? Colors.grey[600]
                                        : Colors.grey[400],
                                    size: 16,
                                  ),
                                ),
                              ),
                              // 最後一頁
                              InkWell(
                                onTap: _currentPage < _pages.length - 1
                                    ? () {
                                        _pageController.animateToPage(
                                          _pages.length - 1,
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.last_page,
                                    color: _currentPage < _pages.length - 1
                                        ? Colors.grey[600]
                                        : Colors.grey[400],
                                    size: 16,
                                  ),
                                ),
                              ),
                              // 返回按鈕
                              InkWell(
                                onTap: () {
                                  // 在返回前保存進度
                                  _saveReadingProgressSync();
                                  Navigator.of(context).pop();
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: Colors.grey[600],
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
