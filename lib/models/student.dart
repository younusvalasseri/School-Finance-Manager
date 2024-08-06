import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'student.g.dart';

@HiveType(typeId: 1)
class Student {
  @HiveField(0)
  late String admNumber;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String fatherPhone;

  @HiveField(3)
  late String motherPhone;

  @HiveField(4)
  late String studentPhone;

  @HiveField(5)
  late String course;

  @HiveField(6)
  late String batch;

  @HiveField(7)
  late String address;

  @HiveField(8)
  String? profilePicture;

  @HiveField(9)
  double? courseFee = 0;

  @HiveField(10)
  bool isDeleted = false; // Added field

  @HiveField(11)
  String? classTeacher; // Added field

  Student({
    required this.admNumber,
    required this.name,
    required this.fatherPhone,
    required this.motherPhone,
    required this.studentPhone,
    required this.course,
    required this.batch,
    required this.address,
    this.profilePicture,
    this.courseFee,
    this.isDeleted = false,
    this.classTeacher,
  });

  // Convert a Firestore DocumentSnapshot into a Student object
  factory Student.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Student(
      admNumber: data['admNumber'] ?? '',
      name: data['name'] ?? '',
      fatherPhone: data['fatherPhone'] ?? '',
      motherPhone: data['motherPhone'] ?? '',
      studentPhone: data['studentPhone'] ?? '',
      course: data['course'] ?? '',
      batch: data['batch'] ?? '',
      address: data['address'] ?? '',
      profilePicture: data['profilePicture'],
      courseFee: data['courseFee']?.toDouble() ?? 0.0,
      isDeleted: data['isDeleted'] ?? false,
      classTeacher: data['classTeacher'],
    );
  }

  // Convert a Student object into a Firestore Document
  Map<String, dynamic> toFirestore() {
    return {
      'admNumber': admNumber,
      'name': name,
      'fatherPhone': fatherPhone,
      'motherPhone': motherPhone,
      'studentPhone': studentPhone,
      'course': course,
      'batch': batch,
      'address': address,
      'profilePicture': profilePicture,
      'courseFee': courseFee,
      'isDeleted': isDeleted,
      'classTeacher': classTeacher,
    };
  }
}
