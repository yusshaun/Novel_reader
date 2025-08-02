import 'package:flutter_test/flutter_test.dart';
import '../lib/screens/bookshelf_detail_screen.dart';
import '../lib/models/bookshelf.dart';

void main() {
  test('BookshelfDetailScreen should be instantiable', () {
    final mockBookshelf = BookShelf(
      id: 'test-id',
      shelfName: 'Test Shelf',
      bookIds: [],
      themeColorValue: 0xFF2196F3,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDefault: false,
    );

    expect(
        () => BookshelfDetailScreen(bookshelf: mockBookshelf), returnsNormally);
  });
}
