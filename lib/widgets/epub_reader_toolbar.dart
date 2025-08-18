import 'package:flutter/material.dart';

/// EPUB閱讀器的工具欄組件
class EpubReaderToolbar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int currentChapterIndex;
  final int totalChapters;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final VoidCallback onShowChapterMenu;
  final VoidCallback onShowPageJump;
  final VoidCallback onBack;

  const EpubReaderToolbar({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.currentChapterIndex,
    required this.totalChapters,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onShowChapterMenu,
    required this.onShowPageJump,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 60,
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
        child: Row(
          children: [
            // 返回按鈕
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
            ),
            
            // 上一頁按鈕
            IconButton(
              icon: const Icon(Icons.navigate_before),
              onPressed: currentPage > 0 ? onPreviousPage : null,
            ),
            
            // 頁面信息（可點擊跳轉）
            Expanded(
              child: GestureDetector(
                onTap: onShowPageJump,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${currentPage + 1}/$totalPages',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (totalPages > 0)
                        LinearProgressIndicator(
                          value: totalPages > 0 ? (currentPage + 1) / totalPages : 0.0,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            
            // 章節選擇按鈕
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: totalChapters > 0 ? onShowChapterMenu : null,
              tooltip: '章節列表',
            ),
            
            // 下一頁按鈕
            IconButton(
              icon: const Icon(Icons.navigate_next),
              onPressed: currentPage < totalPages - 1 ? onNextPage : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// 簡單的進度顯示組件
class ReadingProgressIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const ReadingProgressIndicator({
    Key? key,
    required this.currentPage,
    required this.totalPages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 0) return const SizedBox.shrink();

    final percentage = ((currentPage + 1) / totalPages * 100).toInt();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$percentage%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
