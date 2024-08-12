// ignore_for_file: unrelated_type_equality_checks

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:week7_institute_project_2/generated/l10n.dart';
import 'package:week7_institute_project_2/models/employee.dart';
import 'package:week7_institute_project_2/models/student.dart';
import 'package:week7_institute_project_2/screens/add_students_screen.dart';
import 'student_details_screen.dart';

class StudentsScreen extends StatefulWidget {
  final Employee currentUser;

  const StudentsScreen({super.key, required this.currentUser});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  String _searchQuery = '';
  late Box<Student> studentsBox;

  @override
  void initState() {
    super.initState();
    studentsBox = Hive.box<Student>('students');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {}); // Trigger a rebuild to reflect changes
  }

  void _softDeleteStudent(BuildContext context, Student student) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this student?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('students')
                      .doc(student.admNumber)
                      .update({'isDeleted': true});
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Student deleted')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting student: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<double> _calculateCollectedFee(String admNumber) async {
    double collectedFee = 0.0;
    final querySnapshot = await FirebaseFirestore.instance
        .collection('transaction')
        .where('mainCategory', isEqualTo: 'Student Fee')
        .where('studentId', isEqualTo: admNumber)
        .get();
    for (var doc in querySnapshot.docs) {
      collectedFee += doc['amount'].toDouble();
    }
    return collectedFee;
  }

  void _syncData() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      var studentsBox = Hive.box<Student>('students');
      var studentsCollection =
          FirebaseFirestore.instance.collection('students');

      // Push local changes to Firebase if not already existing
      for (var student in studentsBox.values) {
        var docSnapshot = await studentsCollection.doc(student.admNumber).get();
        if (!docSnapshot.exists) {
          await studentsCollection
              .doc(student.admNumber)
              .set(student.toFirestore());
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data synced to Firestore')),
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

  void _clearHiveData() async {
    var studentsBox = Hive.box<Student>('students');
    await studentsBox.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All Hive data cleared')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).Students),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncData,
          ),
          if (widget.currentUser.username == 'admin')
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: _clearHiveData,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBox(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('students').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<Student> students = snapshot.data!.docs.map((doc) {
                  return Student.fromFirestore(doc);
                }).toList();

                if (widget.currentUser.username != 'admin') {
                  students =
                      students.where((student) => !student.isDeleted).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  students = students
                      .where((student) => student.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                      .toList();
                }

                students.sort((a, b) => a.name.compareTo(b.name));

                // Merge Hive profile pictures with Firestore data
                for (var student in students) {
                  Student? hiveStudent = studentsBox.get(student.admNumber);
                  if (hiveStudent?.profilePicture != null) {
                    student.profilePicture = hiveStudent!.profilePicture;
                  }
                }

                if (students.isEmpty) {
                  return const Center(child: Text('No students yet'));
                }

                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    String? profilePicture = student.profilePicture;

                    return FutureBuilder<double>(
                      future: _calculateCollectedFee(student.admNumber),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const ListTile(
                            title: Text('Loading...'),
                          );
                        }
                        final collectedFee = snapshot.data!;
                        final balance = (student.courseFee ?? 0) - collectedFee;

                        return Card(
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentDetailsScreen(
                                  student: student,
                                  onUpdate: () =>
                                      setState(() {}), // Pass the callback
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: profilePicture != null
                                            ? FileImage(File(profilePicture))
                                            : null,
                                        child: profilePicture == null
                                            ? Text(student.name[0])
                                            : null,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(student.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        Text(student.admNumber),
                                        if (student.isDeleted)
                                          const Text(
                                            'Deleted',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Col.: ₹${collectedFee.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            color: Colors.green),
                                      ),
                                      Text(
                                        'Bal.: ₹${balance.toStringAsFixed(2)}',
                                        style:
                                            const TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 20),
                                  Column(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AddStudentScreen(
                                                      student: student),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _softDeleteStudent(
                                            context, student),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomCenter,
        child: FloatingActionButton(
          backgroundColor: Colors.amberAccent,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddStudentScreen()),
          ),
          tooltip: 'Add Student',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: const InputDecoration(
          labelText: 'Search by name',
          border: OutlineInputBorder(),
        ),
        onChanged: (query) {
          setState(() {
            _searchQuery = query;
          });
        },
      ),
    );
  }
}
