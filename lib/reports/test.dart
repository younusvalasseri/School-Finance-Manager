import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:week7_institute_project_2/models/attendance.dart';
import 'package:week7_institute_project_2/models/student.dart';
import 'package:week7_institute_project_2/models/courses.dart';

class AttendanceReport extends StatefulWidget {
  const AttendanceReport({super.key});

  @override
  State<AttendanceReport> createState() => _AttendanceReportState();
}

class _AttendanceReportState extends State<AttendanceReport> {
  String _selectedCourse = 'All';
  String _selectedBatch = 'All';
  DateTime _selectedDate = DateTime.now();
  String _selectedStatus = 'All';

  List<String> _courses = ['All'];
  List<String> _batches = ['All'];
  List<Student> _students = [];

  @override
  void initState() {
    super.initState();
    _fetchCourses();
    _fetchBatches();
    _fetchStudents(); // Initial fetch of students
  }

  Future<void> _fetchCourses() async {
    QuerySnapshot courseSnapshot =
        await FirebaseFirestore.instance.collection('courses').get();
    final courses = courseSnapshot.docs
        .map((doc) => Courses.fromFirestore(doc).courseName ?? '')
        .toSet()
        .toList();

    setState(() {
      _courses = ['All', ...courses];
      if (!_courses.contains(_selectedCourse)) {
        _selectedCourse = 'All';
      }
    });
  }

  Future<void> _fetchBatches() async {
    QuerySnapshot studentSnapshot =
        await FirebaseFirestore.instance.collection('students').get();
    final batches = studentSnapshot.docs
        .map((doc) => Student.fromFirestore(doc).batch)
        .toSet()
        .toList();

    setState(() {
      _batches = ['All', ...batches];
    });
  }

  void _fetchStudents() {
    FirebaseFirestore.instance.collection('students').get().then((snapshot) {
      final students = snapshot.docs.map((doc) {
        return Student.fromFirestore(doc);
      }).toList();

      setState(() {
        _students = students.where((student) {
          final bool matchesCourse =
              _selectedCourse == 'All' || student.course == _selectedCourse;
          final bool matchesBatch =
              _selectedBatch == 'All' || student.batch == _selectedBatch;
          return matchesCourse && matchesBatch;
        }).toList();
      });
    });
  }

  Future<List<Attendance>> _getAttendanceForStudent(Student student) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .where('admNumber', isEqualTo: student.admNumber)
        .where('date', isEqualTo: Timestamp.fromDate(_selectedDate))
        .get();

    return snapshot.docs.map((doc) {
      return Attendance.fromFirestore(doc.data());
    }).toList();
  }

  void _sendBulkWhatsAppMessage() async {
    for (var student in _students) {
      final attendances = await _getAttendanceForStudent(student);
      for (var attendance in attendances) {
        if (attendance.status != 'Present') {
          final message = attendance.status == 'Absent'
              ? 'Your son ${student.name} is absent today.'
              : 'Your son ${student.name} is late today and he entered the class at ${attendance.lateTime}.';

          _sendWhatsAppMessage(student, message);
        }
      }
    }
  }

  void _sendWhatsAppMessage(Student student, String message) async {
    const String countryCode =
        '91'; // Replace with the appropriate country code
    final String fatherPhoneNumber = '$countryCode${student.fatherPhone}';
    final String motherPhoneNumber = '$countryCode${student.motherPhone}';

    final Uri urlFather = Uri.parse(
        "https://wa.me/$fatherPhoneNumber?text=${Uri.encodeComponent(message)}");
    final Uri urlMother = Uri.parse(
        "https://wa.me/$motherPhoneNumber?text=${Uri.encodeComponent(message)}");

    if (await canLaunchUrl(urlFather)) {
      await launchUrl(urlFather, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch WhatsApp for father';
    }

    if (await canLaunchUrl(urlMother)) {
      await launchUrl(urlMother, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch WhatsApp for mother';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Report'),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: ListView.builder(
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];

                return FutureBuilder<List<Attendance>>(
                  future: _getAttendanceForStudent(student),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(
                        title: Text('Loading...'),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const ListTile(
                        title: Text('Error fetching attendance'),
                      );
                    }

                    final attendances = snapshot.data!;
                    final filteredAttendances = attendances.where((attendance) {
                      return _selectedStatus == 'All' ||
                          attendance.status == _selectedStatus;
                    }).toList();

                    if (filteredAttendances.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredAttendances.length,
                      itemBuilder: (context, index) {
                        final attendance = filteredAttendances[index];
                        return ListTile(
                          title: Text(student.name),
                          trailing: attendance.status != 'Present'
                              ? IconButton(
                                  icon: const Icon(FontAwesomeIcons.whatsapp,
                                      color: Colors.green),
                                  onPressed: () {
                                    _showWhatsAppPopup(
                                        context, student, attendance);
                                  },
                                )
                              : null,
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
        onPressed: _sendBulkWhatsAppMessage,
        tooltip: 'Send Bulk WhatsApp',
        child: const Icon(
          FontAwesomeIcons.whatsapp,
          size: 36.0,
        ),
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
                      _fetchStudents();
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
                      _fetchStudents();
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
          DropdownButton<String>(
            value: _selectedStatus,
            onChanged: (newValue) {
              setState(() {
                _selectedStatus = newValue!;
              });
            },
            items: ['All', 'Absent', 'Present', 'Late'].map((status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(status),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showWhatsAppPopup(
      BuildContext context, Student student, Attendance attendance) {
    TextEditingController messageController = TextEditingController(
      text: attendance.status == 'Absent'
          ? 'Your son ${student.name} is absent today.'
          : 'Your son ${student.name} is late today and he entered the class at ${attendance.lateTime}.',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Send WhatsApp Message'),
          content: TextField(
            controller: messageController,
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _sendWhatsAppMessage(student, messageController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
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
        _selectedDate = picked;
        _fetchStudents();
      });
    }
  }
}
