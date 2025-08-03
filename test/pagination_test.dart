import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  group('EPUB Reader Pagination Tests', () {
    test('Screen-based pagination calculation should work correctly', () {
      // 模擬螢幕尺寸
      const screenSize = Size(375, 812); // iPhone X 尺寸
      
      // 計算可用高度
      const appBarHeight = 56.0;
      const bottomNavHeight = 56.0;
      const verticalPadding = 32.0;
      const pageInfoHeight = 50.0;
      
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
      
      // 估算每行平均字符數
      const horizontalPadding = 32.0;
      final availableWidth = screenSize.width - horizontalPadding;
      final avgCharWidth = fontSize * 0.6;
      final charsPerLine = (availableWidth / avgCharWidth).floor();
      
      // 計算每頁字符數
      final charsPerPage = (linesPerPage * charsPerLine * 0.8).floor();
      
      expect(linesPerPage, greaterThan(0));
      expect(charsPerLine, greaterThan(0));
      expect(charsPerPage, greaterThan(0));
      expect(charsPerPage, lessThan(3000)); // 合理的上限
      
      print('Screen: ${screenSize.width}x${screenSize.height}');
      print('Available height: $availableHeight');
      print('Lines per page: $linesPerPage');
      print('Chars per line: $charsPerLine');
      print('Chars per page: $charsPerPage');
    });

    test('Text pagination should split correctly', () {
      // 測試文本分頁邏輯
      final testText = '''這是第一段文字。這段文字包含了一些測試內容，用來驗證分頁功能是否正常工作。

這是第二段文字。第二段也包含一些內容，確保段落分割正確。

這是第三段文字。最後一段用來測試完整的分頁流程。''';

      final pages = _paginateTextByCharacterCount(testText, 100); // 使用較小的頁面大小進行測試
      
      expect(pages.length, greaterThan(1)); // 應該分成多頁
      expect(pages.every((page) => page.length <= 120), isTrue); // 每頁不應該超過限制太多（考慮段落完整性）
      expect(pages.join('\n\n').replaceAll(RegExp(r'\n+'), '\n'), 
             contains('這是第一段文字')); // 確保內容完整性
    });

    test('Screen size change should trigger re-pagination', () {
      // 測試螢幕尺寸變化時的重新分頁
      const size1 = Size(375, 812);
      const size2 = Size(812, 375); // 橫屏
      
      expect(size1, isNot(equals(size2)));
      
      // 計算不同螢幕尺寸下的字符數
      final chars1 = _calculateCharsPerPage(size1);
      final chars2 = _calculateCharsPerPage(size2);
      
      expect(chars1, isNot(equals(chars2))); // 不同螢幕尺寸應該有不同的分頁設定
    });
  });
}

// 輔助函數：模擬字符數分頁
List<String> _paginateTextByCharacterCount(String text, int charactersPerPage) {
  if (text.isEmpty) return [''];

  final pages = <String>[];
  final paragraphs = text.split(RegExp(r'\n{2,}'));
  final buffer = StringBuffer();
  int currentLength = 0;

  for (final para in paragraphs) {
    final paraTrimmed = para.trim();
    if (paraTrimmed.isEmpty) continue;

    if (currentLength + paraTrimmed.length > charactersPerPage &&
        buffer.isNotEmpty) {
      pages.add(buffer.toString().trim());
      buffer.clear();
      currentLength = 0;
    }

    if (buffer.isNotEmpty) {
      buffer.write('\n\n');
      currentLength += 2;
    }

    buffer.write(paraTrimmed);
    currentLength += paraTrimmed.length;
  }

  if (buffer.isNotEmpty) {
    pages.add(buffer.toString().trim());
  }

  return pages.isEmpty ? [''] : pages;
}

// 輔助函數：計算螢幕尺寸對應的每頁字符數
int _calculateCharsPerPage(Size screenSize) {
  const appBarHeight = 56.0;
  const bottomNavHeight = 56.0;
  const verticalPadding = 32.0;
  const pageInfoHeight = 50.0;
  
  final availableHeight = screenSize.height - 
                         appBarHeight - 
                         bottomNavHeight - 
                         verticalPadding - 
                         pageInfoHeight;
  
  const fontSize = 16.0;
  const lineHeight = 1.5;
  const actualLineHeight = fontSize * lineHeight;
  
  final linesPerPage = (availableHeight / actualLineHeight).floor();
  
  const horizontalPadding = 32.0;
  final availableWidth = screenSize.width - horizontalPadding;
  final avgCharWidth = fontSize * 0.6;
  final charsPerLine = (availableWidth / avgCharWidth).floor();
  
  return (linesPerPage * charsPerLine * 0.8).floor();
}
