import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/account_transaction.dart';
import '../models/category.dart';
import '../models/student.dart';
import '../models/employee.dart';
import '../crud_operations.dart';

class AddTransactionScreen extends StatefulWidget {
  final AccountTransaction? transaction;
  final int? index;
  final Employee currentUser;

  const AddTransactionScreen(
      {super.key, this.transaction, this.index, required this.currentUser});

  @override
  // ignore: library_private_types_in_public_api
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final formKey = GlobalKey<FormState>();
  late String journalNumber;
  late String entryNumber;
  late DateTime entryDate;
  late String category;
  late String mainCategory;
  late String subCategory;
  late double amount;
  late String? note;
  late String? studentId;
  late String? employeeId;
  final CRUDOperations crudOperations = CRUDOperations();

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    journalNumber = transaction?.journalNumber ?? '';
    entryNumber = transaction?.entryNumber ?? '';
    entryDate = transaction?.entryDate ?? DateTime.now();
    category = transaction?.category ?? 'Select Item';
    mainCategory = transaction?.mainCategory ?? 'Select Item';
    subCategory = transaction?.subCategory ?? '';
    amount = transaction?.amount ?? 0;
    note = transaction?.note ?? '';
    studentId = transaction?.studentId ?? 'Select Item';
    employeeId = transaction?.employeeId ?? 'Select Item';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null
            ? 'Add Transaction'
            : 'Edit Transaction'),
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items:
                    ['Select Item', 'Incomes', 'Expense'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    category = newValue!;
                  });
                },
                validator: (value) =>
                    value == 'Select Item' ? 'Required' : null,
              ),
              TextFormField(
                initialValue: journalNumber,
                decoration: const InputDecoration(labelText: 'Journal Number'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => journalNumber = value!,
              ),
              TextFormField(
                initialValue: entryNumber,
                decoration: const InputDecoration(labelText: 'Entry Number'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => entryNumber = value!,
              ),
              InkWell(
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: entryDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null && pickedDate != entryDate) {
                    setState(() {
                      entryDate = pickedDate;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Entry Date'),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(entryDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('categories')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  var categories = snapshot.data!.docs.map((doc) {
                    return Category.fromFirestore(doc);
                  }).toList();

                  categories.sort((a, b) => a.description
                      .toLowerCase()
                      .compareTo(b.description.toLowerCase()));

                  if (!categories.any((c) => c.description == mainCategory)) {
                    mainCategory = 'Select Item';
                  }

                  return DropdownButtonFormField<String>(
                    value: mainCategory,
                    decoration:
                        const InputDecoration(labelText: 'Main Category'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: 'Select Item',
                        child: Text('Select Item'),
                      ),
                      ...categories.map((Category category) {
                        return DropdownMenuItem<String>(
                          value: category.description,
                          child: Text(category.description),
                        );
                      }),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        mainCategory = newValue!;
                      });
                    },
                    validator: (value) =>
                        value == 'Select Item' ? 'Required' : null,
                  );
                },
              ),
              TextFormField(
                initialValue: subCategory,
                decoration: const InputDecoration(labelText: 'Sub Category'),
                onSaved: (value) => subCategory = value!,
              ),
              TextFormField(
                initialValue: amount != 0 ? amount.toString() : '',
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => amount = double.tryParse(value!) ?? 0,
              ),
              TextFormField(
                initialValue: note,
                decoration: const InputDecoration(labelText: 'Note'),
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

                  var students = snapshot.data!.docs.map((doc) {
                    return Student.fromFirestore(doc);
                  }).toList();

                  if (widget.currentUser.position == 'Faculty') {
                    students = students
                        .where((student) =>
                            student.classTeacher ==
                            widget.currentUser.empNumber)
                        .toList();
                  }

                  if (!students.any((s) => s.admNumber == studentId)) {
                    studentId = 'Select Item';
                  }

                  return DropdownButtonFormField<String>(
                    value: studentId,
                    decoration: const InputDecoration(labelText: 'Student'),
                    items: [
                      const DropdownMenuItem(
                        value: 'Select Item',
                        child: Text('Select Item'),
                      ),
                      ...students.map((Student student) {
                        return DropdownMenuItem<String>(
                          value: student.admNumber,
                          child: Text(student.name),
                        );
                      }),
                    ],
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

                  var employees = snapshot.data!.docs
                      .map((doc) {
                        return Employee.fromFirestore(doc);
                      })
                      .where((employee) => employee.isActive)
                      .toList();

                  if (!employees.any((e) => e.empNumber == employeeId)) {
                    employeeId = 'Select Item';
                  }

                  return DropdownButtonFormField<String>(
                    value: employeeId,
                    decoration: const InputDecoration(labelText: 'Employee'),
                    items: [
                      const DropdownMenuItem(
                        value: 'Select Item',
                        child: Text('Select Item'),
                      ),
                      ...employees.map((Employee employee) {
                        return DropdownMenuItem<String>(
                          value: employee.empNumber,
                          child: Text(employee.name),
                        );
                      }),
                    ],
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
        onPressed: _saveTransaction,
        child: const Icon(Icons.save),
      ),
    );
  }

  void _saveTransaction() {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      final newTransaction = AccountTransaction(
        journalNumber: journalNumber,
        entryNumber: entryNumber,
        entryDate: entryDate,
        category: category,
        mainCategory: mainCategory,
        subCategory: subCategory,
        amount: amount,
        note: note,
        studentId: studentId != 'Select Item' ? studentId : null,
        employeeId: employeeId != 'Select Item' ? employeeId : null,
      );

      if (widget.transaction == null) {
        crudOperations.createTransaction(newTransaction);
      } else {
        crudOperations.updateTransaction(
            widget.transaction!.journalNumber, newTransaction);
      }

      Navigator.of(context).pop();
    }
  }
}
