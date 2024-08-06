// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudentAdapter extends TypeAdapter<Student> {
  @override
  final int typeId = 1;

  @override
  Student read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Student(
      admNumber: fields[0] as String,
      name: fields[1] as String,
      fatherPhone: fields[2] as String,
      motherPhone: fields[3] as String,
      studentPhone: fields[4] as String,
      course: fields[5] as String,
      batch: fields[6] as String,
      address: fields[7] as String,
      profilePicture: fields[8] as String?,
      courseFee: fields[9] as double?,
      isDeleted: fields[10] as bool,
      classTeacher: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Student obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.admNumber)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.fatherPhone)
      ..writeByte(3)
      ..write(obj.motherPhone)
      ..writeByte(4)
      ..write(obj.studentPhone)
      ..writeByte(5)
      ..write(obj.course)
      ..writeByte(6)
      ..write(obj.batch)
      ..writeByte(7)
      ..write(obj.address)
      ..writeByte(8)
      ..write(obj.profilePicture)
      ..writeByte(9)
      ..write(obj.courseFee)
      ..writeByte(10)
      ..write(obj.isDeleted)
      ..writeByte(11)
      ..write(obj.classTeacher);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
