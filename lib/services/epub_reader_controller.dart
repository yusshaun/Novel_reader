import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epubx/epubx.dart' as epubx;
import '../models/epub_book.dart';
import 'epub_content_manager.dart';
import 'pagination_manager.dart';
import 'reading_progress_manager.dart';
import 'navigation_manager.dart';

/// EPUB閱讀器的主控制器，協調各個管理器
class EpubReaderController with WidgetsBindingObserver {
  final EpubBook book;
  final WidgetRef ref;
  final VoidCallback onStateChanged;

  // 管理器實例
  late final EpubContentManager _contentManager;
  late final PaginationManager _paginationManager;
  late final ReadingProgressManager _progressManager;
  late final NavigationManager _navigationManager;

  // 狀態變量
  int _currentPage = 0;
  int _currentChapterIndex = 0;
  Size? _lastScreenSize;
  late PageController _pageController;

  // Getter 方法
  int get currentPage => _currentPage;
  int get currentChapterIndex => _currentChapterIndex;
  List<String> get pages => _paginationManager.pages;
  List<epubx.EpubChapter> get chapters => _contentManager.chapters;
  Map<int, int> get chapterPageMapping => _paginationManager.chapterPageMapping;
  PageController get pageController => _pageController;

  EpubReaderController({
    required this.book,
    required this.ref,
    required this.onStateChanged,
  }) {
    _contentManager = EpubContentManager();
    _paginationManager = PaginationManager();
    _progressManager = ReadingProgressManager(ref);

    // 初始化頁面控制器
    _currentPage = _progressManager.loadInitialProgress(book);
    _pageController = PageController(initialPage: _currentPage);
    _navigationManager = NavigationManager(_pageController);

    // 註冊應用狀態監聽器
    WidgetsBinding.instance.addObserver(this);
  }

  /// 初始化加載
  Future<void> initialize() async {
    // 載入書籍內容
    final loadResult = await _contentManager.loadBook(book);

    if (!loadResult.isSuccess) {
      // 載入失敗的處理
      _paginationManager.pages.clear();
      _paginationManager.pages.add(loadResult.errorMessage ?? 'Unknown error');
      onStateChanged();
      return;
    }

    // 初始分頁（需要屏幕尺寸）
    // 這個會在第一次 didChangeDependencies 時調用
    onStateChanged();
  }

  /// 初始化分頁（在獲取屏幕尺寸後調用）
  void initializePagination(Size screenSize) {
    if (_contentManager.chapters.isEmpty) return;

    _paginationManager.paginateChapters(
      _contentManager.chapters,
      screenSize,
      _contentManager.extractTextFromHtml,
    );

    // 更新當前章節
    _updateCurrentChapter();

    // 延遲加載閱讀進度
    Future.delayed(const Duration(milliseconds: 100), () {
      _progressManager.loadReadingProgress(
        book,
        _paginationManager.pages,
        _jumpToPage,
      );
    });

    onStateChanged();
  }

  /// 處理屏幕尺寸變化
  void handleScreenSizeChange(Size newSize) {
    if (_lastScreenSize != null &&
        _lastScreenSize != newSize &&
        _contentManager.originalText.isNotEmpty) {
      print('Screen size changed, re-paginating...');
      _repaginateContent(newSize);
    }
    _lastScreenSize = newSize;
  }

  /// 重新分頁內容
  void _repaginateContent(Size screenSize) {
    if (_contentManager.originalText.isEmpty) return;

    final repaginationResult = _paginationManager.repaginate(
      _contentManager.chapters,
      screenSize,
      _contentManager.extractTextFromHtml,
      _currentPage,
      _paginationManager.pages,
    );

    _currentPage = repaginationResult.newPage;
    _updateCurrentChapter();

    // 重新初始化 PageController
    _pageController.dispose();
    _pageController = PageController(initialPage: _currentPage);
    _navigationManager = NavigationManager(_pageController);

    print(
        'Re-paginated: ${_paginationManager.pages.length} pages, current page: $_currentPage');
    onStateChanged();
  }

  /// 頁面導航方法
  void nextPage() {
    _navigationManager.nextPage(
        _currentPage, _paginationManager.pages.length, _onPageChanged);
  }

  void previousPage() {
    _navigationManager.previousPage(_currentPage, _onPageChanged);
  }

  void jumpToPage(int page) {
    _navigationManager.jumpToPage(
        page, _paginationManager.pages.length, _onPageChanged);
  }

  void _jumpToPage(int page) {
    jumpToPage(page);
  }

  void goToChapter(int chapterIndex) {
    _navigationManager.goToChapter(
      chapterIndex,
      _contentManager.chapters,
      _paginationManager.chapterPageMapping,
      _onPageChanged,
      (index) => _currentChapterIndex = index,
    );
  }

  /// 頁面變化處理
  void _onPageChanged(int page) {
    _currentPage = page;
    _updateCurrentChapter();

    // 使用 Future.microtask 避免在 build 過程中修改 provider
    Future.microtask(() =>
        _progressManager.onPageChanged(book, _paginationManager.pages, page));

    onStateChanged();
  }

  /// 更新當前章節
  void _updateCurrentChapter() {
    _currentChapterIndex = _navigationManager.updateCurrentChapter(
      _currentPage,
      _paginationManager.chapterPageMapping,
    );
  }

  /// 顯示章節選擇對話框
  Future<void> showChapterSelection(BuildContext context) {
    return _navigationManager.showChapterSelection(
      context,
      _contentManager.chapters,
      _currentChapterIndex,
      goToChapter,
    );
  }

  /// 顯示頁面跳轉對話框
  Future<void> showPageJumpDialog(BuildContext context) {
    return _navigationManager.showPageJumpDialog(
      context,
      _currentPage,
      _paginationManager.pages.length,
      jumpToPage,
    );
  }

  /// 應用生命週期狀態變化
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _saveProgressSync();
    }
  }

  /// 同步保存進度
  void _saveProgressSync() {
    _progressManager.saveProgressSync(
        book, _paginationManager.pages, _currentPage);
  }

  /// 清理資源
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveProgressSync();
    _pageController.dispose();
    _contentManager.dispose();
    _paginationManager.dispose();
  }
}
