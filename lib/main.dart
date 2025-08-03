import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_core/firebase_core.dart';
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

  // Initialize Firebase - commented out for Windows build
  // await Firebase.initializeApp();

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

  // 打開閱讀進度盒子
  try {
    final progressBox = await Hive.openBox<ReadingProgress>('reading_progress');
    print('Reading progress box opened successfully with ${progressBox.length} records');
  } catch (e) {
    print('Error opening progress box: $e');
    // 如果打開失敗，刪除舊盒子並重新創建
    await Hive.deleteBoxFromDisk('reading_progress');
    await Hive.openBox<ReadingProgress>('reading_progress');
    print('Created new reading progress box');
  }

  final savedThemeMode = await AdaptiveTheme.getThemeMode();

  runApp(
    ProviderScope(
      child: NovelReaderApp(savedThemeMode: savedThemeMode),
    ),
  );
}

class NovelReaderApp extends StatefulWidget {
  final AdaptiveThemeMode? savedThemeMode;

  const NovelReaderApp({
    super.key,
    this.savedThemeMode,
  });

  @override
  State<NovelReaderApp> createState() => _NovelReaderAppState();
}

class _NovelReaderAppState extends State<NovelReaderApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // 監聽應用生命週期，確保關閉應用時保存所有數據
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 當應用即將關閉或進入後台時，確保 Hive 數據已保存
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _ensureDataSaved();
    }
  }

  // 確保所有數據已保存到磁碟
  void _ensureDataSaved() async {
    try {
      // 強制將所有 Hive 盒子的數據刷新到磁碟
      final boxes = [
        'books',
        'bookshelves',
        'reader_theme',
        'reading_progress'
      ];

      for (final boxName in boxes) {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          await box.flush();
        }
      }
      print('✅ All Hive data flushed to disk safely');
    } catch (e) {
      print('❌ Error flushing Hive data: $e');
    }
  }

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
      initial: widget.savedThemeMode ?? AdaptiveThemeMode.system,
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
