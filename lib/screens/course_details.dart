import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CourseDetailsScreen extends StatefulWidget {
  const CourseDetailsScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CourseDetailsScreenState createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  void _showAddCourseDialog() {
    final formKey = GlobalKey<FormState>();
    String courseName = '';
    String courseDescription = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Course'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Course Name'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => courseName = value!,
                  ),
                  TextFormField(
                    decoration:
                        const InputDecoration(labelText: 'Course Description'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => courseDescription = value!,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  final newCourse = Courses(
                    courseName: courseName,
                    courseDescription: courseDescription,
                  );

                  _addCourse(newCourse);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditCourseDialog(Courses course) {
    final formKey = GlobalKey<FormState>();
    String courseName = course.courseName ?? '';
    String courseDescription = course.courseDescription ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Course'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: courseName,
                    decoration: const InputDecoration(labelText: 'Course Name'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => courseName = value!,
                  ),
                  TextFormField(
                    initialValue: courseDescription,
                    decoration:
                        const InputDecoration(labelText: 'Course Description'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => courseDescription = value!,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  course.courseName = courseName;
                  course.courseDescription = courseDescription;
                  _updateCourse(course);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteCourse(Courses course) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this course?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                _deleteCourseFromFirestore(course);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addCourse(Courses course) async {
    await FirebaseFirestore.instance
        .collection('courses')
        .add(course.toFirestore());
  }

  Future<void> _updateCourse(Courses course) async {
    await FirebaseFirestore.instance
        .collection('courses')
        .doc(course.id)
        .update(course.toFirestore());
  }

  Future<void> _deleteCourseFromFirestore(Courses course) async {
    await FirebaseFirestore.instance
        .collection('courses')
        .doc(course.id)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('courses').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final courses = snapshot.data!.docs
              .map((doc) => Courses.fromFirestore(doc))
              .toList();

          if (courses.isEmpty) {
            return const Center(child: Text('No courses yet'));
          }

          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return ListTile(
                title: Text(course.courseName ?? 'No name'),
                subtitle: Text(course.courseDescription ?? 'No description'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditCourseDialog(course),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteCourse(course),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCourseDialog,
        tooltip: 'Add Course',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Firestore model for Courses
class Courses {
  String? id; // Document ID
  String? courseName;
  String? courseDescription;

  Courses({
    this.id,
    this.courseName,
    this.courseDescription,
  });

  // Convert a Firestore DocumentSnapshot into a Courses object
  factory Courses.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Courses(
      id: doc.id,
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
