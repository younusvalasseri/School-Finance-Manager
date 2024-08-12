// ignore_for_file: unrelated_type_equality_checks

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../generated/l10n.dart';
import '../models/employee.dart';
import '../screens/add_employee_screen.dart';
import 'employee_details_screen.dart';

class EmployeesScreen extends StatefulWidget {
  final Employee currentUser;

  const EmployeesScreen({super.key, required this.currentUser});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  String _searchQuery = '';
  late Box<Employee> employeesBox;

  @override
  void initState() {
    super.initState();
    employeesBox = Hive.box<Employee>('employees');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {}); // Trigger a rebuild to reflect changes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).Employees),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncData,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _clearHiveData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBox(),
          Expanded(child: _buildEmployeeList()),
        ],
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FloatingActionButton(
            backgroundColor: Colors.amberAccent,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddEmployeeScreen(),
              ),
            ),
            tooltip: 'Add Employee',
            child: const Icon(Icons.add),
          ),
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

  Widget _buildEmployeeList() {
    final employeesRef = FirebaseFirestore.instance.collection('employees');

    return StreamBuilder<QuerySnapshot>(
      stream: employeesRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading employees'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No employees yet'));
        }

        List<Employee> employees = snapshot.data!.docs
            .map((doc) => Employee.fromFirestore(doc))
            .toList();

        if (widget.currentUser.username != 'admin') {
          employees = employees
              .where((employee) =>
                  employee.isActive && employee.name != 'Administrator')
              .toList();
        }

        if (_searchQuery.isNotEmpty) {
          employees.retainWhere((employee) =>
              employee.name.toLowerCase().contains(_searchQuery.toLowerCase()));
        }

        // Merge Hive profile pictures with Firestore data
        for (var employee in employees) {
          Employee? hiveEmployee = employeesBox.get(employee.empNumber);
          if (hiveEmployee?.profilePicture != null) {
            employee.profilePicture = hiveEmployee!.profilePicture;
          }
        }

        return ListView.builder(
          itemCount: employees.length,
          itemBuilder: (context, index) {
            final employee = employees[index];
            String? profilePicture = employee.profilePicture;

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: profilePicture != null
                    ? FileImage(File(profilePicture))
                    : null,
                child: profilePicture == null ? Text(employee.name[0]) : null,
              ),
              title: Text(employee.name),
              subtitle: employee.isActive
                  ? Text('Position: ${employee.position}')
                  : RichText(
                      text: TextSpan(
                        text: 'Position: ${employee.position} ',
                        style: DefaultTextStyle.of(context).style,
                        children: const <TextSpan>[
                          TextSpan(
                            text: '(Deleted)',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEmployeeScreen(
                          employee: employee,
                          employeeId: employee.empNumber,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _softDeleteEmployee(context, employee),
                  ),
                ],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmployeeDetailsScreen(
                    employee: employee,
                    currentUser: widget.currentUser,
                    onUpdate: () => setState(() {}), // Pass the callback
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _softDeleteEmployee(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this employee?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  await FirebaseFirestore.instance
                      .collection('employees')
                      .doc(employee.empNumber)
                      .update({'isActive': false});
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }

                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Employee deleted')),
                  );
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Error deleting employee: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
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

  void _clearHiveData() async {
    var employeesBox = Hive.box<Employee>('employees');
    await employeesBox.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All Hive data cleared')),
      );
    }
  }
}
