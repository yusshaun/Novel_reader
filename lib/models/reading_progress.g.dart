// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReadingProgressAdapter extends TypeAdapter<ReadingProgress> {
  @override
  final int typeId = 3;

  @override
  ReadingProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReadingProgress(
      id: fields[0] as String,
      bookId: fields[1] as String,
      lastPage: fields[2] as int,
      scrollPosition: fields[3] as double,
      timestamp: fields[4] as DateTime,
      chapterId: fields[5] as String?,
      chapterTitle: fields[6] as String?,
      progressPercentage: fields[7] as double,
      totalPages: fields[8] as int,
      readingTime: fields[9] as Duration,
      lastReadText: fields[10] as String?,
      isSynced: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ReadingProgress obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.bookId)
      ..writeByte(2)
      ..write(obj.lastPage)
      ..writeByte(3)
      ..write(obj.scrollPosition)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.chapterId)
      ..writeByte(6)
      ..write(obj.chapterTitle)
      ..writeByte(7)
      ..write(obj.progressPercentage)
      ..writeByte(8)
      ..write(obj.totalPages)
      ..writeByte(9)
      ..write(obj.readingTime)
      ..writeByte(10)
      ..write(obj.lastReadText)
      ..writeByte(11)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}