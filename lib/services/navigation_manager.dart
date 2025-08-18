import 'package:flutter/material.dart';
import 'package:epubx/epubx.dart' as epubx;

/// 負責頁面導航和章節跳轉功能
class NavigationManager {
  final PageController pageController;

  NavigationManager(this.pageController);

  /// 跳轉到下一頁
  void nextPage(int currentPage, int totalPages, Function(int) onPageChanged) {
    if (currentPage < totalPages - 1) {
      final newPage = currentPage + 1;
      pageController.animateToPage(
        newPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      onPageChanged(newPage);
    }
  }

  /// 跳轉到上一頁
  void previousPage(int currentPage, Function(int) onPageChanged) {
    if (currentPage > 0) {
      final newPage = currentPage - 1;
      pageController.animateToPage(
        newPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      onPageChanged(newPage);
    }
  }

  /// 跳轉到指定頁面
  void jumpToPage(int page, int totalPages, Function(int) onPageChanged) {
    final targetPage = page.clamp(0, totalPages - 1);
    pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    onPageChanged(targetPage);
  }

  /// 跳轉到指定章節
  void goToChapter(
    int chapterIndex,
    List<epubx.EpubChapter> chapters,
    Map<int, int> chapterPageMapping,
    Function(int) onPageChanged,
    Function(int) updateCurrentChapter,
  ) {
    if (chapterIndex >= 0 && chapterIndex < chapters.length) {
      final startPage = chapterPageMapping[chapterIndex] ?? 0;
      print('Jumping to chapter $chapterIndex at page $startPage');

      pageController.animateToPage(
        startPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      onPageChanged(startPage);
      updateCurrentChapter(chapterIndex);
    }
  }

  /// 更新當前章節索引
  int updateCurrentChapter(
    int currentPage,
    Map<int, int> chapterPageMapping,
  ) {
    int currentChapterIndex = 0;

    // 找到當前頁面所屬的章節
    for (final entry in chapterPageMapping.entries) {
      if (currentPage >= entry.value) {
        currentChapterIndex = entry.key;
      } else {
        break;
      }
    }

    return currentChapterIndex;
  }

  /// 處理頁面變化
  void onPageChanged(
    int page,
    Function(int) setCurrentPage,
    Function(int) updateChapter,
    Function(int, int) saveProgress,
  ) {
    print('Page changed to: ${page + 1}');
    setCurrentPage(page);

    // 更新當前章節
    final newChapterIndex = updateChapter(page);

    // 保存進度
    saveProgress(page, newChapterIndex);
  }

  /// 顯示章節選擇對話框
  Future<void> showChapterSelection(
    BuildContext context,
    List<epubx.EpubChapter> chapters,
    int currentChapterIndex,
    Function(int) onChapterSelected,
  ) async {
    if (chapters.isEmpty) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('選擇章節'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                final isCurrentChapter = index == currentChapterIndex;

                return ListTile(
                  title: Text(
                    chapter.Title ?? '章節 ${index + 1}',
                    style: TextStyle(
                      fontWeight: isCurrentChapter
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isCurrentChapter
                          ? Theme.of(context).primaryColor
                          : null,
                    ),
                  ),
                  leading: Icon(
                    isCurrentChapter
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isCurrentChapter
                        ? Theme.of(context).primaryColor
                        : null,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    onChapterSelected(index);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  /// 顯示跳轉頁面對話框
  Future<void> showPageJumpDialog(
    BuildContext context,
    int currentPage,
    int totalPages,
    Function(int) onPageSelected,
  ) async {
    final controller = TextEditingController(text: '${currentPage + 1}');

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('跳轉到頁面'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '頁面 (1-$totalPages)',
              hintText: '輸入頁碼',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final pageNumber = int.tryParse(controller.text);
                if (pageNumber != null &&
                    pageNumber >= 1 &&
                    pageNumber <= totalPages) {
                  Navigator.of(context).pop();
                  onPageSelected(pageNumber - 1); // 轉換為0-based索引
                }
              },
              child: const Text('跳轉'),
            ),
          ],
        );
      },
    );
  }
}
