import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:week7_institute_project_2/models/employee.dart';

class PasswordResetPage extends StatelessWidget {
  const PasswordResetPage({super.key});

  void _resetPassword(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final formKey = GlobalKey<FormState>();
        String username = '';
        String newPassword = '';

        Future<void> handleReset() async {
          if (formKey.currentState!.validate()) {
            formKey.currentState!.save();
            final navigator = Navigator.of(context);
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            try {
              var employeesCollection =
                  FirebaseFirestore.instance.collection('employees');
              var employeeSnapshot = await employeesCollection
                  .where('username', isEqualTo: username)
                  .limit(1)
                  .get();

              if (employeeSnapshot.docs.isEmpty) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('User not found')),
                );
                return;
              }

              var employeeDoc = employeeSnapshot.docs.first;
              await employeesCollection.doc(employeeDoc.id).update({
                'password': newPassword,
              });

              // Update Hive
              var employeesBox = Hive.box<Employee>('employees');
              var employee = employeesBox.values.firstWhereOrNull(
                (e) => e.username == username,
              );
              if (employee != null) {
                employee.password = newPassword;
                await employee.save();
              }

              navigator.pop();
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Password reset successful')),
              );
            } catch (e) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                    content: Text('Failed to reset password: ${e.toString()}')),
              );
            }
          }
        }

        return AlertDialog(
          title: const Text('Reset User Password'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => username = value!,
                  ),
                  TextFormField(
                    decoration:
                        const InputDecoration(labelText: 'New Password'),
                    obscureText: true,
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => newPassword = value!,
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
              onPressed: handleReset,
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _resetPassword(context),
          child: const Text('Reset Password'),
        ),
      ),
    );
  }
}

extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
