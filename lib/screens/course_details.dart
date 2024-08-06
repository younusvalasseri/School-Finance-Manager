// ignore_for_file: unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CourseDetailsScreen extends StatefulWidget {
  const CourseDetailsScreen({super.key});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  late Box<Courses> _coursesBox;

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    if (!Hive.isBoxOpen('courses')) {
      _coursesBox = await Hive.openBox<Courses>('courses');
    } else {
      _coursesBox = Hive.box<Courses>('courses');
    }
    await _syncData(); // Automatically sync data on app start
  }

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
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  final newCourse = Courses(
                    courseName: courseName,
                    courseDescription: courseDescription,
                  );

                  _addCourse(newCourse);
                  Navigator.of(context).pop(); // Close the dialog
                  setState(() {});
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
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  course.courseName = courseName;
                  course.courseDescription = courseDescription;
                  await _updateCourse(course);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
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
              onPressed: () async {
                await _deleteCourseFromFirestore(course);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addCourse(Courses course) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      // Save to Hive if no internet connection
      await _coursesBox.put(course.courseName, course);
    } else {
      // Save to Firestore if internet connection is available
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(course.courseName)
          .set(course.toFirestore());
      await _coursesBox.put(course.courseName, course);
    }
  }

  Future<void> _updateCourse(Courses course) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      // Save to Hive if no internet connection
      await _coursesBox.put(course.courseName, course);
    } else {
      // Save to Firestore if internet connection is available
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(course.courseName)
          .update(course.toFirestore());
      await _coursesBox.put(course.courseName, course);
    }
  }

  Future<void> _deleteCourseFromFirestore(Courses course) async {
    await FirebaseFirestore.instance
        .collection('courses')
        .doc(course.courseName)
        .delete();
    await _coursesBox.delete(course.courseName);
  }

  Future<void> _syncData() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      var coursesCollection = FirebaseFirestore.instance.collection('courses');

      // Sync data from Firestore to Hive
      var firestoreDocs = await coursesCollection.get();
      for (var doc in firestoreDocs.docs) {
        var course = Courses.fromFirestore(doc);
        if (!_coursesBox.containsKey(course.courseName)) {
          await _coursesBox.put(course.courseName, course);
        }
      }

      // Sync data from Hive to Firestore
      for (var course in _coursesBox.values) {
        var docSnapshot = await coursesCollection.doc(course.courseName).get();
        if (!docSnapshot.exists) {
          await coursesCollection
              .doc(course.courseName)
              .set(course.toFirestore());
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data synced to Firestore and Hive')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No internet connection')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncData,
          ),
        ],
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
