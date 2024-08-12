// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceAdapter extends TypeAdapter<Attendance> {
  @override
  final int typeId = 0;

  @override
  Attendance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Attendance(
      admNumber: fields[0] as String,
      date: fields[1] as DateTime,
      status: fields[2] as String,
      lateTime: fields[3] as String?,
      period: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Attendance obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.admNumber)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.lateTime)
      ..writeByte(4)
      ..write(obj.period);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
