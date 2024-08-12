import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

part 'attendance.g.dart';

@HiveType(typeId: 0)
class Attendance extends HiveObject {
  @HiveField(0)
  String admNumber;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String status;

  @HiveField(3)
  String? lateTime;

  @HiveField(4)
  int period = 1; // Default value to avoid null issues

  Attendance({
    required this.admNumber,
    required this.date,
    required this.status,
    this.lateTime,
    required this.period,
  });
// Add the copyWith method
  Attendance copyWith({
    String? admNumber,
    DateTime? date,
    String? status,
    String? lateTime,
    int? period,
  }) {
    return Attendance(
      admNumber: admNumber ?? this.admNumber,
      date: date ?? this.date,
      status: status ?? this.status,
      lateTime: lateTime ?? this.lateTime,
      period: period ?? this.period,
    );
  }

  factory Attendance.fromFirestore(Map<String, dynamic> data) {
    return Attendance(
      admNumber: data['admNumber'],
      date: (data['date'] as Timestamp).toDate(),
      status: data['status'],
      lateTime: data['lateTime'],
      period: data['period'] ?? 1, // Default value if period is null
    );
  }

  Map<String, dynamic> toFirestore() {
    // Truncate the time part, keeping only the date
    DateTime dateOnly = DateTime(date.year, date.month, date.day);
    return {
      'admNumber': admNumber,
      'date': dateOnly,
      'status': status,
      'lateTime': lateTime,
      'period': period,
    };
  }

  String get id =>
      '${admNumber}_${DateFormat('yyyy-MM-dd').format(date)}_Period$period';
}
