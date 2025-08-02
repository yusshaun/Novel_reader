import 'package:flutter_test/flutter_test.dart';
import 'package:novel_reader/services/epub_service.dart';

void main() {
  group('EpubService Tests', () {
    test('EpubService can be instantiated', () {
      final service = EpubService();
      expect(service, isNotNull);
    });

    test('Search functionality with empty results', () async {
      final service = EpubService();
      
      // Test with non-existent file should return empty list
      final results = await service.searchInBook('/non/existent/path.epub', 'test');
      expect(results, isEmpty);
    });
  });
}