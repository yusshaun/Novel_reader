import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../providers/books_provider.dart';
import '../providers/bookshelves_provider.dart';
import '../widgets/book_grid.dart';
import '../widgets/bookshelf_drawer.dart';
import '../widgets/app_bar_search.dart';
import '../services/epub_service.dart';
import 'epub_reader_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _importEpubFile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final epubService = ref.read(epubServiceProvider);
        final booksNotifier = ref.read(booksProvider.notifier);
        final defaultShelf = ref.read(bookshelvesProvider.notifier).getDefaultShelf();

        for (final platformFile in result.files) {
          if (platformFile.path != null) {
            final file = File(platformFile.path!);
            final book = await epubService.parseEpubFile(file);
            
            if (book != null) {
              await booksNotifier.addBook(book);
              
              if (defaultShelf != null) {
                await ref
                    .read(bookshelvesProvider.notifier)
                    .addBookToShelf(defaultShelf.id, book.id);
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added "${book.title}" to library'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing book: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openBook(String bookId) {
    final books = ref.read(booksProvider);
    final book = books.firstWhere((b) => b.id == bookId);
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EpubReaderScreen(book: book),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(booksProvider);
    final bookshelves = ref.watch(bookshelvesProvider);
    final filteredBooks = ref.watch(filteredBooksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Novel Reader'),
        elevation: 0,
        scrolledUnderElevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: AppBarSearch(books: books),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.library_books), text: 'Library'),
            Tab(icon: Icon(Icons.folder), text: 'Shelves'),
            Tab(icon: Icon(Icons.history), text: 'Recent'),
          ],
        ),
      ),
      drawer: const BookshelfDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Library Tab
          RefreshIndicator(
            onRefresh: () async {
              // Refresh the books list
              ref.invalidate(booksProvider);
            },
            child: books.isEmpty
                ? _buildEmptyState()
                : BookGrid(
                    books: filteredBooks,
                    onBookTap: _openBook,
                  ),
          ),
          
          // Shelves Tab
          _buildShelvesTab(bookshelves),
          
          // Recent Tab
          _buildRecentTab(),
        ],
      ),
      floatingActionButton: _isLoading
          ? const FloatingActionButton(
              onPressed: null,
              child: CircularProgressIndicator(),
            )
          : FloatingActionButton.extended(
              onPressed: _importEpubFile,
              icon: const Icon(Icons.add),
              label: const Text('Import Book'),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 100,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            'Your library is empty',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Import EPUB files to start reading',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _importEpubFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('Import Books'),
          ),
        ],
      ),
    );
  }

  Widget _buildShelvesTab(List<dynamic> bookshelves) {
    if (bookshelves.isEmpty) {
      return const Center(
        child: Text('No bookshelves yet'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookshelves.length,
      itemBuilder: (context, index) {
        final shelf = bookshelves[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(shelf.themeColorValue),
              child: Text(
                shelf.shelfName[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(shelf.shelfName),
            subtitle: Text('${shelf.bookIds.length} books'),
            trailing: shelf.isDefault 
                ? const Icon(Icons.star, color: Colors.amber)
                : null,
            onTap: () {
              // Navigate to shelf detail view
            },
          ),
        );
      },
    );
  }

  Widget _buildRecentTab() {
    final booksNotifier = ref.read(booksProvider.notifier);
    final recentBooks = booksNotifier.getRecentBooks(limit: 20);

    if (recentBooks.isEmpty) {
      return const Center(
        child: Text('No recently read books'),
      );
    }

    return BookGrid(
      books: recentBooks,
      onBookTap: _openBook,
    );
  }
}