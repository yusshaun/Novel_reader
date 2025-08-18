import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/epub_book.dart';
import '../services/epub_reader_controller.dart';
import '../widgets/epub_reader_toolbar.dart';

class EpubReaderScreenModular extends ConsumerStatefulWidget {
  final EpubBook book;

  const EpubReaderScreenModular({
    Key? key,
    required this.book,
  }) : super(key: key);

  @override
  ConsumerState<EpubReaderScreenModular> createState() =>
      _EpubReaderScreenModularState();
}

class _EpubReaderScreenModularState
    extends ConsumerState<EpubReaderScreenModular> {
  late EpubReaderController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = EpubReaderController(
      book: widget.book,
      ref: ref,
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );
    _controller.initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 初始化分頁（需要屏幕尺寸）
    if (!_isInitialized) {
      final screenSize = MediaQuery.of(context).size;
      _controller.initializePagination(screenSize);
      _isInitialized = true;
    }

    // 處理屏幕尺寸變化
    final currentSize = MediaQuery.of(context).size;
    _controller.handleScreenSizeChange(currentSize);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 主要內容區域
          Positioned.fill(
            bottom: 70, // 為工具欄留出空間
            child: _buildPageView(),
          ),

          // 固定工具欄
          EpubReaderToolbar(
            currentPage: _controller.currentPage,
            totalPages: _controller.pages.length,
            currentChapterIndex: _controller.currentChapterIndex,
            totalChapters: _controller.chapters.length,
            onPreviousPage: _controller.previousPage,
            onNextPage: _controller.nextPage,
            onShowChapterMenu: () => _controller.showChapterSelection(context),
            onShowPageJump: () => _controller.showPageJumpDialog(context),
            onBack: () => Navigator.of(context).pop(),
          ),

          // 進度指示器（右上角）
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: ReadingProgressIndicator(
              currentPage: _controller.currentPage,
              totalPages: _controller.pages.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    if (_controller.pages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return PageView.builder(
      controller: _controller.pageController,
      itemCount: _controller.pages.length,
      onPageChanged: (page) {
        // 由控制器處理頁面變化
        setState(() {}); // 觸發UI更新
      },
      itemBuilder: (context, index) {
        return _buildPage(_controller.pages[index]);
      },
    );
  }

  Widget _buildPage(String content) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: SingleChildScrollView(
        child: Text(
          content,
          style: const TextStyle(
            fontSize: 18,
            height: 1.6,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }
}
