import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:week7_institute_project_2/generated/l10n.dart';
import 'package:week7_institute_project_2/screens/add_employee_screen.dart';
import '../models/employee.dart';
import 'employee_details_screen.dart';

class EmployeesScreen extends StatefulWidget {
  final Employee currentUser;

  const EmployeesScreen({super.key, required this.currentUser});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).Employees),
      ),
      body: Column(
        children: [
          _buildSearchBox(),
          Expanded(child: _buildEmployeeList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddEmployeeScreen(),
          ),
        ),
        tooltip: 'Add Employee',
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

        return ListView.builder(
          itemCount: employees.length,
          itemBuilder: (context, index) {
            final employee = employees[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: employee.profilePicture != null
                    ? NetworkImage(employee.profilePicture!)
                    : null,
                child: employee.profilePicture == null
                    ? Text(employee.name[0])
                    : null,
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
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop();
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
}
