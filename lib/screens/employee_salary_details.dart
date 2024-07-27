import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/account_transaction.dart'; // Import the existing model
import '../models/employee.dart';

class EmployeeSalaryDetails extends StatelessWidget {
  final Employee employee;

  const EmployeeSalaryDetails({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    final transactionsRef =
        FirebaseFirestore.instance.collection('transaction');

    return Scaffold(
      appBar: AppBar(
        title: Text('${employee.name} - Salary Transactions'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: transactionsRef
            .where('employeeId', isEqualTo: employee.empNumber)
            .where('mainCategory', isEqualTo: 'Salary')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading transactions'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No salary transactions found'));
          }

          final transactions = snapshot.data!.docs
              .map((doc) => AccountTransaction.fromFirestore(doc))
              .toList();

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(transaction.mainCategory),
                  subtitle: Text(
                    'Date: ${transaction.entryDate.toLocal().toString().split(' ')[0]}',
                  ),
                  trailing: Text(
                    '₹ ${transaction.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
