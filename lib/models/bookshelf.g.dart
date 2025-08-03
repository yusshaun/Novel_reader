// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookshelf.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookShelfAdapter extends TypeAdapter<BookShelf> {
  @override
  final int typeId = 1;

  @override
  BookShelf read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookShelf(
      id: fields[0] as String,
      shelfName: fields[1] as String,
      bookIds: (fields[2] as List).cast<String>(),
      themeColorValue: fields[3] as int,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
      description: fields[6] as String?,
      isDefault: fields[7] as bool,
      coverImage: fields[8] as Uint8List?,
    );
  }

  @override
  void write(BinaryWriter writer, BookShelf obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.shelfName)
      ..writeByte(2)
      ..write(obj.bookIds)
      ..writeByte(3)
      ..write(obj.themeColorValue)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.isDefault)
      ..writeByte(8)
      ..write(obj.coverImage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookShelfAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
