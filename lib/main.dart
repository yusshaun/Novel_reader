import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_screen.dart';
import 'models/epub_book.dart';
import 'models/bookshelf.dart';
import 'models/reader_theme.dart';
import 'models/reading_progress.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Hive adapters
  Hive.registerAdapter(EpubBookAdapter());
  Hive.registerAdapter(BookShelfAdapter());
  Hive.registerAdapter(ReaderThemeAdapter());
  Hive.registerAdapter(ReadingProgressAdapter());
  
  // Open Hive boxes
  await Hive.openBox<EpubBook>('books');
  await Hive.openBox<BookShelf>('bookshelves');
  await Hive.openBox<ReaderTheme>('reader_theme');
  await Hive.openBox<ReadingProgress>('reading_progress');
  
  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  
  runApp(
    ProviderScope(
      child: NovelReaderApp(savedThemeMode: savedThemeMode),
    ),
  );
}

class NovelReaderApp extends StatelessWidget {
  final AdaptiveThemeMode? savedThemeMode;
  
  const NovelReaderApp({
    super.key,
    this.savedThemeMode,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      dark: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      initial: savedThemeMode ?? AdaptiveThemeMode.system,
      builder: (theme, darkTheme) => MaterialApp(
        title: 'Novel Reader',
        theme: theme,
        darkTheme: darkTheme,
        home: const HomeScreen(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
          Locale('zh', 'CN'),
          Locale('zh', 'TW'),
        ],
      ),
    );
  }
}