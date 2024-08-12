import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'package:week7_institute_project_2/models/attendance.dart';
import 'package:week7_institute_project_2/models/employee.dart';
import 'package:week7_institute_project_2/models/student.dart';
import 'package:week7_institute_project_2/models/courses.dart';

class StudentsAttendanceScreen extends StatefulWidget {
  final Employee currentUser;

  const StudentsAttendanceScreen({super.key, required this.currentUser});

  @override
  State<StudentsAttendanceScreen> createState() =>
      _StudentsAttendanceScreenState();
}

class _StudentsAttendanceScreenState extends State<StudentsAttendanceScreen> {
  late Box<Student> studentsBox;
  late Box<Attendance> attendanceBox;

  String _selectedCourse = 'All';
  String _selectedBatch = 'All';
  DateTime _selectedDate = DateTime.now();
  int _selectedPeriod = 1;
  List<String> _courses = ['All'];
  List<String> _batches = ['All'];
  List<Student> filteredStudents = [];

  Map<String, bool> isPresentMap = {};
  Map<String, bool> isLateMap = {};
  Map<String, TextEditingController> lateTimeControllers = {};

  @override
  void initState() {
    super.initState();
    studentsBox = Hive.box<Student>('students');
    attendanceBox = Hive.box<Attendance>('attendance');
    _fetchCourses();
    _fetchBatches();

    // Clear the maps to ensure they start empty
    isPresentMap.clear();
    isLateMap.clear();
    lateTimeControllers.clear();
  }

  Future<void> _fetchCourses() async {
    QuerySnapshot courseSnapshot =
        await FirebaseFirestore.instance.collection('courses').get();
    List<String> courses = courseSnapshot.docs.map((doc) {
      Courses course = Courses.fromFirestore(doc);
      return course.courseName ?? '';
    }).toList();

    setState(() {
      _courses = ['All', ...courses];
    });
  }

  Future<void> _fetchBatches() async {
    QuerySnapshot studentSnapshot =
        await FirebaseFirestore.instance.collection('students').get();
    List<String> batches = studentSnapshot.docs
        .map((doc) {
          Student student = Student.fromFirestore(doc);
          return student.batch;
        })
        .toSet()
        .toList(); // Use a set to avoid duplicate batch names

    setState(() {
      _batches = ['All', ...batches];
    });
  }

  void _filterStudents(List<Student> students) {
    setState(() {
      filteredStudents = students.where((student) {
        bool matchesCourse =
            _selectedCourse == 'All' || student.course == _selectedCourse;
        bool matchesBatch =
            _selectedBatch == 'All' || student.batch == _selectedBatch;
        return matchesCourse && matchesBatch;
      }).toList();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        // Truncate the time part, keeping only the date
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _saveAllAttendance() async {
    for (String admNumber in isPresentMap.keys) {
      try {
        final student = studentsBox.values.firstWhere(
          (s) => s.admNumber == admNumber,
        );

        // Filtered check
        if ((_selectedCourse == 'All' || student.course == _selectedCourse) &&
            (_selectedBatch == 'All' || student.batch == _selectedBatch)) {
          final attendance = Attendance(
            admNumber: admNumber,
            date: _selectedDate,
            status: isPresentMap[admNumber]!
                ? (isLateMap[admNumber]! ? 'Late' : 'Present')
                : 'Absent',
            lateTime: isLateMap[admNumber]!
                ? lateTimeControllers[admNumber]!.text
                : null,
            period: _selectedPeriod,
          );

          await _saveAttendance(attendance);
        }
      } catch (e) {
        // Handle any exceptions, such as the student not being found
        print("Student not found for admission number: $admNumber");
        continue;
      }
    }
  }

  Future<void> _saveAttendance(Attendance attendance) async {
    // Truncate the time part from the date
    DateTime dateOnly = DateTime(
        attendance.date.year, attendance.date.month, attendance.date.day);

    // Save attendance with the truncated date
    await attendanceBox.put(attendance.id, attendance.copyWith(date: dateOnly));

    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      try {
        await FirebaseFirestore.instance
            .collection('attendance')
            .doc(attendance.id)
            .set(attendance.toFirestore());

        await attendanceBox.delete(attendance.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Attendance synced to Firestore')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to sync: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No internet. Attendance saved locally.')),
        );
      }
    }
  }

