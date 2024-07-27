import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  String admNumber;
  String name;
  String fatherPhone;
  String motherPhone;
  String studentPhone;
  String course;
  String batch;
  String address;
  String? profilePicture;
  double? courseFee = 0;
  bool isDeleted = false;
  String? classTeacher;

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
