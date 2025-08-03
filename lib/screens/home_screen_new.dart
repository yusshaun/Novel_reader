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

  Future<void> _importEpubFile() async {
    try {
      final filePath = await PlatformFileImport.importFile();
      if (filePath != null) {
        setState(() {
          _isLoading = true;
        });
        await _processEpubFiles([filePath]);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('導入失敗: $e')),
        );
      }
    }
  }

  Future<void> _processEpubFiles(List<String> filePaths) async {
    try {
      final booksNotifier = ref.read(booksProvider.notifier);

      for (final filePath in filePaths) {
        await booksNotifier.addBookFromPath(filePath);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功導入 ${filePaths.length} 本書'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('處理文件時發生錯誤: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
      floatingActionButton: PlatformFileImport.buildFileImportButton(
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
                  books: filteredBooks,
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
            size: 120,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            'No Books Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Import your first EPUB book to get started',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _importEpubFile,
            icon: const Icon(Icons.add),
            label: const Text('Import Book'),
          ),
        ],
      ),
    );
  }

  Widget _buildShelvesTab(List bookshelves) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(bookshelvesProvider);
      },
      child: bookshelves.isEmpty
          ? _buildEmptyShelvesState()
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: bookshelves.length,
              itemBuilder: (context, index) {
                final shelf = bookshelves[index];
                return _buildShelfCard(shelf);
              },
            ),
    );
  }

  Widget _buildEmptyShelvesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_outlined,
            size: 120,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            'No Bookshelves Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first bookshelf to organize your books',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => _showCreateShelfDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Bookshelf'),
          ),
        ],
      ),
    );
  }

  Widget _buildShelfCard(shelf) {
    final books = ref.watch(booksProvider);
    final shelfBooks = books
        .where((book) => book.bookshelfIds?.contains(shelf.id) == true)
        .toList();

    // 獲取書架封面圖片
    String? coverImage;
    if (shelfBooks.isNotEmpty && shelfBooks.first.coverImagePath != null) {
      coverImage = shelfBooks.first.coverImagePath;
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BookshelfDetailScreen(bookshelf: shelf),
            ),
          );
        },
        child: Container(
          decoration: coverImage != null
              ? BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(File(coverImage)),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.3),
                      BlendMode.darken,
                    ),
                  ),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        shelf.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: coverImage != null ? Colors.white : null,
                              shadows: coverImage != null
                                  ? [
                                      const Shadow(
                                        offset: Offset(1, 1),
                                        blurRadius: 3,
                                        color: Colors.black54,
                                      )
                                    ]
                                  : null,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: coverImage != null ? Colors.white : null,
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditShelfDialog(context, shelf);
                        } else if (value == 'delete') {
                          _showDeleteShelfDialog(context, shelf);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Edit'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete),
                            title: Text('Delete'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '${shelfBooks.length} ${shelfBooks.length == 1 ? 'book' : 'books'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: coverImage != null
                            ? Colors.white.withOpacity(0.9)
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        shadows: coverImage != null
                            ? [
                                const Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                  color: Colors.black54,
                                )
                              ]
                            : null,
                      ),
                ),
                if (shelf.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    shelf.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: coverImage != null
                              ? Colors.white.withOpacity(0.8)
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          shadows: coverImage != null
                              ? [
                                  const Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                    color: Colors.black54,
                                  )
                                ]
                              : null,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTab() {
    final books = ref.watch(booksProvider);
    final recentBooks = books.take(10).toList(); // 最近的10本書

    if (recentBooks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 120,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'No Recent Books',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start reading to see your recent books here',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return BookGrid(
      books: recentBooks,
      onBookTap: _openBook,
    );
  }

  void _showCreateShelfDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Bookshelf'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Bookshelf Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              final description = descriptionController.text.trim();
              await ref.read(bookshelvesProvider.notifier).createShelf(
                    name: name,
                    description: description.isEmpty ? null : description,
                  );

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('書架「$name」已創建')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditShelfDialog(BuildContext context, shelf) {
    final nameController = TextEditingController(text: shelf.name);
    final descriptionController =
        TextEditingController(text: shelf.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Bookshelf'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Bookshelf Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              final description = descriptionController.text.trim();
              final updatedShelf = shelf.copyWith(
                name: name,
                description: description.isEmpty ? null : description,
              );

              await ref
                  .read(bookshelvesProvider.notifier)
                  .updateShelf(updatedShelf);

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('書架「$name」已更新')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteShelfDialog(BuildContext context, shelf) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bookshelf'),
        content: Text(
            'Are you sure you want to delete "${shelf.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(bookshelvesProvider.notifier)
                  .deleteShelf(shelf.id);

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('書架「${shelf.name}」已刪除')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
