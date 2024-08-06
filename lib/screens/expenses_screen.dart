import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:week7_institute_project_2/custom_date_range_picker.dart';
import 'package:week7_institute_project_2/generated/l10n.dart';
import 'package:week7_institute_project_2/models/employee.dart';
import '../models/account_transaction.dart';
import 'add_expenses_screen.dart';

class ExpensesScreen extends StatefulWidget {
  final Employee currentUser;
  const ExpensesScreen({super.key, required this.currentUser});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  DateTimeRange? _selectedDateRange;

  void _pickDateRange(BuildContext context) async {
    DateTimeRange? picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (BuildContext context) {
        return CustomDateRangePicker(initialDateRange: _selectedDateRange);
      },
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _selectedDateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).Expenses),
      ),
      body: Column(
        children: [
          _buildSummary(),
          _buildDateFilter(),
          Expanded(child: _buildExpensesList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AddExpensesScreen(currentUser: widget.currentUser),
          ),
        ),
        tooltip: 'Add Expense',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDateFilter() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () => _pickDateRange(context),
            child: const Text('Select Date Range'),
          ),
          if (_selectedDateRange != null)
            Wrap(
              spacing: 8.0,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${DateFormat('dd/MMM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MMM/yyyy').format(_selectedDateRange!.end)}',
                  style: const TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearDateRange,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: _selectedDateRange != null
          ? FirebaseFirestore.instance
              .collection('transaction')
              .where('category', isEqualTo: 'Expense')
              .where('entryDate',
                  isGreaterThanOrEqualTo: _selectedDateRange!.start)
              .where('entryDate', isLessThanOrEqualTo: _selectedDateRange!.end)
              .snapshots()
          : FirebaseFirestore.instance
              .collection('transaction')
              .where('category', isEqualTo: 'Expense')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading transactions'));
        }

        var filteredTransactions = snapshot.data!.docs.map((doc) {
          return AccountTransaction.fromFirestore(doc);
        }).toList();

        double totalExpenses = filteredTransactions.fold(
            0, (total, transaction) => total + transaction.amount);

        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.red[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Expenses:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '₹ ${totalExpenses.toStringAsFixed(2)}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpensesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _selectedDateRange != null
          ? FirebaseFirestore.instance
              .collection('transaction')
              .where('category', isEqualTo: 'Expense')
              .where('entryDate',
                  isGreaterThanOrEqualTo: _selectedDateRange!.start)
              .where('entryDate', isLessThanOrEqualTo: _selectedDateRange!.end)
              .snapshots()
          : FirebaseFirestore.instance
              .collection('transaction')
              .where('category', isEqualTo: 'Expense')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading transactions'));
        }

        var expenseTransactions = snapshot.data!.docs.map((doc) {
          return AccountTransaction.fromFirestore(doc);
        }).toList();

        if (expenseTransactions.isEmpty) {
          return const Center(child: Text('No Expense transactions yet'));
        }

        return ListView.builder(
          itemCount: expenseTransactions.length,
          itemBuilder: (context, index) {
            var transaction = expenseTransactions[index];
            return Card(
              margin:
                  const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${transaction.mainCategory} - ${transaction.subCategory}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Date: ${DateFormat('dd-MMM-yyyy').format(transaction.entryDate)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '₹ ${transaction.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddExpensesScreen(
                                    currentUser: widget.currentUser,
                                    transaction: transaction,
                                    transactionId: transaction.compositeKey,
                                    // index: index, // Removed index as it's not needed in Firestore
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  _deleteTransaction(context, transaction),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteTransaction(
      BuildContext context, AccountTransaction transaction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content:
              const Text('Are you sure you want to delete this expense entry?'),
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
                      .collection('transaction')
                      .doc(transaction.compositeKey)
                      .delete();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }

                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Transaction deleted')),
                  );
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Error deleting transaction: $e')),
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
