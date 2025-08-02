import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'reader_theme.g.dart';

@HiveType(typeId: 2)
class ReaderTheme extends HiveObject {
  @HiveField(0)
  double fontSize;
  
  @HiveField(1)
  String fontFamily;
  
  @HiveField(2)
  bool darkMode;
  
  @HiveField(3)
  int bgColorValue;
  
  @HiveField(4)
  int textColorValue;
  
  @HiveField(5)
  double lineHeight;
  
  @HiveField(6)
  double letterSpacing;
  
  @HiveField(7)
  double wordSpacing;
  
  @HiveField(8)
  EdgeInsets padding;
  
  @HiveField(9)
  TextAlign textAlign;

  Color get bgColor => Color(bgColorValue);
  Color get textColor => Color(textColorValue);
  
  set bgColor(Color color) {
    bgColorValue = color.value;
  }
  
  set textColor(Color color) {
    textColorValue = color.value;
  }

  static const List<String> availableFonts = [
    'NotoSans',
    'Roboto',
    'OpenSans',
  ];

  ReaderTheme({
    this.fontSize = 16.0,
    this.fontFamily = 'NotoSans',
    this.darkMode = false,
    this.bgColorValue = 0xFFFFFFFF,
    this.textColorValue = 0xFF000000,
    this.lineHeight = 1.5,
    this.letterSpacing = 0.0,
    this.wordSpacing = 0.0,
    this.padding = const EdgeInsets.all(16.0),
    this.textAlign = TextAlign.justify,
  });

  ReaderTheme copyWith({
    double? fontSize,
    String? fontFamily,
    bool? darkMode,
    int? bgColorValue,
    int? textColorValue,
    double? lineHeight,
    double? letterSpacing,
    double? wordSpacing,
    EdgeInsets? padding,
    TextAlign? textAlign,
  }) {
    return ReaderTheme(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      darkMode: darkMode ?? this.darkMode,
      bgColorValue: bgColorValue ?? this.bgColorValue,
      textColorValue: textColorValue ?? this.textColorValue,
      lineHeight: lineHeight ?? this.lineHeight,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      wordSpacing: wordSpacing ?? this.wordSpacing,
      padding: padding ?? this.padding,
      textAlign: textAlign ?? this.textAlign,
    );
  }

  TextStyle get textStyle => TextStyle(
        fontSize: fontSize,
        fontFamily: fontFamily,
        color: textColor,
        height: lineHeight,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
      );

  bool get isValidFontSize => fontSize >= 12.0 && fontSize <= 32.0;

  void updateFromSystemTheme(bool isDarkMode) {
    darkMode = isDarkMode;
    if (isDarkMode) {
      bgColorValue = 0xFF121212;
      textColorValue = 0xFFE0E0E0;
    } else {
      bgColorValue = 0xFFFFFFFF;
      textColorValue = 0xFF000000;
    }
  }

  @override
  String toString() {
    return 'ReaderTheme(fontSize: $fontSize, fontFamily: $fontFamily, darkMode: $darkMode)';
  }
}