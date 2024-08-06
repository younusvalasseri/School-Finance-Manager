// ignore_for_file: unrelated_type_equality_checks

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:week7_institute_project_2/generated/l10n.dart';
import 'package:week7_institute_project_2/models/employee.dart';
import '../crud_operations.dart';

class AddEmployeeScreen extends StatefulWidget {
  final Employee? employee;
  final String? employeeId;
  const AddEmployeeScreen({super.key, this.employee, this.employeeId});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final formKey = GlobalKey<FormState>();
  late String empNumber, name, position, phone, address, role;
  late bool isActive;

  @override
  void initState() {
    super.initState();
    empNumber = widget.employee?.empNumber ?? '';
    name = widget.employee?.name ?? '';
    position = widget.employee?.position ?? '';
    phone = widget.employee?.phone ?? '';
    address = widget.employee?.address ?? '';
    role = widget.employee?.role ?? 'General';
    isActive = widget.employee?.isActive ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employee == null
            ? S.of(context).AddEmployee
            : S.of(context).EditEmployee),
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildTextFormField(
                  'Employee Number', empNumber, (value) => empNumber = value!),
              buildTextFormField('Name', name, (value) => name = value!),
              buildTextFormField(
                  'Position', position, (value) => position = value!),
              buildTextFormField('Phone', phone, (value) => phone = value!,
                  validator: _validatePhone),
              buildTextFormField(
                  'Address', address, (value) => address = value!,
                  isOptional: true),
              buildTextFormField('Role', role, (value) => role = value!,
                  isOptional: true),
              SwitchListTile(
                title: const Text('Active'),
                value: isActive,
                onChanged: (bool value) {
                  setState(() {
                    isActive = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveEmployee,
        child: const Icon(Icons.save),
      ),
    );
  }

  Widget buildTextFormField(
      String labelText, String initialValue, Function(String?) onSaved,
      {String? Function(String?)? validator, bool isOptional = false}) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(labelText: labelText),
      validator: validator ??
          (value) => isOptional || value!.isNotEmpty ? null : 'Required',
      onSaved: onSaved,
    );
  }

  void _saveEmployee() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      final newEmployee = Employee(
        empNumber: empNumber,
        name: name,
        position: position,
        phone: phone,
        address: address,
        role: role,
        isActive: isActive,
      );

      final navigator = Navigator.of(context);

      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        // Save to Firestore if internet connection is available
        if (widget.employee == null) {
          await CRUDOperations().createEmployee(newEmployee);
        } else {
          await CRUDOperations().updateEmployee(empNumber, newEmployee);
        }
      } else {
        // Save to Hive if no internet connection
        await Future(() async {
          var employeesBox = Hive.box<Employee>('employees');
          await employeesBox.add(newEmployee);
        });
      }

      if (mounted) {
        navigator.pop();
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
