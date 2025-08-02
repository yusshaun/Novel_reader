import 'package:flutter/material.dart';
import '../models/epub_book.dart';

class AppBarSearch extends SearchDelegate<EpubBook?> {
  final List<EpubBook> books;

  AppBarSearch({required this.books});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return const Center(
        child: Text('Type to search books...'),
      );
    }

    final filteredBooks = books.where((book) {
      return book.title.toLowerCase().contains(query.toLowerCase()) ||
             book.author.toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (filteredBooks.isEmpty) {
      return const Center(
        child: Text('No books found'),
      );
    }

    return ListView.builder(
      itemCount: filteredBooks.length,
      itemBuilder: (context, index) {
        final book = filteredBooks[index];
        return ListTile(
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
                  child: const Icon(Icons.book),
                ),
          title: Text(book.title),
          subtitle: Text(book.author),
          onTap: () {
            close(context, book);
          },
        );
      },
    );
  }
}