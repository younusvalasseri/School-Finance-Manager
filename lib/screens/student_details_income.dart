import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:week7_institute_project_2/models/account_transaction.dart';
import 'package:week7_institute_project_2/models/student.dart';

class StudentDetailsIncomeScreen extends StatelessWidget {
  final Student student;

  const StudentDetailsIncomeScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final transactionsRef =
        FirebaseFirestore.instance.collection('transaction');

    return Scaffold(
      appBar: AppBar(
        title: Text('${student.name} - Transactions'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: transactionsRef
            .where('studentId', isEqualTo: student.admNumber)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading transactions'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No transactions found'));
          }

          final studentTransactions = snapshot.data!.docs
              .map((doc) => AccountTransaction.fromFirestore(doc))
              .toList();

          return ListView.builder(
            itemCount: studentTransactions.length,
            itemBuilder: (context, index) {
              final transaction = studentTransactions[index];
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
