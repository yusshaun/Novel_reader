// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'epub_book.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EpubBookAdapter extends TypeAdapter<EpubBook> {
  @override
  final int typeId = 0;

  @override
  EpubBook read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EpubBook(
      id: fields[0] as String,
      title: fields[1] as String,
      author: fields[2] as String,
      coverImage: fields[3] as Uint8List?,
      filePath: fields[4] as String,
      lastRead: fields[5] as DateTime,
      description: fields[6] as String?,
      genres: (fields[7] as List?)?.cast<String>(),
      publisher: fields[8] as String?,
      publishDate: fields[9] as DateTime?,
      totalPages: fields[10] as int,
      language: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EpubBook obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.author)
      ..writeByte(3)
      ..write(obj.coverImage)
      ..writeByte(4)
      ..write(obj.filePath)
      ..writeByte(5)
      ..write(obj.lastRead)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.genres)
      ..writeByte(8)
      ..write(obj.publisher)
      ..writeByte(9)
      ..write(obj.publishDate)
      ..writeByte(10)
      ..write(obj.totalPages)
      ..writeByte(11)
      ..write(obj.language);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpubBookAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}