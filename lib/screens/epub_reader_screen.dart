import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epubx/epubx.dart';
import 'dart:io';
import 'dart:convert';

import '../models/epub_book.dart';
import '../models/reading_progress.dart';
import '../providers/reader_theme_provider.dart';
import '../services/epub_service.dart';
import '../widgets/reader_app_bar.dart';
import '../widgets/reader_drawer.dart';
import '../widgets/reading_progress_indicator.dart';

class EpubReaderScreen extends ConsumerStatefulWidget {
  final EpubBook book;

  const EpubReaderScreen({
    super.key,
    required this.book,
  });

  @override
  ConsumerState<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends ConsumerState<EpubReaderScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _appBarAnimationController;
  
  EpubBookRef? _epubBook;
  List<EpubChapter>? _chapters;
  int _currentChapterIndex = 0;
  int _currentPageIndex = 0;
  List<String> _pages = [];
  bool _isLoading = true;
  bool _showAppBar = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _appBarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadEpubBook();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _appBarAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadEpubBook() async {
    try {
      final epubService = ref.read(epubServiceProvider);
      _epubBook = await epubService.openEpubForReading(widget.book.filePath);
      
      if (_epubBook == null) {
        throw Exception('Failed to open EPUB file');
      }

      _chapters = _epubBook!.Chapters;
      
      if (_chapters != null && _chapters!.isNotEmpty) {
        await _loadChapter(0);
      } else {
        throw Exception('No chapters found in EPUB file');
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadChapter(int chapterIndex) async {
    if (_chapters == null || chapterIndex >= _chapters!.length) return;

    try {
      final chapter = _chapters![chapterIndex];
      final htmlContent = chapter.HtmlContent ?? '';
      
      // Basic HTML to text conversion and pagination
      final textContent = _htmlToText(htmlContent);
      _pages = _paginateText(textContent);
      
      setState(() {
        _currentChapterIndex = chapterIndex;
        _currentPageIndex = 0;
      });
      
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      print('Error loading chapter: $e');
    }
  }

  String _htmlToText(String html) {
    // Basic HTML tag removal and text formatting
    String text = html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    // Decode HTML entities
    text = text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
    
    return text;
  }

  List<String> _paginateText(String text) {
    final theme = ref.read(readerThemeProvider);
    final words = text.split(' ');
    final pages = <String>[];
    
    // Estimate words per page based on font size and screen size
    const wordsPerPage = 250; // Rough estimation
    
    for (int i = 0; i < words.length; i += wordsPerPage) {
      final pageWords = words.skip(i).take(wordsPerPage).toList();
      pages.add(pageWords.join(' '));
    }
    
    return pages.isEmpty ? [''] : pages;
  }

  void _toggleAppBar() {
    setState(() {
      _showAppBar = !_showAppBar;
    });
    
    if (_showAppBar) {
      _appBarAnimationController.forward();
    } else {
      _appBarAnimationController.reverse();
    }
  }

  void _goToNextPage() {
    if (_currentPageIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_currentChapterIndex < (_chapters?.length ?? 0) - 1) {
      _loadChapter(_currentChapterIndex + 1);
    }
  }

  void _goToPreviousPage() {
    if (_currentPageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_currentChapterIndex > 0) {
      _loadChapter(_currentChapterIndex - 1);
    }
  }

  void _goToChapter(int chapterIndex) {
    if (chapterIndex >= 0 && chapterIndex < (_chapters?.length ?? 0)) {
      _loadChapter(chapterIndex);
      Navigator.pop(context); // Close drawer
    }
  }

  double _calculateProgress() {
    if (_chapters == null || _chapters!.isEmpty) return 0.0;
    
    final totalChapters = _chapters!.length;
    final chapterProgress = _currentChapterIndex / totalChapters;
    final pageProgress = _pages.isNotEmpty ? _currentPageIndex / _pages.length : 0.0;
    
    return (chapterProgress + (pageProgress / totalChapters)) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(readerThemeProvider);
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.book.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.book.title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading book: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.bgColor,
      appBar: _showAppBar
          ? ReaderAppBar(
              book: widget.book,
              currentChapter: _currentChapterIndex + 1,
              totalChapters: _chapters?.length ?? 0,
              onMenuPressed: () => Scaffold.of(context).openDrawer(),
            )
          : null,
      drawer: _showAppBar
          ? ReaderDrawer(
              chapters: _chapters ?? [],
              currentChapterIndex: _currentChapterIndex,
              onChapterSelected: _goToChapter,
            )
          : null,
      body: GestureDetector(
        onTap: _toggleAppBar,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return Container(
                  padding: theme.padding,
                  child: SingleChildScrollView(
                    child: Text(
                      _pages[index],
                      style: theme.textStyle,
                      textAlign: theme.textAlign,
                    ),
                  ),
                );
              },
            ),
            
            // Left tap zone for previous page
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.3,
              child: GestureDetector(
                onTap: _goToPreviousPage,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
            
            // Right tap zone for next page
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.3,
              child: GestureDetector(
                onTap: _goToNextPage,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
            
            // Progress indicator
            if (_showAppBar)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ReadingProgressIndicator(
                  progress: _calculateProgress(),
                  currentPage: _currentPageIndex + 1,
                  totalPages: _pages.length,
                  chapterTitle: _chapters?[_currentChapterIndex].Title ?? '',
                ),
              ),
          ],
        ),
      ),
    );
  }
}