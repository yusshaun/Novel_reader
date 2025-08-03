import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../lib/screens/epub_reader_screen.dart';
import '../lib/models/epub_book.dart';

void main() {
  group('EPUB Chapter Selection Tests', () {
    testWidgets('EPUB reader should have chapter selection button',
        (WidgetTester tester) async {
      // 創建測試用的 EPUB 書籍
      final testBook = EpubBook(
        id: 'test-book',
        title: '測試書籍',
        author: '測試作者',
        filePath: '/test/path/book.epub',
        lastRead: DateTime.now(),
      );

      // 構建 widget
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EpubReaderScreen(book: testBook),
          ),
        ),
      );

      // 等待初始化
      await tester.pumpAndSettle();

      // 檢查是否有章節選擇按鈕（list_alt 圖標）
      expect(find.byIcon(Icons.list_alt), findsOneWidget);

      // 檢查是否有設置按鈕
      expect(find.byIcon(Icons.settings), findsOneWidget);

      // 檢查應用欄標題
      expect(find.text('測試書籍'), findsOneWidget);
    });

    testWidgets('Bottom navigation should show page and chapter info',
        (WidgetTester tester) async {
      final testBook = EpubBook(
        id: 'test-book-2',
        title: '另一本測試書',
        author: '測試作者2',
        filePath: '/test/path/book2.epub',
        lastRead: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EpubReaderScreen(book: testBook),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 檢查底部導航欄是否存在
      expect(find.byType(BottomAppBar), findsOneWidget);

      // 檢查翻頁按鈕
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    test('Chapter mapping should work correctly', () {
      // 測試章節到頁面的映射邏輯
      final Map<int, int> chapterPageMapping = {};

      // 模擬添加章節
      chapterPageMapping[0] = 0; // 第一章從第0頁開始
      chapterPageMapping[1] = 10; // 第二章從第10頁開始
      chapterPageMapping[2] = 25; // 第三章從第25頁開始

      // 測試查找當前章節的邏輯
      int getCurrentChapter(int currentPage) {
        for (int i = chapterPageMapping.length - 1; i >= 0; i--) {
          final startPage = chapterPageMapping[i] ?? 0;
          if (currentPage >= startPage) {
            return i;
          }
        }
        return 0;
      }

      expect(getCurrentChapter(0), equals(0)); // 第0頁應該在第0章
      expect(getCurrentChapter(5), equals(0)); // 第5頁應該在第0章
      expect(getCurrentChapter(10), equals(1)); // 第10頁應該在第1章
      expect(getCurrentChapter(15), equals(1)); // 第15頁應該在第1章
      expect(getCurrentChapter(25), equals(2)); // 第25頁應該在第2章
      expect(getCurrentChapter(30), equals(2)); // 第30頁應該在第2章
    });
  });
}
