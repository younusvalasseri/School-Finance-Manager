// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AccountTransactionAdapter extends TypeAdapter<AccountTransaction> {
  @override
  final int typeId = 3;

  @override
  AccountTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AccountTransaction(
      journalNumber: fields[0] as String,
      entryNumber: fields[1] as String,
      entryDate: fields[2] as DateTime,
      category: fields[3] as String,
      mainCategory: fields[4] as String,
      subCategory: fields[5] as String,
      amount: fields[6] as double,
      note: fields[7] as String?,
      studentId: fields[8] as String?,
      employeeId: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AccountTransaction obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.journalNumber)
      ..writeByte(1)
      ..write(obj.entryNumber)
      ..writeByte(2)
      ..write(obj.entryDate)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.mainCategory)
      ..writeByte(5)
      ..write(obj.subCategory)
      ..writeByte(6)
      ..write(obj.amount)
      ..writeByte(7)
      ..write(obj.note)
      ..writeByte(8)
      ..write(obj.studentId)
      ..writeByte(9)
      ..write(obj.employeeId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
