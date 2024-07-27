import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:week7_institute_project_2/generated/l10n.dart';
import 'package:week7_institute_project_2/models/employee.dart';
import 'package:week7_institute_project_2/screens/add_students_screen.dart';
import '../models/student.dart';
import 'student_details_screen.dart';

class StudentsScreen extends StatefulWidget {
  final Employee currentUser;

  const StudentsScreen({super.key, required this.currentUser});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  String _searchQuery = '';

  void _markStudentAsDeleted(String id) async {
    await FirebaseFirestore.instance
        .collection('students')
        .doc(id)
        .update({'isDeleted': true});
    setState(() {});
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

  Future<double> _calculateBalance(Student student) async {
    double collectedFee = await _calculateCollectedFee(student.admNumber);
    return (student.courseFee ?? 0) - collectedFee;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).Students),
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

                if (students.isEmpty) {
                  return const Center(child: Text('No students yet'));
                }

                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
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
                                builder: (context) =>
                                    StudentDetailsScreen(student: student),
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
                                        backgroundImage:
                                            student.profilePicture != null
                                                ? NetworkImage(
                                                    student.profilePicture!)
                                                : null,
                                        child: student.profilePicture == null
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
                                        onPressed: () => _markStudentAsDeleted(
                                            student.admNumber),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddStudentScreen()),
        ),
        tooltip: 'Add Student',
        child: const Icon(Icons.add),
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
