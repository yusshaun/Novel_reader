import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/reader_theme.dart';

final readerThemeBoxProvider = Provider<Box<ReaderTheme>>((ref) {
  return Hive.box<ReaderTheme>('reader_theme');
});

final readerThemeProvider = StateNotifierProvider<ReaderThemeNotifier, ReaderTheme>((ref) {
  final box = ref.watch(readerThemeBoxProvider);
  return ReaderThemeNotifier(box);
});

class ReaderThemeNotifier extends StateNotifier<ReaderTheme> {
  final Box<ReaderTheme> _box;
  static const String _themeKey = 'current_theme';
  
  ReaderThemeNotifier(this._box) : super(_getInitialTheme(_box));

  static ReaderTheme _getInitialTheme(Box<ReaderTheme> box) {
    return box.get(_themeKey) ?? ReaderTheme();
  }

  Future<void> updateFontSize(double fontSize) async {
    if (fontSize >= 12.0 && fontSize <= 32.0) {
      final newTheme = state.copyWith(fontSize: fontSize);
      await _saveTheme(newTheme);
    }
  }

  Future<void> updateFontFamily(String fontFamily) async {
    if (ReaderTheme.availableFonts.contains(fontFamily)) {
      final newTheme = state.copyWith(fontFamily: fontFamily);
      await _saveTheme(newTheme);
    }
  }

  Future<void> toggleDarkMode() async {
    final newTheme = state.copyWith(darkMode: !state.darkMode);
    await _saveTheme(newTheme);
  }

  Future<void> updateBackgroundColor(int colorValue) async {
    final newTheme = state.copyWith(bgColorValue: colorValue);
    await _saveTheme(newTheme);
  }

  Future<void> updateTextColor(int colorValue) async {
    final newTheme = state.copyWith(textColorValue: colorValue);
    await _saveTheme(newTheme);
  }

  Future<void> updateLineHeight(double lineHeight) async {
    if (lineHeight >= 1.0 && lineHeight <= 3.0) {
      final newTheme = state.copyWith(lineHeight: lineHeight);
      await _saveTheme(newTheme);
    }
  }

  Future<void> updateLetterSpacing(double letterSpacing) async {
    if (letterSpacing >= -2.0 && letterSpacing <= 5.0) {
      final newTheme = state.copyWith(letterSpacing: letterSpacing);
      await _saveTheme(newTheme);
    }
  }

  Future<void> updateWordSpacing(double wordSpacing) async {
    if (wordSpacing >= 0.0 && wordSpacing <= 10.0) {
      final newTheme = state.copyWith(wordSpacing: wordSpacing);
      await _saveTheme(newTheme);
    }
  }

  Future<void> resetToDefaults() async {
    final defaultTheme = ReaderTheme();
    await _saveTheme(defaultTheme);
  }

  Future<void> updateFromSystemTheme(bool isDarkMode) async {
    final newTheme = ReaderTheme(
      fontSize: state.fontSize,
      fontFamily: state.fontFamily,
      darkMode: isDarkMode,
      bgColorValue: isDarkMode ? 0xFF121212 : 0xFFFFFFFF,
      textColorValue: isDarkMode ? 0xFFE0E0E0 : 0xFF000000,
      lineHeight: state.lineHeight,
      letterSpacing: state.letterSpacing,
      wordSpacing: state.wordSpacing,
      padding: state.padding,
      textAlign: state.textAlign,
    );
    await _saveTheme(newTheme);
  }

  Future<void> _saveTheme(ReaderTheme theme) async {
    state = theme;
    await _box.put(_themeKey, theme);
  }
}