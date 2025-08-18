import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/epub_book.dart';
import '../providers/reading_progress_provider.dart';

/// 負責閱讀進度的載入和保存
class ReadingProgressManager {
  final WidgetRef ref;

  ReadingProgressManager(this.ref);

  /// 載入初始閱讀進度
  int loadInitialProgress(EpubBook book) {
    print('Loading initial progress for bookId: ${book.id}');

    final progressMap = ref.read(readingProgressProvider);
    final progress = progressMap[book.id];

    print('Available progress records: ${progressMap.keys.toList()}');

    if (progress != null) {
      final lastReadPage = (progress.lastPage - 1).clamp(0, 999999);
      print('Set initial page: last read display page ${progress.lastPage}, same page index $lastReadPage');
      return lastReadPage;
    } else {
      print('No initial progress found for bookId: ${book.id}');
      return 0;
    }
  }

  /// 載入閱讀進度並跳轉到指定頁面
  Future<void> loadReadingProgress(
    EpubBook book,
    List<String> pages,
    Function(int) jumpToPage,
  ) async {
    print('Loading progress for bookId: ${book.id}');

    // 延遲執行避免在 widget 生命週期中修改 provider，並確保 PageController 準備好
    await Future.delayed(const Duration(milliseconds: 100));

    // 先刷新 provider 確保數據是最新的
    ref.read(readingProgressProvider.notifier).refresh();

    final progressMap = ref.read(readingProgressProvider);
    final progress = progressMap[book.id];

    if (progress != null && pages.isNotEmpty) {
      final lastPage = (progress.lastPage - 1).clamp(0, pages.length - 1);
      print('📖 Found saved progress: jumping to page ${lastPage + 1} (index $lastPage)');
      
      jumpToPage(lastPage);
      
      print('✅ Successfully restored reading progress to page ${lastPage + 1}');
    } else {
      print('No saved progress found for book: ${book.id}');
    }
  }

  /// 同步保存閱讀進度（用於 dispose 和應用狀態變化時）
  void saveProgressSync(EpubBook book, List<String> pages, int currentPage) {
    if (pages.isEmpty || currentPage < 0) {
      return;
    }

    try {
      // 使用同步方式保存進度，頁數 +1 與顯示一致
      ref.read(readingProgressProvider.notifier).updateProgressSync(
        bookId: book.id,
        page: currentPage + 1, // 顯示頁數 (1-based)
        totalPages: pages.length,
      );
      print('✅ Saved reading progress on exit: page ${currentPage + 1} of ${pages.length}');
    } catch (e) {
      print('❌ Error saving progress on exit: $e');
    }
  }

  /// 異步保存閱讀進度
  Future<void> saveProgress(EpubBook book, List<String> pages, int currentPage) async {
    if (pages.isEmpty || currentPage < 0) {
      return;
    }

    try {
      await ref.read(readingProgressProvider.notifier).updateProgress(
        bookId: book.id,
        page: currentPage + 1, // 顯示頁數 (1-based)
        totalPages: pages.length,
      );
      print('✅ Saved reading progress: page ${currentPage + 1} of ${pages.length}');
    } catch (e) {
      print('❌ Error saving progress: $e');
    }
  }

  /// 在頁面變化時自動保存進度
  void onPageChanged(EpubBook book, List<String> pages, int newPage) {
    print('Page changed to: ${newPage + 1}');
    
    // 使用 Future.microtask 避免在 build 過程中修改 provider
    Future.microtask(() => saveProgress(book, pages, newPage));
  }
}
