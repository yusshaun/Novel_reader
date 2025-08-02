import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bookshelves_provider.dart';

class BookshelfDrawer extends ConsumerWidget {
  const BookshelfDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookshelves = ref.watch(bookshelvesProvider);

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.library_books,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'My Bookshelves',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                ),
                Text(
                  '${bookshelves.length} shelves',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: bookshelves.length,
              itemBuilder: (context, index) {
                final shelf = bookshelves[index];
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(shelf.themeColorValue),
                    child: Text(
                      shelf.shelfName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(shelf.shelfName),
                  subtitle: Text('${shelf.bookIds.length} books'),
                  trailing: shelf.isDefault
                      ? const Icon(Icons.star, color: Colors.amber, size: 20)
                      : null,
                  onTap: () {
                    ref.read(selectedShelfProvider.notifier).state = shelf;
                    Navigator.pop(context);
                    // TODO: Navigate to shelf detail view
                  },
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Create New Shelf'),
            onTap: () {
              Navigator.pop(context);
              _showCreateShelfDialog(context, ref);
            },
          ),
        ],
      ),
    );
  }

  void _showCreateShelfDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _CreateShelfDialog(),
    );
  }
}

class _CreateShelfDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CreateShelfDialog> createState() => _CreateShelfDialogState();
}

class _CreateShelfDialogState extends ConsumerState<_CreateShelfDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  Color _selectedColor = Colors.blue;

  final List<Color> _availableColors = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Shelf'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Shelf Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Color'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _availableColors.map((color) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: _selectedColor == color
                        ? Border.all(color: Colors.black, width: 2)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _nameController.text.trim().isEmpty
              ? null
              : () async {
                  await ref.read(bookshelvesProvider.notifier).createShelf(
                        name: _nameController.text.trim(),
                        themeColor: _selectedColor,
                        description: _descriptionController.text.trim().isEmpty
                            ? null
                            : _descriptionController.text.trim(),
                      );
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
          child: const Text('Create'),
        ),
      ],
    );
  }
}