// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmployeeAdapter extends TypeAdapter<Employee> {
  @override
  final int typeId = 2;

  @override
  Employee read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Employee(
      empNumber: fields[0] as String,
      name: fields[1] as String,
      position: fields[2] as String,
      phone: fields[3] as String,
      address: fields[4] as String,
      password: fields[5] as String?,
      role: fields[6] as String,
      isActive: fields[7] as bool,
      profilePicture: fields[8] as String?,
      username: fields[9] as String?,
      previousSalary: fields[10] as double?,
      currentSalary: fields[11] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Employee obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.empNumber)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.position)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.address)
      ..writeByte(5)
      ..write(obj.password)
      ..writeByte(6)
      ..write(obj.role)
      ..writeByte(7)
      ..write(obj.isActive)
      ..writeByte(8)
      ..write(obj.profilePicture)
      ..writeByte(9)
      ..write(obj.username)
      ..writeByte(10)
      ..write(obj.previousSalary)
      ..writeByte(11)
      ..write(obj.currentSalary);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
