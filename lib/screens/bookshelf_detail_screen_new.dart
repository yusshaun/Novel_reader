import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bookshelf.dart';
import '../models/epub_book.dart';
import '../providers/books_provider.dart';
import '../providers/bookshelves_provider.dart';
import '../services/cover_image_service.dart';
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
  bool _isEditMode = false;
  bool _isSortMode = false;
  List<String> _selectedBooks = [];

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
    final currentShelf = _getCurrentShelf();

    final booksMap = {for (var book in allBooks) book.id: book};

    // 按照書架中 bookIds 的順序返回書籍
    return currentShelf.bookIds
        .where((bookId) => booksMap.containsKey(bookId))
        .map((bookId) => booksMap[bookId]!)
        .toList();
  }

  BookShelf _getCurrentShelf() {
    final bookshelves = ref.watch(bookshelvesProvider);

    // 從 provider 中獲取最新的書架數據
    return bookshelves.firstWhere(
      (shelf) => shelf.id == widget.bookshelf.id,
      orElse: () => widget.bookshelf,
    );
  }

  @override
  Widget build(BuildContext context) {
    final booksInShelf = _getBooksInShelf();
    final currentShelf = _getCurrentShelf();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(currentShelf.shelfName),
        backgroundColor: Color(currentShelf.themeColorValue),
        foregroundColor: Colors.white,
        actions: [
          if (currentShelf.isDefault)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: const Icon(Icons.star, color: Colors.amber),
            ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            // 書架信息頭部
            Container(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(currentShelf.themeColorValue),
                    Color(currentShelf.themeColorValue).withOpacity(0.8),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: currentShelf.coverImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.memory(
                                  currentShelf.coverImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.library_books,
                                size: 32,
                                color: Colors.white,
                              ),
                      ),
                      // 封面編輯按鈕
                      if (!_isEditMode && !_isSortMode)
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: GestureDetector(
                            onTap: _editShelfCover,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 14,
                                color: Color(currentShelf.themeColorValue),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentShelf.shelfName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${booksInShelf.length} 本書',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 操作按鈕區域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_isEditMode) ...[
                      ListTile(
                        leading: const Icon(Icons.select_all),
                        title: const Text('全選'),
                        onTap: () {
                          _selectAllBooks();
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete),
                        title: const Text('移除選中的書籍'),
                        enabled: _selectedBooks.isNotEmpty,
                        onTap: _selectedBooks.isNotEmpty
                            ? () {
                                _removeSelectedBooks();
                                Navigator.pop(context);
                              }
                            : null,
                      ),
                      ListTile(
                        leading: const Icon(Icons.close),
                        title: const Text('退出編輯模式'),
                        onTap: () {
                          _exitEditMode();
                          Navigator.pop(context);
                        },
                      ),
                    ] else if (_isSortMode) ...[
                      ListTile(
                        leading: const Icon(Icons.check),
                        title: const Text('完成排序'),
                        onTap: () {
                          _exitSortMode();
                          Navigator.pop(context);
                        },
                      ),
                    ] else ...[
                      ListTile(
                        leading: const Icon(Icons.swap_vert),
                        title: const Text('排序書籍'),
                        onTap: () {
                          setState(() {
                            _isSortMode = true;
                          });
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.sort),
                        title: const Text('編輯書籍'),
                        onTap: () {
                          setState(() {
                            _isEditMode = true;
                          });
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('編輯書架'),
                        onTap: () {
                          _showEditShelfDialog();
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.add),
                        title: const Text('添加書籍'),
                        onTap: () {
                          _showAddBooksDialog();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: booksInShelf.isEmpty
            ? Center(
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
                      '使用側邊欄添加書籍',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            : _isSortMode
                ? _buildSortableBookList(booksInShelf)
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: booksInShelf.length,
                    itemBuilder: (context, index) {
                      final book = booksInShelf[index];
                      return _buildBookCard(book);
                    },
                  ),
      ),
      floatingActionButton: (_isEditMode || _isSortMode)
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAddBooksDialog,
              backgroundColor: Color(currentShelf.themeColorValue),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('添加書籍'),
            ),
    );
  }

  // 以下保留所有原有的方法實現...
  void _selectAllBooks() {
    setState(() {
      final allBookIds = _getBooksInShelf().map((book) => book.id).toList();
      _selectedBooks = allBookIds;
    });
  }

  void _removeSelectedBooks() async {
    try {
      final bookshelvesNotifier = ref.read(bookshelvesProvider.notifier);

      for (final bookId in _selectedBooks) {
        await bookshelvesNotifier.removeBookFromShelf(
            widget.bookshelf.id, bookId);
      }

      setState(() {
        _selectedBooks.clear();
        _isEditMode = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已移除選中的書籍'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('移除失敗：$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _exitEditMode() {
    setState(() {
      _isEditMode = false;
      _selectedBooks.clear();
    });
  }

  void _exitSortMode() {
    setState(() {
      _isSortMode = false;
    });
  }

  void _editShelfCover() {
    // 編輯書架封面的實現
  }

  void _showEditShelfDialog() {
    // 顯示編輯書架對話框的實現
  }

  void _showAddBooksDialog() {
    // 顯示添加書籍對話框的實現
  }

  Widget _buildSortableBookList(List<EpubBook> books) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text('排序模式 - 功能待實現'),
    );
  }

  Widget _buildBookCard(EpubBook book) {
    final isSelected = _selectedBooks.contains(book.id);

    return GestureDetector(
      onTap: () {
        if (_isEditMode) {
          setState(() {
            if (isSelected) {
              _selectedBooks.remove(book.id);
            } else {
              _selectedBooks.add(book.id);
            }
          });
        } else {
          _openBook(book.id);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: Colors.blue, width: 2)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        color: Colors.grey[200],
                      ),
                      child: book.coverImage != null
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: Image.memory(
                                book.coverImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.book,
                              size: 40,
                              color: Colors.grey,
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          book.author,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isEditMode)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? Colors.blue : Colors.grey,
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
