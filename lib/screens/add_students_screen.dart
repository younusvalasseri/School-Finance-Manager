// ignore_for_file: unrelated_type_equality_checks

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../crud_operations.dart';
import '../models/student.dart';
import '../models/courses.dart';
import '../models/employee.dart';

class AddStudentScreen extends StatefulWidget {
  final Student? student;
  final int? index;
  const AddStudentScreen({super.key, this.student, this.index});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  late String admNumber,
      name,
      course,
      batch,
      fatherPhone,
      motherPhone,
      studentPhone,
      address,
      classTeacher;
  late double courseFee;
  late List<Courses> availableCourses = [];
  late Future<Box<Courses>> _coursesBoxFuture;
  final _employeesBox = Hive.box<Employee>('employees');

  @override
  void initState() {
    super.initState();
    _coursesBoxFuture = _openCoursesBox();
    final student = widget.student;
    admNumber = student?.admNumber ?? '';
    name = student?.name ?? '';
    course = student?.course ?? '';
    batch = student?.batch ?? '';
    fatherPhone = student?.fatherPhone ?? '';
    motherPhone = student?.motherPhone ?? '';
    studentPhone = student?.studentPhone ?? '';
    address = student?.address ?? '';
    courseFee = student?.courseFee ?? 0;
    classTeacher = student?.classTeacher ?? 'Select Teacher';
  }

  Future<Box<Courses>> _openCoursesBox() async {
    var box = await Hive.openBox<Courses>('courses');
    await _fetchCourses(box);
    return box;
  }

  Future<void> _fetchCourses(Box<Courses> coursesBox) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      // Fetch courses from Firebase if connected
      var coursesCollection = FirebaseFirestore.instance.collection('courses');
      var firestoreDocs = await coursesCollection.get();
      availableCourses = firestoreDocs.docs.map((doc) {
        var course = Courses.fromFirestore(doc);
        coursesBox.put(course.courseName, course); // Sync with Hive
        return course;
      }).toList();
    } else {
      // Fetch courses from Hive if not connected
      availableCourses = coursesBox.values.toList();
    }

    // Ensure UI is updated
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student == null ? 'Add Student' : 'Edit Student'),
      ),
      body: FutureBuilder<Box<Courses>>(
        future: _coursesBoxFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (availableCourses.isEmpty) {
            return const Center(child: Text('No courses available'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    buildTextFormField(
                      initialValue: admNumber,
                      labelText: 'Admission Number',
                      onSaved: (value) => admNumber = value!,
                    ),
                    buildTextFormField(
                      initialValue: name,
                      labelText: 'Name',
                      onSaved: (value) => name = value!,
                    ),
                    buildDropdownButtonFormField(
                      labelText: 'Course',
                      value: course.isEmpty ? null : course,
                      items: availableCourses.map((Courses course) {
                        return DropdownMenuItem<String>(
                          value: course.courseName!,
                          child: Text(course.courseName ?? 'No name'),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        course = newValue!;
                      },
                      onSaved: (value) => course = value!,
                    ),
                    buildTextFormField(
                      initialValue: batch,
                      labelText: 'Batch',
                      onSaved: (value) => batch = value!,
                    ),
                    buildTextFormField(
                      initialValue: fatherPhone,
                      labelText: 'Father\'s Phone',
                      validator: (value) =>
                          value!.isEmpty ? null : _validatePhone(value),
                      onSaved: (value) => fatherPhone = value!,
                    ),
                    buildTextFormField(
                      initialValue: motherPhone,
                      labelText: 'Mother\'s Phone',
                      validator: (value) =>
                          value!.isEmpty ? null : _validatePhone(value),
                      onSaved: (value) => motherPhone = value!,
                    ),
                    buildTextFormField(
                      initialValue: studentPhone,
                      labelText: 'Student\'s Phone',
                      validator: _validatePhone,
                      onSaved: (value) => studentPhone = value!,
                    ),
                    buildTextFormField(
                      initialValue: address,
                      labelText: 'Address',
                      onSaved: (value) => address = value!,
                    ),
                    buildTextFormField(
                      initialValue: courseFee != 0 ? courseFee.toString() : '',
                      labelText: 'Course Fee',
                      keyboardType: TextInputType.number,
                      onSaved: (value) =>
                          courseFee = double.tryParse(value!) ?? 0,
                    ),
                    ValueListenableBuilder(
                      valueListenable: _employeesBox.listenable(),
                      builder: (context, Box<Employee> box, _) {
                        List<DropdownMenuItem<String>> items = [
                          const DropdownMenuItem(
                            value: 'Select Teacher',
                            child: Text('Select Teacher'),
                          ),
                          ...box.values
                              .where((employee) =>
                                  employee.position == 'Faculty' &&
                                  employee.isActive) // Filter by isActive
                              .map((employee) {
                            return DropdownMenuItem<String>(
                              value: employee.empNumber,
                              child: Text(employee.name),
                            );
                          }),
                        ];

                        if (!items.any((item) => item.value == classTeacher)) {
                          classTeacher = 'Select Teacher';
                        }

                        return buildDropdownButtonFormField(
                          labelText: 'Class Teacher',
                          value: classTeacher,
                          items: items,
                          onChanged: (String? newValue) {
                            setState(() {
                              classTeacher = newValue!;
                            });
                          },
                          onSaved: (value) => classTeacher = value!,
                          validator: (value) =>
                              value == 'Select Teacher' ? 'Required' : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveStudent,
        child: const Icon(Icons.save),
      ),
    );
  }

  Widget buildTextFormField({
    required String initialValue,
    required String labelText,
    required Function(String?) onSaved,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(labelText: labelText),
      keyboardType: keyboardType,
      validator: validator ?? (value) => value!.isEmpty ? 'Required' : null,
      onSaved: onSaved,
    );
  }

  Widget buildDropdownButtonFormField({
    required String labelText,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    Function(String?)? onSaved,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: labelText),
      items: items,
      onChanged: onChanged,
      onSaved: onSaved,
      validator: validator ?? (value) => value == null ? 'Required' : null,
    );
  }

  void _saveStudent() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newStudent = Student(
        admNumber: admNumber,
        name: name,
        course: course,
        batch: batch,
        fatherPhone: fatherPhone,
        motherPhone: motherPhone,
        studentPhone: studentPhone,
        address: address,
        courseFee: courseFee,
        classTeacher: classTeacher,
      );

      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        // Save to Hive if no internet connection
        var studentsBox = Hive.box<Student>('students');
        await studentsBox.put(newStudent.admNumber, newStudent);
      } else {
        // Save to Firestore if internet connection is available
        if (widget.student == null) {
          await CRUDOperations().createStudent(newStudent);
        } else {
          await CRUDOperations().updateStudent(admNumber, newStudent);
        }

        // Sync data to Firestore if connectivity is available
        await CRUDOperations.syncHiveDataToFirestore();
      }

      // Pop the screen after saving the data
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  String? _validatePhone(String? value) {
    final RegExp phoneExp = RegExp(r'^\d{10}$');
    if (value == null || !phoneExp.hasMatch(value)) {
      return 'Enter a valid phone number';
    }
    return null;
  }
}