  Future<Attendance> _getAttendanceForStudent(Student student) async {
    // Construct the document ID or query to get the relevant attendance record
    final docId =
        '${student.admNumber}_${_selectedDate.year}_${_selectedDate.month}_${_selectedDate.day}';

    final doc = await FirebaseFirestore.instance
        .collection('attendance')
        .doc(docId)
        .get();

    // If the document exists, return the Attendance object
    if (doc.exists) {
      return Attendance.fromFirestore(doc.data() as Map<String, dynamic>);
    } else {
      // If no attendance record is found, return an 'Absent' attendance by default
      return Attendance(
        admNumber: student.admNumber,
        date: _selectedDate,
        status: 'Absent',
        lateTime: null,
        period: _selectedPeriod,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students Attendance'),
      ),
      body: Column(
        children: [
          _buildFilters(),
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

                if (_selectedCourse != 'All') {
                  students = students
                      .where((student) => student.course == _selectedCourse)
                      .toList();
                }

                if (_selectedBatch != 'All') {
                  students = students
                      .where((student) => student.batch == _selectedBatch)
                      .toList();
                }

                if (students.isEmpty) {
                  print("No students found after filtering.");
                  return const Center(child: Text('No students found'));
                }

                // No setState call here, just return the list of students
                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];

                    return FutureBuilder<Attendance>(
                      future: _getAttendanceForStudent(student),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const ListTile(
                            title: Text('Loading...'),
                          );
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return const ListTile(
                            title: Text('Error fetching attendance'),
                          );
                        }

                        final attendance = snapshot.data!;

                        // Now you pass the attendance object to the _buildAttendanceTile method
                        return _buildAttendanceTile(student, attendance);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedCourse,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCourse = newValue!;
                    });
                  },
                  items: _courses.map((course) {
                    return DropdownMenuItem<String>(
                      value: course,
                      child: Text(course),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedBatch,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedBatch = newValue!;
                    });
                  },
                  items: _batches.map((batch) {
                    return DropdownMenuItem<String>(
                      value: batch,
                      child: Text(batch),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child:
                    Text('Date: ${DateFormat.yMMMd().format(_selectedDate)}'),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Period:'),
              const SizedBox(width: 10),
              DropdownButton<int>(
                value: _selectedPeriod,
                onChanged: (newValue) {
                  setState(() {
                    _selectedPeriod = newValue!;
                  });
                },
                items: List.generate(5, (index) => index + 1).map((period) {
                  return DropdownMenuItem<int>(
                    value: period,
                    child: Text(period.toString()),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTile(Student student, Attendance attendance) {
    // Initialize the maps if not already done
    isPresentMap.putIfAbsent(student.admNumber,
        () => attendance.status == 'Present' || attendance.status == 'Late');
    isLateMap.putIfAbsent(student.admNumber, () => attendance.status == 'Late');

    bool isPresent = isPresentMap[student.admNumber]!;
    bool isLate = isLateMap[student.admNumber]!;

    // Initialize the late time controller if not already done
    lateTimeControllers.putIfAbsent(student.admNumber,
        () => TextEditingController(text: attendance.lateTime ?? ''));

    TextEditingController lateTimeController =
        lateTimeControllers[student.admNumber]!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal, // Enable horizontal scrolling
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      student.name,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(
                      height:
                          8), // Add some spacing between the rows and the button
                  ElevatedButton(
                    onPressed: () async {
                      final updatedAttendance = Attendance(
                        admNumber: student.admNumber,
                        date: _selectedDate,
                        status: isPresent
                            ? (isLate ? 'Late' : 'Present')
                            : 'Absent',
                        lateTime: isLate ? lateTimeController.text : null,
                        period: _selectedPeriod,
                      );

                      await _saveAttendance(updatedAttendance);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Attendance saved')),
                      );
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
              SizedBox(
                width: 120,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: isPresent,
                          onChanged: (value) {
                            setState(() {
                              isPresentMap[student.admNumber] = value!;
                              isPresent = value;
                              if (!isPresent) {
                                isLateMap[student.admNumber] = false;
                                isLate = false;
                              }
                            });
                          },
                        ),
                        const Text('Present'),
                      ],
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: isLate,
                          onChanged: isPresent
                              ? (value) {
                                  setState(() {
                                    isLateMap[student.admNumber] = value!;
                                    isLate = value;
                                  });
                                }
                              : null,
                        ),
                        const Text('Late'),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 150,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: !isPresent,
                          onChanged: (value) {
                            setState(() {
                              isPresentMap[student.admNumber] = !value!;
                              isPresent = !value;
                              if (!isPresent) {
                                isLateMap[student.admNumber] = false;
                                isLate = false;
                              }
                            });
                          },
                        ),
                        const Text('Absent'),
                      ],
                    ),
                    if (isLate)
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: lateTimeController,
                          decoration: const InputDecoration(
                            labelText: 'Late Time',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
