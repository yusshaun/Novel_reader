// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reader_theme.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReaderThemeAdapter extends TypeAdapter<ReaderTheme> {
  @override
  final int typeId = 2;

  @override
  ReaderTheme read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReaderTheme(
      fontSize: fields[0] as double,
      fontFamily: fields[1] as String,
      darkMode: fields[2] as bool,
      bgColorValue: fields[3] as int,
      textColorValue: fields[4] as int,
      lineHeight: fields[5] as double,
      letterSpacing: fields[6] as double,
      wordSpacing: fields[7] as double,
      padding: fields[8] as EdgeInsets,
      textAlign: fields[9] as TextAlign,
    );
  }

  @override
  void write(BinaryWriter writer, ReaderTheme obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.fontSize)
      ..writeByte(1)
      ..write(obj.fontFamily)
      ..writeByte(2)
      ..write(obj.darkMode)
      ..writeByte(3)
      ..write(obj.bgColorValue)
      ..writeByte(4)
      ..write(obj.textColorValue)
      ..writeByte(5)
      ..write(obj.lineHeight)
      ..writeByte(6)
      ..write(obj.letterSpacing)
      ..writeByte(7)
      ..write(obj.wordSpacing)
      ..writeByte(8)
      ..write(obj.padding)
      ..writeByte(9)
      ..write(obj.textAlign);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReaderThemeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
