// ignore_for_file: unrelated_type_equality_checks

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:week7_institute_project_2/models/employee.dart';
import 'screens/add_employee_screen.dart';

class UsersPanel extends StatefulWidget {
  const UsersPanel({super.key});

  @override
  State<UsersPanel> createState() => _UsersPanelState();
}

class _UsersPanelState extends State<UsersPanel> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _deleteUser(String empNumber) async {
    // Delete from Firestore
    await _firestore.collection('employees').doc(empNumber).delete();

    // Delete from Hive
    var employeesBox = Hive.box<Employee>('employees');
    var employeeToDelete =
        employeesBox.values.firstWhere((e) => e.empNumber == empNumber);
    employeeToDelete.delete();

    setState(() {});
  }

  void _resetPassword(String id) {
    showDialog(
      context: context,
      builder: (context) {
        final formKey = GlobalKey<FormState>();
        String newPassword = '';

        return AlertDialog(
          title: const Text('Reset Password'),
          content: Form(
            key: formKey,
            child: TextFormField(
              decoration: const InputDecoration(labelText: 'New Password'),
              validator: (value) => value!.isEmpty ? 'Required' : null,
              onSaved: (value) => newPassword = value!,
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Reset'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  final navigator = Navigator.of(context);
                  await _firestore
                      .collection('employees')
                      .doc(id)
                      .update({'password': newPassword});
                  navigator.pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _updateUser(String id, Employee updatedEmployee) async {
    await _firestore
        .collection('employees')
        .doc(id)
        .update(updatedEmployee.toFirestore());

    // Update Hive
    var employeesBox = Hive.box<Employee>('employees');
    employeesBox.put(id, updatedEmployee);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncData,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('employees').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching users'));
          }

          final employees = snapshot.data!.docs.map((doc) {
            return Employee.fromFirestore(doc);
          }).toList();

          if (employees.isEmpty) {
            return const Center(child: Text('No users yet'));
          }

          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final employee = employees[index];
              return ListTile(
                title: Text(employee.name),
                subtitle: Text('Role: ${employee.role}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: employee.role,
                      items: ['Admin', 'User', 'General'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          employee.role = newValue;
                          _updateUser(employee.empNumber, employee);
                        }
                      },
                    ),
                    Switch(
                      value: employee.isActive,
                      onChanged: (bool value) {
                        employee.isActive = value;
                        _updateUser(employee.empNumber, employee);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.lock_reset),
                      onPressed: () => _resetPassword(employee.empNumber),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteUser(employee.empNumber),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddEmployeeScreen(),
          ),
        ),
        tooltip: 'Add User',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _syncData() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      var employeesBox = Hive.box<Employee>('employees');
      var employeesCollection =
          FirebaseFirestore.instance.collection('employees');

      // Push local changes to Firebase if not already existing
      for (var employee in employeesBox.values) {
        var docSnapshot =
            await employeesCollection.doc(employee.empNumber).get();
        if (!docSnapshot.exists) {
          await employeesCollection
              .doc(employee.empNumber)
              .set(employee.toFirestore());
        }
      }

      employeesBox.clear(); // Clear the local data after syncing
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
}
