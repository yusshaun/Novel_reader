import 'package:flutter/material.dart';
import 'package:epubx/epubx.dart' as epubx;

/// 負責文字分頁的邏輯處理
class PaginationManager {
  static const double horizontalPadding = 24.0;
  static const double verticalPadding = 32.0;
  static const double bottomToolbarHeight = 60.0;
  static const double bottomSpacing = 70.0;
  static const double fontSize = 18.0;
  static const double lineHeight = 1.6;

  List<String> _pages = [];
  Map<int, int> _chapterPageMapping = {};

  List<String> get pages => _pages;
  Map<int, int> get chapterPageMapping => _chapterPageMapping;

  /// 將文字內容分頁
  List<String> paginateText(String text, Size screenSize) {
    if (text.isEmpty) return [''];

    // 計算可用的文字顯示區域
    final availableWidth = screenSize.width - (horizontalPadding * 2);
    final availableHeight = screenSize.height -
        (verticalPadding * 2) -
        bottomToolbarHeight -
        bottomSpacing;

    // 計算每頁可容納的文字
    final textStyle = TextStyle(fontSize: fontSize, height: lineHeight);
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: null,
    );

    // 估算每行字符數和每頁行數
    textPainter.text = TextSpan(text: '測', style: textStyle);
    textPainter.layout(maxWidth: availableWidth);
    final charWidth = textPainter.width;
    final lineHeightPixels = textPainter.height;

    final charsPerLine = (availableWidth / charWidth).floor();
    final maxLinesPerPage = (availableHeight / lineHeightPixels).floor();
    final maxCharsPerPage = charsPerLine * (maxLinesPerPage - 1); // 保留安全邊距

    if (maxCharsPerPage <= 0) return [text];

    final pages = <String>[];
    final lines = text.split('\n');
    String currentPage = '';
    int currentPageChars = 0;

    for (final line in lines) {
      final lineWithBreak = line + '\n';

      // 檢查添加這一行是否會超出頁面容量
      if (currentPageChars + lineWithBreak.length > maxCharsPerPage &&
          currentPage.isNotEmpty) {
        // 當前頁面已滿，開始新頁面
        pages.add(currentPage.trim());
        currentPage = lineWithBreak;
        currentPageChars = lineWithBreak.length;
      } else {
        // 添加到當前頁面
        currentPage += lineWithBreak;
        currentPageChars += lineWithBreak.length;
      }
    }

    // 添加最後一頁
    if (currentPage.trim().isNotEmpty) {
      pages.add(currentPage.trim());
    }

    return pages.isEmpty ? [''] : pages;
  }

  /// 為所有章節建立分頁並建立章節映射
  PaginationResult paginateChapters(List<epubx.EpubChapter> chapters,
      Size screenSize, String Function(String) textExtractor) {
    _pages.clear();
    _chapterPageMapping.clear();

    int currentPageIndex = 0;

    for (int i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];

      // 記錄章節開始的頁面位置
      _chapterPageMapping[i] = currentPageIndex;

      // 分頁章節內容
      final chapterText = textExtractor(chapter.HtmlContent ?? '');
      if (chapterText.trim().isNotEmpty) {
        final chapterPages = paginateText(chapterText, screenSize);
        _pages.addAll(chapterPages);
        currentPageIndex += chapterPages.length;
      }
    }

    print(
        'Pagination completed: ${_pages.length} pages, ${_chapterPageMapping.length} chapters');
    return PaginationResult(_pages, _chapterPageMapping);
  }

  /// 重新分頁並嘗試保持閱讀位置
  RepaginationResult repaginate(
    List<epubx.EpubChapter> chapters,
    Size screenSize,
    String Function(String) textExtractor,
    int currentPage,
    List<String> oldPages,
  ) {
    // 記錄當前閱讀位置的詳細信息
    String? currentPageContent;
    String? searchKeywords;
    int? currentCharacterOffset;

    if (oldPages.isNotEmpty && currentPage < oldPages.length) {
      currentPageContent = oldPages[currentPage];

      // 計算當前頁面在整個文本中的大概位置
      int totalCharsBeforeCurrentPage = 0;
      for (int i = 0; i < currentPage && i < oldPages.length; i++) {
        totalCharsBeforeCurrentPage += oldPages[i].length;
      }
      currentCharacterOffset = totalCharsBeforeCurrentPage;

      // 提取關鍵詞用於搜索（取中間部分，避免頁面邊界問題）
      if (currentPageContent.length > 100) {
        int startPos = currentPageContent.length ~/ 4;
        int endPos = startPos + 50;
        searchKeywords = currentPageContent.substring(startPos, endPos).trim();
      } else if (currentPageContent.length > 20) {
        searchKeywords = currentPageContent.substring(0, 20).trim();
      }

      print('Current page content length: ${currentPageContent.length}');
      print('Search keywords: $searchKeywords');
      print('Character offset: $currentCharacterOffset');
    }

    final currentPageRatio =
        oldPages.isNotEmpty ? currentPage / oldPages.length : 0.0;

    // 重新分頁
    final paginationResult =
        paginateChapters(chapters, screenSize, textExtractor);

    // 使用多種方法嘗試找到最佳的頁面位置
    int newPage = 0;
    bool foundMatch = false;

    // 方法1: 使用關鍵詞搜索
    if (searchKeywords != null && searchKeywords.isNotEmpty) {
      for (int i = 0; i < _pages.length; i++) {
        if (_pages[i].contains(searchKeywords)) {
          newPage = i;
          foundMatch = true;
          print('Found match using keywords at page: $i');
          break;
        }
      }
    }

    // 方法2: 如果關鍵詞搜索失敗，使用字符偏移量估算
    if (!foundMatch && currentCharacterOffset != null) {
      int estimatedOffset = 0;
      for (int i = 0; i < _pages.length; i++) {
        if (estimatedOffset >= currentCharacterOffset) {
          newPage = i;
          foundMatch = true;
          print('Found match using character offset at page: $i');
          break;
        }
        estimatedOffset += _pages[i].length;
      }
    }

    // 方法3: 如果前兩種方法都失敗，使用比例計算
    if (!foundMatch) {
      newPage = (_pages.length * currentPageRatio)
          .round()
          .clamp(0, _pages.length - 1);
      print('Using ratio-based page calculation: $newPage');
    }

    return RepaginationResult(paginationResult, newPage, foundMatch);
  }

  /// 清理資源
  void dispose() {
    _pages.clear();
    _chapterPageMapping.clear();
  }
}

/// 分頁結果
class PaginationResult {
  final List<String> pages;
  final Map<int, int> chapterPageMapping;

  PaginationResult(this.pages, this.chapterPageMapping);
}

/// 重新分頁結果
class RepaginationResult {
  final PaginationResult paginationResult;
  final int newPage;
  final bool foundMatch;

  RepaginationResult(this.paginationResult, this.newPage, this.foundMatch);
}
