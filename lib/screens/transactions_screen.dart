import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:week7_institute_project_2/custom_date_range_picker.dart';
import 'package:week7_institute_project_2/generated/l10n.dart';
import 'package:week7_institute_project_2/models/employee.dart';
import '../models/account_transaction.dart';
import 'add_transaction.dart';

class TransactionsScreen extends StatefulWidget {
  final Employee currentUser;
  const TransactionsScreen({super.key, required this.currentUser});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
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
        title: Text(S.of(context).Transaction),
      ),
      body: Column(
        children: [
          _buildSummary(),
          _buildDateFilter(),
          Expanded(child: _buildList(context)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AddTransactionScreen(
                    currentUser: widget.currentUser,
                  )),
        ),
        tooltip: 'Add Transaction',
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
      stream: FirebaseFirestore.instance.collection('transaction').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var filteredExpenseTransactions = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['category'] != 'Expense') {
            return false;
          }
          if (_selectedDateRange == null) {
            return true;
          }
          final entryDate = (data['entryDate'] as Timestamp).toDate();
          return !entryDate.isBefore(_selectedDateRange!.start) &&
              !entryDate.isAfter(_selectedDateRange!.end);
        }).toList();

        var filteredIncomeTransactions = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['category'] != 'Incomes') {
            return false;
          }
          if (_selectedDateRange == null) {
            return true;
          }
          final entryDate = (data['entryDate'] as Timestamp).toDate();
          return !entryDate.isBefore(_selectedDateRange!.start) &&
              !entryDate.isAfter(_selectedDateRange!.end);
        }).toList();

        double totalExpenses = filteredExpenseTransactions.fold(
            0, (total, doc) => total + (doc['amount'] as num).toDouble());
        double totalIncomes = filteredIncomeTransactions.fold(
            0, (total, doc) => total + (doc['amount'] as num).toDouble());

        double balance = totalIncomes - totalExpenses;
        Color balanceColor =
            balance > 0 ? Colors.green[100]! : Colors.red[100]!;

        return Container(
          padding: const EdgeInsets.all(16),
          color: balanceColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'The Balance Amount:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '₹ ${balance.toStringAsFixed(2)}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('transaction').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var filteredTransactions = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (_selectedDateRange == null) {
            return true;
          }
          final entryDate = (data['entryDate'] as Timestamp).toDate();
          return !entryDate.isBefore(_selectedDateRange!.start) &&
              !entryDate.isAfter(_selectedDateRange!.end);
        }).toList();

        if (filteredTransactions.isEmpty) {
          return const Center(child: Text('No transactions yet'));
        }

        return ListView.builder(
          itemCount: filteredTransactions.length,
          itemBuilder: (context, index) {
            final doc = filteredTransactions[index];
            final transaction = AccountTransaction.fromFirestore(doc);
            bool isIncome = transaction.category == 'Incomes';
            return ListTile(
              leading: Icon(
                isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                color: isIncome ? Colors.green : Colors.red,
              ),
              title: Text(
                  '${transaction.mainCategory} - ${transaction.subCategory}'),
              subtitle: Text(
                  'Date: ${DateFormat('dd-MMM-yyyy').format(transaction.entryDate)}'),
              trailing: SizedBox(
                width: 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '₹ ${transaction.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Flexible(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddTransactionScreen(
                                  transaction: transaction,
                                  currentUser: widget.currentUser,
                                  transactionId: transaction.compositeKey,
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
          content: const Text('Are you sure you want to delete this entry?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('transaction')
                    .doc(transaction.compositeKey)
                    .delete();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
