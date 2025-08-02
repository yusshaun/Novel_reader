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
      body: CustomScrollView(
        slivers: [
          // 漸變背景的 AppBar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Color(currentShelf.themeColorValue),
            foregroundColor: Colors.white,
            actions: [
              if (currentShelf.isDefault)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: const Icon(Icons.star, color: Colors.amber),
                ),
              if (_isEditMode) ...[
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: _selectAllBooks,
                  tooltip: '全選',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed:
                      _selectedBooks.isNotEmpty ? _removeSelectedBooks : null,
                  tooltip: '移除選中的書籍',
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _exitEditMode,
                  tooltip: '退出編輯模式',
                ),
              ] else if (_isSortMode) ...[
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _exitSortMode,
                  tooltip: '完成排序',
                ),
              ] else ...[
                IconButton(
                  icon: const Icon(Icons.swap_vert),
                  onPressed: () {
                    setState(() {
                      _isSortMode = true;
                    });
                  },
                  tooltip: '排序書籍',
                ),
                IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: () {
                    setState(() {
                      _isEditMode = true;
                    });
                  },
                  tooltip: '編輯書籍',
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _showEditShelfDialog();
                  },
                  tooltip: '編輯書架',
                ),
              ],
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
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
                                      currentShelf.shelfName,
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
                : _isSortMode
                    ? SliverToBoxAdapter(
                        child: _buildSortableBookList(booksInShelf),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(currentShelf.themeColorValue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${books.length} 本書',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(currentShelf.themeColorValue),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: books.length,
            onReorder: _onBookReorder,
            itemBuilder: (context, index) {
              final book = books[index];
              return _buildSortableBookItem(book, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSortableBookItem(EpubBook book, int index) {
    return Container(
      key: ValueKey(book.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Container(
            width: 50,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: book.coverImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      book.coverImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.book,
                    size: 32,
                    color: Colors.grey,
                  ),
          ),
          title: Text(
            book.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            book.author,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.drag_handle,
                color: Colors.grey[600],
                size: 24,
              ),
              Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          onTap: () => _openBook(book.id),
        ),
      ),
    );
  }

  void _onBookReorder(int oldIndex, int newIndex) async {
    try {
      // 獲取當前最新的書架數據
      final currentShelf = _getCurrentShelf();

      // 創建 bookIds 的副本來重新排序
      final reorderedBookIds = List<String>.from(currentShelf.bookIds);

      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final bookId = reorderedBookIds.removeAt(oldIndex);
      reorderedBookIds.insert(newIndex, bookId);

      // 創建更新後的書架副本
      final updatedShelf = currentShelf.copyWith(
        bookIds: reorderedBookIds,
        updatedAt: DateTime.now(),
      );

      // 更新資料庫
      await ref.read(bookshelvesProvider.notifier).updateShelf(updatedShelf);

      // 顯示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('書籍順序已更新'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('排序失敗：$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildBookCard(EpubBook book) {
    final isSelected = _selectedBooks.contains(book.id);
    final currentShelf = _getCurrentShelf();

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
      onLongPress: () {
        if (!_isEditMode) {
          _showBookOptions(book);
        }
      },
      child: Stack(
        children: [
          Card(
            elevation: _isEditMode && isSelected ? 8 : 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: _isEditMode && isSelected
                  ? BorderSide(
                      color: Color(currentShelf.themeColorValue),
                      width: 2,
                    )
                  : BorderSide.none,
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
          // 選擇指示器
          if (_isEditMode)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Color(currentShelf.themeColorValue)
                      : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? Color(currentShelf.themeColorValue)
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            ),
        ],
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
                leading: const Icon(Icons.image, color: Colors.purple),
                title: const Text('編輯封面'),
                onTap: () {
                  Navigator.pop(context);
                  _editBookCover(book);
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

  void _editBookCover(EpubBook book) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.image, color: Colors.purple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '編輯封面',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 當前封面預覽
              Container(
                width: 120,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: book.coverImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
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
              const SizedBox(height: 20),
              Text(
                '書名：${book.title}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _updateBookCover(book);
                    },
                    icon: const Icon(Icons.upload),
                    label: const Text('更換封面'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  if (book.coverImage != null)
                    OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        final shouldRemove =
                            await CoverImageService.showRemoveCoverDialog(
                                context);
                        if (shouldRemove && mounted) {
                          await _removeCover(book);
                        }
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('移除封面'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '關閉',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateBookCover(EpubBook book) async {
    try {
      debugPrint('開始選擇封面圖片...');
      final newCoverData =
          await CoverImageService.showImagePickerDialog(context);

      debugPrint('圖片選擇結果: ${newCoverData != null ? '成功' : '失敗'}');
      if (newCoverData != null) {
        debugPrint('圖片大小: ${newCoverData.length} bytes');
        debugPrint('圖片數據哈希: ${newCoverData.hashCode}');
      }

      if (newCoverData != null && mounted) {
        debugPrint('開始更新書籍封面...');
        // 更新書籍封面
        final updatedBook = book.copyWith(coverImage: newCoverData);
        await ref.read(booksProvider.notifier).updateBook(updatedBook);

        debugPrint('封面更新完成');
        
        // 強制刷新UI
        setState(() {});
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已更新「${book.title}」的封面'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else if (newCoverData == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('未選擇圖片'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('更新封面時發生錯誤: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新封面失敗：$e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _removeCover(EpubBook book) async {
    try {
      // 移除書籍封面
      final updatedBook = book.copyWith(clearCoverImage: true);
      await ref.read(booksProvider.notifier).updateBook(updatedBook);

      // 強制刷新UI
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已移除「${book.title}」的封面'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('移除封面失敗：$e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: colorOptions.map((color) {
                          final isSelected = color.value == selectedColor.value;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedColor = color;
                              });
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.grey.shade300,
                                  width: isSelected ? 3 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withOpacity(0.3),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
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
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('請輸入書架名稱'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final updatedShelf = widget.bookshelf.copyWith(
                      shelfName: name,
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      themeColorValue: selectedColor.value,
                      updatedAt: DateTime.now(),
                    );

                    await ref
                        .read(bookshelvesProvider.notifier)
                        .updateShelf(updatedShelf);

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('書架「$name」已更新'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // 更新當前頁面
                    setState(() {});
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

  void _selectAllBooks() {
    final booksInShelf = _getBooksInShelf();
    setState(() {
      if (_selectedBooks.length == booksInShelf.length) {
        _selectedBooks.clear();
      } else {
        _selectedBooks = booksInShelf.map((book) => book.id).toList();
      }
    });
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

  void _removeSelectedBooks() {
    if (_selectedBooks.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('移除書籍'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('確定要從書架中移除 ${_selectedBooks.length} 本書籍嗎？'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '書籍將從此書架中移除，但不會被刪除',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                Navigator.pop(context);
                await _performRemoveBooks();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('移除'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performRemoveBooks() async {
    try {
      final bookshelvesNotifier = ref.read(bookshelvesProvider.notifier);

      for (final bookId in _selectedBooks) {
        await bookshelvesNotifier.removeBookFromShelf(
            widget.bookshelf.id, bookId);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已從書架中移除 ${_selectedBooks.length} 本書籍'),
          backgroundColor: Colors.green,
        ),
      );

      _exitEditMode();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('移除失敗：$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
}
