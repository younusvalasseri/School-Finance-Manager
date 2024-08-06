// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'courses.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CoursesAdapter extends TypeAdapter<Courses> {
  @override
  final int typeId = 5;

  @override
  Courses read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Courses(
      courseName: fields[0] as String?,
      courseDescription: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Courses obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.courseName)
      ..writeByte(1)
      ..write(obj.courseDescription);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoursesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
