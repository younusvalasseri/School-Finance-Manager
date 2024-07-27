import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/employee.dart';

class UsersPanel extends StatefulWidget {
  const UsersPanel({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _UsersPanelState createState() => _UsersPanelState();
}

class _UsersPanelState extends State<UsersPanel> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _addUser() async {
    showDialog(
      context: context,
      builder: (context) {
        final formKey = GlobalKey<FormState>();
        String name = '';
        String position = '';
        String phone = '';
        String address = '';
        String password = '';
        String role = 'General'; // Default role
        bool isActive = true;

        return AlertDialog(
          title: const Text('Add User'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => name = value!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Position'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => position = value!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Phone'),
                    onSaved: (value) => phone = value!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Address'),
                    onSaved: (value) => address = value!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => password = value!,
                  ),
                  DropdownButtonFormField<String>(
                    value: role,
                    items: [
                      'Admin',
                      'User',
                      'General',
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      role = newValue!;
                    },
                    decoration: const InputDecoration(labelText: 'Role'),
                  ),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (bool value) {
                      isActive = value;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  final navigator = Navigator.of(context);

                  final newEmployee = Employee(
                    empNumber: '',
                    name: name,
                    position: position,
                    phone: phone,
                    address: address,
                    password: password,
                    role: role,
                    isActive: isActive,
                  );

                  await _firestore
                      .collection('employees')
                      .add(newEmployee.toFirestore());
                  navigator.pop();
                  setState(() {});
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteUser(String id) async {
    final navigator = Navigator.of(context);
    await _firestore.collection('employees').doc(id).delete();
    navigator.pop();
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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Panel'),
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
        onPressed: _addUser,
        tooltip: 'Add User',
        child: const Icon(Icons.add),
      ),
    );
  }
}
