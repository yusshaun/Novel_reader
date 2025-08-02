import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bookshelf.dart';
import '../models/epub_book.dart';
import '../providers/books_provider.dart';
import '../providers/bookshelves_provider.dart';
import 'epub_reader_screen.dart';

class BookshelfDetailScreen extends ConsumerStatefulWidget {
  final BookShelf bookshelf;

  const BookshelfDetailScreen({
    super.key,
    required this.bookshelf,
  });

  @override
  ConsumerState<BookshelfDetailScreen> createState() =>
      _BookshelfDetailScreenState();
}

class _BookshelfDetailScreenState extends ConsumerState<BookshelfDetailScreen> {
  void _openBook(String bookId) {
    final books = ref.read(booksProvider);
    final book = books.firstWhere((b) => b.id == bookId);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EpubReaderScreen(book: book),
      ),
    );
  }

  List<EpubBook> _getBooksInShelf() {
    final allBooks = ref.watch(booksProvider);
    return allBooks
        .where((book) => widget.bookshelf.bookIds.contains(book.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final booksInShelf = _getBooksInShelf();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // 漸變背景的 AppBar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Color(widget.bookshelf.themeColorValue),
            foregroundColor: Colors.white,
            actions: [
              if (widget.bookshelf.isDefault)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: const Icon(Icons.star, color: Colors.amber),
                ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _showEditShelfDialog();
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(widget.bookshelf.themeColorValue),
                      Color(widget.bookshelf.themeColorValue).withOpacity(0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // 背景裝飾
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -20,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    // 書架信息
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.library_books,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.bookshelf.shelfName,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${booksInShelf.length} 本書',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 書籍內容
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: booksInShelf.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.book_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '這個書架還是空的',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '點擊下方按鈕添加書籍',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.7,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final book = booksInShelf[index];
                        return _buildBookCard(book);
                      },
                      childCount: booksInShelf.length,
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddBookDialog,
        backgroundColor: Color(widget.bookshelf.themeColorValue),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('添加書籍'),
      ),
    );
  }

  Widget _buildBookCard(EpubBook book) {
    return GestureDetector(
      onTap: () => _openBook(book.id),
      onLongPress: () => _showBookOptions(book),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 書籍封面
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.grey[200],
                ),
                child: book.coverImage != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: Image.memory(
                          book.coverImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.book,
                        size: 48,
                        color: Colors.grey,
                      ),
              ),
            ),
            // 書籍信息
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookOptions(EpubBook book) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.open_in_new, color: Colors.blue),
                title: const Text('打開書籍'),
                onTap: () {
                  Navigator.pop(context);
                  _openBook(book.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.remove_circle, color: Colors.orange),
                title: const Text('從書架移除'),
                onTap: () {
                  Navigator.pop(context);
                  _removeBookFromShelf(book);
                },
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        );
      },
    );
  }

  void _showAddBookDialog() {
    final allBooks = ref.read(booksProvider);
    final availableBooks = allBooks
        .where((book) => !widget.bookshelf.bookIds.contains(book.id))
        .toList();

    if (availableBooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('所有書籍都已在此書架中'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('添加書籍到書架'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: availableBooks.length,
              itemBuilder: (context, index) {
                final book = availableBooks[index];
                return ListTile(
                  leading: book.coverImage != null
                      ? Image.memory(book.coverImage!,
                          width: 40, height: 60, fit: BoxFit.cover)
                      : const Icon(Icons.book),
                  title: Text(book.title),
                  subtitle: Text(book.author),
                  onTap: () {
                    Navigator.pop(context);
                    _addBookToShelf(book);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  void _addBookToShelf(EpubBook book) async {
    try {
      await ref
          .read(bookshelvesProvider.notifier)
          .addBookToShelf(widget.bookshelf.id, book.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已將「${book.title}」添加到書架'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('添加書籍失敗：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeBookFromShelf(EpubBook book) async {
    try {
      await ref
          .read(bookshelvesProvider.notifier)
          .removeBookFromShelf(widget.bookshelf.id, book.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已將「${book.title}」從書架移除'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('移除書籍失敗：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditShelfDialog() {
    // TODO: 實現編輯書架功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('編輯書架功能待實現'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
