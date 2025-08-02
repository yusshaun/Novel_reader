// This is a basic Flutter widget test for Novel Reader.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:novel_reader/main.dart';

void main() {
  testWidgets('Novel Reader app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: NovelReaderApp(),
      ),
    );

    // Verify that the app loads and shows the main navigation
    expect(find.text('Novel Reader'), findsOneWidget);

    // Verify that we have the main tabs
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Shelves'), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget);
  });
}
