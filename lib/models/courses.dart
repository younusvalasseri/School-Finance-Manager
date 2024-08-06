import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'courses.g.dart';

@HiveType(typeId: 5)
class Courses {
  @HiveField(0)
  String? courseName;

  @HiveField(1)
  String? courseDescription;

  Courses({
    this.courseName,
    this.courseDescription,
  });

  // Convert a Firestore DocumentSnapshot into a Courses object
  factory Courses.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Courses(
      courseName: data['courseName'],
      courseDescription: data['courseDescription'],
    );
  }

  // Convert a Courses object into a Firestore Document
  Map<String, dynamic> toFirestore() {
    return {
      'courseName': courseName,
      'courseDescription': courseDescription,
    };
  }
}
