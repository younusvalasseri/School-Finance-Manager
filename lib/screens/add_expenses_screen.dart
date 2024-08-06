import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/account_transaction.dart';
import '../models/category.dart';
import '../models/student.dart';
import '../models/employee.dart';
import '../crud_operations.dart';

class AddExpensesScreen extends StatefulWidget {
  final AccountTransaction? transaction;
  final String? transactionId;
  final Employee currentUser;
  const AddExpensesScreen(
      {super.key,
      this.transaction,
      this.transactionId,
      required this.currentUser});

  @override
  State<AddExpensesScreen> createState() => _AddExpensesScreenState();
}

class _AddExpensesScreenState extends State<AddExpensesScreen> {
  final formKey = GlobalKey<FormState>();
  late String journalNumber;
  late String entryNumber;
  late DateTime entryDate;
  late String mainCategory;
  late String subCategory;
  late double amount;
  late String? note;
  late String? studentId;
  late String? employeeId;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    journalNumber = transaction?.journalNumber ?? '';
    entryNumber = transaction?.entryNumber ?? '';
    entryDate = transaction?.entryDate ?? DateTime.now();
    mainCategory = transaction?.mainCategory ?? '';
    subCategory = transaction?.subCategory ?? '';
    amount = transaction?.amount ?? 0;
    note = transaction?.note ?? '';
    studentId = transaction?.studentId;
    employeeId = transaction?.employeeId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.transaction == null ? 'Add Expense' : 'Edit Expense'),
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildTextFormField(
                labelText: 'Journal Number',
                initialValue: journalNumber,
                onSaved: (value) => journalNumber = value!,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              buildTextFormField(
                labelText: 'Entry Number',
                initialValue: entryNumber,
                onSaved: (value) => entryNumber = value!,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              buildDatePickerField(
                labelText: 'Entry Date',
                selectedDate: entryDate,
                onDateChanged: (pickedDate) {
                  if (pickedDate != null && pickedDate != entryDate) {
                    setState(() {
                      entryDate = pickedDate;
                    });
                  }
                },
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('categories')
                    .where('type', isEqualTo: 'Expense')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  return buildDropdownButtonFormField<String>(
                    labelText: 'Main Category',
                    value: mainCategory.isEmpty ? null : mainCategory,
                    items: snapshot.data!.docs.map((doc) {
                      final category = Category.fromFirestore(doc);
                      return DropdownMenuItem<String>(
                        value: category.description,
                        child: Text(category.description),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        mainCategory = newValue!;
                      });
                    },
                    validator: (value) => value == null ? 'Required' : null,
                  );
                },
              ),
              buildTextFormField(
                labelText: 'Sub Category',
                initialValue: subCategory,
                onSaved: (value) => subCategory = value!,
              ),
              buildTextFormField(
                labelText: 'Amount',
                initialValue: amount != 0 ? amount.toString() : '',
                keyboardType: TextInputType.number,
                onSaved: (value) => amount = double.tryParse(value!) ?? 0,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              buildTextFormField(
                labelText: 'Note',
                initialValue: note ?? '',
                onSaved: (value) => note = value,
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('students')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  List<Student> students = snapshot.data!.docs
                      .map((doc) => Student.fromFirestore(doc))
                      .where((student) => !student.isDeleted)
                      .toList();
                  if (widget.currentUser.position == 'Faculty') {
                    students = students
                        .where((student) =>
                            student.classTeacher ==
                            widget.currentUser.empNumber)
                        .toList();
                  }

                  List<DropdownMenuItem<String>> items = [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Select Item'),
                    ),
                    ...students.map((student) {
                      return DropdownMenuItem<String>(
                        value: student.admNumber,
                        child: Text(student.name),
                      );
                    }),
                  ];

                  if (!items.any((item) => item.value == studentId)) {
                    studentId = null;
                  }

                  return buildDropdownButtonFormField<String>(
                    labelText: 'Student',
                    value: studentId,
                    items: items,
                    onChanged: (String? newValue) {
                      setState(() {
                        studentId = newValue!;
                      });
                    },
                    onSaved: (value) => studentId = value,
                  );
                },
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('employees')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  List<Employee> employees = snapshot.data!.docs
                      .map((doc) => Employee.fromFirestore(doc))
                      .where((employee) => employee.isActive)
                      .toList();
                  List<DropdownMenuItem<String>> items = [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Select Item'),
                    ),
                    ...employees.map((employee) {
                      return DropdownMenuItem<String>(
                        value: employee.empNumber,
                        child: Text(employee.name),
                      );
                    }),
                  ];

                  if (!items.any((item) => item.value == employeeId)) {
                    employeeId = null;
                  }

                  return buildDropdownButtonFormField<String>(
                    labelText: 'Employee',
                    value: employeeId,
                    items: items,
                    onChanged: (String? newValue) {
                      setState(() {
                        employeeId = newValue!;
                      });
                    },
                    onSaved: (value) => employeeId = value,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveExpense,
        child: const Icon(Icons.save),
      ),
    );
  }

  Widget buildTextFormField({
    required String labelText,
    required String initialValue,
    required Function(String?) onSaved,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(labelText: labelText),
      keyboardType: keyboardType,
      validator: validator,
      onSaved: onSaved,
    );
  }

  Widget buildDatePickerField({
    required String labelText,
    required DateTime selectedDate,
    required Function(DateTime?) onDateChanged,
  }) {
    return InkWell(
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );
        onDateChanged(pickedDate);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: labelText),
        child: Text(
          DateFormat('yyyy-MM-dd').format(selectedDate),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget buildDropdownButtonFormField<T>({
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
      validator: validator,
    );
  }

  void _saveExpense() {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      final newTransaction = AccountTransaction(
        journalNumber: journalNumber,
        entryNumber: entryNumber,
        entryDate: entryDate,
        category: 'Expense',
        mainCategory: mainCategory,
        subCategory: subCategory,
        amount: amount,
        note: note,
        studentId: studentId,
        employeeId: employeeId,
      );

      if (widget.transaction == null) {
        CRUDOperations().createTransaction(newTransaction);
      } else {
        CRUDOperations()
            .updateTransaction(newTransaction.compositeKey, newTransaction);
      }

      Navigator.of(context).pop();
    }
  }
}
