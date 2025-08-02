import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Simple Tests', () {
    test('basic arithmetic', () {
      expect(2 + 2, equals(4));
      expect(3 * 3, equals(9));
    });

    test('string operations', () {
      expect('Hello'.length, equals(5));
      expect('World'.toUpperCase(), equals('WORLD'));
    });

    test('list operations', () {
      final list = [1, 2, 3];
      expect(list.length, equals(3));
      expect(list.first, equals(1));
      expect(list.last, equals(3));
    });
  });
}
