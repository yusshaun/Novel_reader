import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../providers/books_provider.dart';
import '../providers/bookshelves_provider.dart';
import '../widgets/book_grid.dart';
import '../widgets/app_bar_search.dart';
import '../utils/platform_file_import.dart';
import 'epub_reader_screen.dart';
import 'settings_screen.dart';
import 'bookshelf_detail_screen.dart';

// 導航項目類別
class NavigationItem {
  final IconData icon;
  final String label;
  final String title;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.title,
  });
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isLoading = false;
  int _selectedIndex = 1; // 預設選中 Shelves

  // 導航項目
  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.library_books,
      label: 'Library',
      title: 'Library',
    ),
    NavigationItem(
      icon: Icons.folder,
      label: 'Shelves',
      title: 'Bookshelves',
    ),
    NavigationItem(
      icon: Icons.history,
      label: 'Recent',
      title: 'Recent Books',
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _importEpubFile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final filePaths = await PlatformFileImport.pickEpubFiles();

      if (filePaths != null && filePaths.isNotEmpty) {
        await _processEpubFiles(filePaths);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing books: $e'),
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

  Future<void> _processEpubFiles(List<String> filePaths) async {
    final epubService = ref.read(epubServiceProvider);
    final booksNotifier = ref.read(booksProvider.notifier);
    final defaultShelf =
        ref.read(bookshelvesProvider.notifier).getDefaultShelf();

    for (final filePath in filePaths) {
      try {
        final file = File(filePath);
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
      } catch (e) {
        print('Error processing file $filePath: $e');
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
        title: Text(_navigationItems[_selectedIndex].title),
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
      ),
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.book,
                    color: Colors.white,
                    size: 32,
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Novel Reader',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _navigationItems.length,
                itemBuilder: (context, index) {
                  final item = _navigationItems[index];
                  final isSelected = _selectedIndex == index;

                  return ListTile(
                    leading: Icon(
                      item.icon,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color:
                            isSelected ? Theme.of(context).primaryColor : null,
                      ),
                    ),
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                      Navigator.pop(context); // 關閉 drawer
                    },
                  );
                },
              ),
            ),
            const Divider(),
            // 書架管理相關選項
            ListTile(
              leading: const Icon(Icons.folder_special),
              title: const Text('Manage Bookshelves'),
              onTap: () {
                Navigator.pop(context);
                // 可以添加書架管理功能
              },
            ),
          ],
        ),
      ),
      body: PlatformFileImport.buildDragDropWidget(
            onFilesDropped: (filePaths) async {
              if (filePaths.isNotEmpty) {
                setState(() {
                  _isLoading = true;
                });
                await _processEpubFiles(filePaths);
                setState(() {
                  _isLoading = false;
                });
              }
            },
            child: _buildCurrentContent(books, bookshelves, filteredBooks),
          ) ??
          _buildCurrentContent(books, bookshelves, filteredBooks),
      floatingActionButton: _selectedIndex == 1 // Shelves tab
          ? FloatingActionButton(
              onPressed: _showCreateShelfDialog,
              tooltip: '新增書架',
              child: const Icon(Icons.add),
            )
          : PlatformFileImport.buildFileImportButton(
              onPressed: _importEpubFile,
              isLoading: _isLoading,
            ),
    );
  }

  Widget _buildCurrentContent(
      List books, List bookshelves, List filteredBooks) {
    switch (_selectedIndex) {
      case 0: // Library
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(booksProvider);
          },
          child: books.isEmpty
              ? _buildEmptyState()
              : BookGrid(
                  books: filteredBooks.cast(),
                  onBookTap: _openBook,
                ),
        );
      case 1: // Shelves
        return _buildShelvesTab(bookshelves);
      case 2: // Recent
        return _buildRecentTab();
      default:
        return _buildShelvesTab(bookshelves);
    }
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('還沒有書架', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('到設定中建立你的第一個書架吧！'),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: bookshelves.length,
      itemBuilder: (context, index) {
        final shelf = bookshelves[index];
        return _buildShelfCard(shelf);
      },
    );
  }

  Widget _buildShelfCard(dynamic shelf) {
    return GestureDetector(
      onTap: () {
        final detailScreen = BookshelfDetailScreen(bookshelf: shelf);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => detailScreen,
          ),
        );
      },
      onLongPress: () => _showShelfOptions(shelf),
      child: Card(
        elevation: 4,
        shadowColor: Color(shelf.themeColorValue).withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          child: Stack(
            children: [
              // 背景：書架封面或漸變背景
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: shelf.coverImage != null
                      ? null
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(shelf.themeColorValue),
                            Color(shelf.themeColorValue).withOpacity(0.7),
                          ],
                        ),
                ),
                child: shelf.coverImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            // 封面圖片作為背景
                            Positioned.fill(
                              child: Image.memory(
                                shelf.coverImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                            // 半透明遮罩確保文字可讀性
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.6),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : null,
              ),
              // 背景裝飾圖案（僅在沒有封面時顯示）
              if (shelf.coverImage == null) ...[
                Positioned(
                  top: -15,
                  right: -15,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -8,
                  left: -8,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),
              ],
              // 主要內容
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 頂部區域：圖示和選項按鈕
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 如果沒有封面，顯示圖示
                        if (shelf.coverImage == null)
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.library_books,
                              size: 24,
                              color: Colors.white,
                            ),
                          )
                        else
                          // 如果有封面，顯示小標記
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.photo,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '自訂封面',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!shelf.isDefault)
                          GestureDetector(
                            onTap: () => _showShelfOptions(shelf),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (shelf.coverImage != null
                                        ? Colors.black
                                        : Colors.white)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.more_vert,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    // 書架名稱（增強可讀性）
                    Container(
                      padding: shelf.coverImage != null
                          ? const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4)
                          : EdgeInsets.zero,
                      decoration: shelf.coverImage != null
                          ? BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(6),
                            )
                          : null,
                      child: Text(
                        shelf.shelfName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: shelf.coverImage != null
                              ? [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 3,
                                    color: Colors.black.withOpacity(0.8),
                                  ),
                                ]
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // 書籍數量（增強可讀性）
                    Consumer(
                      builder: (context, ref, child) {
                        return Container(
                          padding: shelf.coverImage != null
                              ? const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2)
                              : EdgeInsets.zero,
                          decoration: shelf.coverImage != null
                              ? BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                )
                              : null,
                          child: Text(
                            '${shelf.bookIds.length} 本書',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              shadows: shelf.coverImage != null
                                  ? [
                                      Shadow(
                                        offset: Offset(1, 1),
                                        blurRadius: 2,
                                        color: Colors.black.withOpacity(0.8),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    // 默認標籤
                    if (shelf.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '默認',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShelfOptions(dynamic shelf) {
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
              // 拖拽指示器
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
              // 書架信息
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(shelf.themeColorValue).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.library_books,
                        color: Color(shelf.themeColorValue),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shelf.shelfName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Consumer(
                            builder: (context, ref, child) {
                              return Text(
                                '${shelf.bookIds.length} 本書',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // 選項列表
              if (!shelf.isDefault) ...[
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('編輯書架'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditShelfDialog(shelf);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('刪除書架'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteShelf(shelf);
                  },
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    '這是默認書架，無法刪除',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteShelf(dynamic shelf) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('刪除書架'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('確定要刪除「${shelf.shelfName}」書架嗎？'),
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
                      Icons.warning_amber_rounded,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '書架中的書籍不會被刪除，但會從此書架中移除',
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
                await _deleteShelf(shelf);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('刪除'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteShelf(dynamic shelf) async {
    try {
      // 如果書架中有書籍，將它們移動到默認書架
      if (shelf.bookIds.isNotEmpty) {
        final defaultShelf =
            ref.read(bookshelvesProvider.notifier).getDefaultShelf();
        if (defaultShelf != null && defaultShelf.id != shelf.id) {
          final bookshelvesNotifier = ref.read(bookshelvesProvider.notifier);

          // 將所有書籍添加到默認書架
          for (final bookId in shelf.bookIds) {
            if (!defaultShelf.bookIds.contains(bookId)) {
              await bookshelvesNotifier.addBookToShelf(defaultShelf.id, bookId);
            }
          }
        }
      }

      // 刪除書架
      await ref.read(bookshelvesProvider.notifier).deleteShelf(shelf.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已刪除書架「${shelf.shelfName}」'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刪除書架失敗：$e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _showEditShelfDialog(dynamic shelf) {
    final TextEditingController nameController =
        TextEditingController(text: shelf.shelfName);
    final TextEditingController descriptionController =
        TextEditingController(text: shelf.description ?? '');
    Color selectedColor = Color(shelf.themeColorValue);

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
                              width: 40,
                              height: 40,
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
                                      size: 20,
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

                    final updatedShelf = shelf.copyWith(
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

  void _showCreateShelfDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('新增書架'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '書架名稱',
                  hintText: '輸入書架名稱',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '描述（可選）',
                  hintText: '輸入書架描述',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('顏色：'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: [
                        Colors.blue,
                        Colors.red,
                        Colors.green,
                        Colors.orange,
                        Colors.purple,
                        Colors.teal,
                        Colors.pink,
                        Colors.brown,
                      ]
                          .map((color) => GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedColor = color;
                                  });
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: selectedColor == color
                                        ? Border.all(
                                            color: Colors.black, width: 2)
                                        : null,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  try {
                    await ref.read(bookshelvesProvider.notifier).createShelf(
                          name: name,
                          themeColor: selectedColor,
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                        );

                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('書架「$name」已建立')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('建立書架失敗：$e')),
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('請輸入書架名稱')),
                  );
                }
              },
              child: const Text('建立'),
            ),
          ],
        ),
      ),
    );
  }
}
