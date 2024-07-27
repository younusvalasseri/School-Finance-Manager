import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';
import '../models/courses.dart';
import '../models/employee.dart';

class StudentsPerCourse extends StatefulWidget {
  final Employee currentUser;

  const StudentsPerCourse({super.key, required this.currentUser});

  @override
  // ignore: library_private_types_in_public_api
  _StudentsPerCourseState createState() => _StudentsPerCourseState();
}

class _StudentsPerCourseState extends State<StudentsPerCourse> {
  String _selectedCourse = 'All';
  String _selectedBatch = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students per Course'),
      ),
      body: Column(
        children: [
          _buildCourseDropdown(),
          _buildBatchDropdown(),
          Expanded(child: _buildStudentList()),
        ],
      ),
    );
  }

  Widget _buildCourseDropdown() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('courses').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }

          List<DropdownMenuItem<String>> items = [
            const DropdownMenuItem(
              value: 'All',
              child: Text('All'),
            ),
            ...snapshot.data!.docs.map((doc) {
              final course = Courses.fromFirestore(doc);
              return DropdownMenuItem<String>(
                value: course.courseName,
                child: Text(course.courseName ?? 'No name'),
              );
            }),
          ];

          return DropdownButtonFormField<String>(
            value: _selectedCourse,
            decoration: const InputDecoration(
              labelText: 'Select Course',
              border: OutlineInputBorder(),
            ),
            items: items,
            onChanged: (String? newValue) {
              setState(() {
                _selectedCourse = newValue!;
                _selectedBatch =
                    'All'; // Reset batch filter when course changes
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildBatchDropdown() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('students').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }

          List<String> batches = _selectedCourse == 'All'
              ? snapshot.data!.docs
                  .map((doc) => Student.fromFirestore(doc).batch)
                  .toSet()
                  .toList()
              : snapshot.data!.docs
                  .where((doc) =>
                      Student.fromFirestore(doc).course == _selectedCourse)
                  .map((doc) => Student.fromFirestore(doc).batch)
                  .toSet()
                  .toList();

          batches.sort();

          List<DropdownMenuItem<String>> items = [
            const DropdownMenuItem(
              value: 'All',
              child: Text('All'),
            ),
            ...batches.map((batch) {
              return DropdownMenuItem<String>(
                value: batch,
                child: Text(batch),
              );
            }),
          ];

          return DropdownButtonFormField<String>(
            value: _selectedBatch,
            decoration: const InputDecoration(
              labelText: 'Select Batch',
              border: OutlineInputBorder(),
            ),
            items: items,
            onChanged: (String? newValue) {
              setState(() {
                _selectedBatch = newValue!;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildStudentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('students').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        List<Student> students;

        if (widget.currentUser.username == 'admin') {
          students = _selectedCourse == 'All'
              ? snapshot.data!.docs
                  .map((doc) => Student.fromFirestore(doc))
                  .toList()
              : snapshot.data!.docs
                  .map((doc) => Student.fromFirestore(doc))
                  .where((student) => student.course == _selectedCourse)
                  .toList();
        } else {
          students = _selectedCourse == 'All'
              ? snapshot.data!.docs
                  .map((doc) => Student.fromFirestore(doc))
                  .where((student) => !student.isDeleted)
                  .toList()
              : snapshot.data!.docs
                  .map((doc) => Student.fromFirestore(doc))
                  .where((student) =>
                      student.course == _selectedCourse && !student.isDeleted)
                  .toList();
        }

        if (_selectedBatch != 'All') {
          students = students
              .where((student) => student.batch == _selectedBatch)
              .toList();
        }

        if (students.isEmpty) {
          return const Center(child: Text('No students found'));
        }

        return ListView.builder(
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: student.profilePicture != null
                    ? NetworkImage(student.profilePicture!)
                    : null,
                child: student.profilePicture == null
                    ? Text(student.name[0])
                    : null,
              ),
              title: Text(student.name),
              subtitle:
                  Text('Course: ${student.course}\nBatch: ${student.batch}'),
            );
          },
        );
      },
    );
  }
}
