import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:week7_institute_project_2/crud_operations.dart';
import '../models/student.dart';
import '../models/courses.dart';
import '../models/employee.dart';

class AddStudentScreen extends StatefulWidget {
  final Student? student;
  final int? index;
  const AddStudentScreen({super.key, this.student, this.index});

  @override
  // ignore: library_private_types_in_public_api
  _AddStudentScreenState createState() => _AddStudentScreenState();
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

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student == null ? 'Add Student' : 'Edit Student'),
      ),
      body: Padding(
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
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('courses')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    return buildDropdownButtonFormField(
                      labelText: 'Course',
                      value: course.isEmpty ? null : course,
                      items: snapshot.data!.docs.map((doc) {
                        final course = Courses.fromFirestore(doc);
                        return DropdownMenuItem<String>(
                          value: course.courseName!,
                          child: Text(course.courseName ?? 'No name'),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          course = newValue!;
                        });
                      },
                      onSaved: (value) => course = value!,
                    );
                  },
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
                  onSaved: (value) => courseFee = double.tryParse(value!) ?? 0,
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('employees')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    final employees = snapshot.data!.docs
                        .map((doc) {
                          final employee = Employee.fromFirestore(doc);
                          return employee;
                        })
                        .where((employee) => employee.position == 'Faculty')
                        .toList();

                    return buildDropdownButtonFormField(
                      labelText: 'Class Teacher',
                      value: classTeacher,
                      items: [
                        const DropdownMenuItem(
                          value: 'Select Teacher',
                          child: Text('Select Teacher'),
                        ),
                        ...employees.map((employee) {
                          return DropdownMenuItem<String>(
                            value: employee.empNumber,
                            child: Text(employee.name),
                          );
                        }).toList(),
                      ],
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

      final navigator = Navigator.of(context); // Store the navigator context

      if (widget.student == null) {
        await CRUDOperations().createStudent(newStudent);
      } else {
        await CRUDOperations()
            .updateStudent(widget.student!.admNumber, newStudent);
      }

      navigator.pop(); // Use the stored navigator context
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
