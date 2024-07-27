import 'package:cloud_firestore/cloud_firestore.dart';

class Courses {
  String? courseName;
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
