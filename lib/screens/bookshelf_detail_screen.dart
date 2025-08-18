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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? Theme.of(context).scaffoldBackgroundColor
          : Colors.grey[50],
      appBar: AppBar(
        title: Text(currentShelf.shelfName),
        backgroundColor: Color(currentShelf.themeColorValue),
        foregroundColor:
            isDarkMode ? Theme.of(context).colorScheme.onSurface : Colors.white,
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
              tooltip: '返回',
            ),
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                tooltip: '選單',
              ),
            ),
          ],
        ),
        leadingWidth: 100, // 增加 leading 區域寬度以容納兩個按鈕
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
                          color: isDarkMode
                              ? Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.3)
                              : Colors.white.withOpacity(0.2),
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
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${booksInShelf.length} 本書',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode
                                ? Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7)
                                : Colors.white70,
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
                      color: isDarkMode
                          ? Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.4)
                          : Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '這個書架還是空的',
                      style: TextStyle(
                        fontSize: 18,
                        color: isDarkMode
                            ? Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6)
                            : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '使用側邊欄添加書籍',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode
                            ? Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5)
                            : Colors.grey[500],
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
              foregroundColor: isDarkMode
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.white,
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
    // TODO: 實現書架封面編輯功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('封面編輯功能待實現'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showEditShelfDialog() {
    final TextEditingController nameController =
        TextEditingController(text: widget.bookshelf.shelfName);
    final TextEditingController descriptionController =
        TextEditingController(text: widget.bookshelf.description ?? '');
    Color selectedColor = Color(widget.bookshelf.themeColorValue);

    // 預設顏色選項
    final List<Color> colorOptions = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.lime,
      Colors.deepPurple,
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.edit,
                    color: selectedColor,
                  ),
                  const SizedBox(width: 8),
                  const Text('編輯書架'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 書架名稱
                    const Text(
                      '書架名稱',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: '輸入書架名稱',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.library_books),
                      ),
                      maxLength: 20,
                    ),
                    const SizedBox(height: 16),

                    // 書架描述
                    const Text(
                      '書架描述（選填）',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        hintText: '輸入書架描述',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.description),
                      ),
                      maxLines: 2,
                      maxLength: 100,
                    ),
                    const SizedBox(height: 16),

                    // 主題顏色
                    const Text(
                      '主題顏色',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: colorOptions.length,
                        itemBuilder: (context, index) {
                          final color = colorOptions[index];
                          final isSelected = color.value == selectedColor.value;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedColor = color;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: Colors.black54,
                                        width: 3,
                                      )
                                    : Border.all(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withOpacity(0.5),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    '取消',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final description = descriptionController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('書架名稱不能為空'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context);

                    try {
                      final bookshelvesNotifier =
                          ref.read(bookshelvesProvider.notifier);

                      // 創建更新後的書架對象
                      final currentShelf = _getCurrentShelf();
                      final updatedShelf = BookShelf(
                        id: currentShelf.id,
                        shelfName: name,
                        bookIds: currentShelf.bookIds,
                        themeColorValue: selectedColor.value,
                        createdAt: currentShelf.createdAt,
                        updatedAt: DateTime.now(),
                        description: description.isEmpty ? null : description,
                        isDefault: currentShelf.isDefault,
                        coverImage: currentShelf.coverImage,
                      );

                      await bookshelvesNotifier.updateShelf(updatedShelf);

                      if (mounted) {
                        setState(() {});
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('書架「$name」已更新'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('更新失敗：$e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddBooksDialog() {
    // 獲取不在當前書架中的所有書籍
    final allBooks = ref.read(booksProvider);
    final availableBooks = allBooks
        .where((book) => !widget.bookshelf.bookIds.contains(book.id))
        .toList();

    if (availableBooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('沒有可添加的書籍'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    List<String> selectedBooksToAdd = [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('添加書籍到書架'),
              content: Container(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    Text(
                      '選擇要添加到「${widget.bookshelf.shelfName}」的書籍：',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: availableBooks.length,
                        itemBuilder: (context, index) {
                          final book = availableBooks[index];
                          final isSelected =
                              selectedBooksToAdd.contains(book.id);

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selectedBooksToAdd.add(book.id);
                                } else {
                                  selectedBooksToAdd.remove(book.id);
                                }
                              });
                            },
                            title: Text(
                              book.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              book.author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            secondary: book.coverImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.memory(
                                      book.coverImage!,
                                      width: 40,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    width: 40,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.book,
                                        color: Colors.grey),
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    '取消',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedBooksToAdd.isNotEmpty
                      ? () async {
                          Navigator.pop(context);
                          await _performAddBooks(selectedBooksToAdd);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(widget.bookshelf.themeColorValue),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('添加 (${selectedBooksToAdd.length})'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _performAddBooks(List<String> bookIds) async {
    try {
      final bookshelvesNotifier = ref.read(bookshelvesProvider.notifier);

      for (final bookId in bookIds) {
        await bookshelvesNotifier.addBookToShelf(widget.bookshelf.id, bookId);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已添加 ${bookIds.length} 本書籍到書架'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('添加失敗：$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSortableBookList(List<EpubBook> books) {
    final currentShelf = _getCurrentShelf();

    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(currentShelf.themeColorValue).withOpacity(0.3),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.swap_vert,
                color: Color(currentShelf.themeColorValue),
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '拖拽排序模式',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(currentShelf.themeColorValue),
                      ),
                    ),
                    Text(
                      '長按並拖拽書籍來重新排序',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: books.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
                // TODO: 實現重新排序邏輯
              },
              itemBuilder: (context, index) {
                final book = books[index];
                return Card(
                  key: ValueKey(book.id),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: book.coverImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.memory(
                              book.coverImage!,
                              width: 40,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(
                            width: 40,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.book, color: Colors.grey),
                          ),
                    title: Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.drag_handle),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
