import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:week7_institute_project_2/custom_date_range_picker.dart';
import 'package:week7_institute_project_2/generated/l10n.dart';
import 'package:week7_institute_project_2/models/account_transaction.dart';
import 'package:week7_institute_project_2/models/employee.dart';
import 'package:week7_institute_project_2/screens/add_income_screen.dart';

class IncomeScreen extends StatefulWidget {
  final Employee currentUser;

  const IncomeScreen({super.key, required this.currentUser});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
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
        title: Text(S.of(context).Income),
      ),
      body: Column(
        children: [
          _buildSummary(),
          _buildDateFilter(),
          Expanded(child: _buildIncomesList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AddIncomeScreen(currentUser: widget.currentUser),
          ),
        ),
        tooltip: 'Add Income',
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
                  '${DateFormat('dd-MM-yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd-MM-yyyy').format(_selectedDateRange!.end)}',
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
              .where('category', isEqualTo: 'Incomes')
              .where('entryDate',
                  isGreaterThanOrEqualTo: _selectedDateRange!.start)
              .where('entryDate', isLessThanOrEqualTo: _selectedDateRange!.end)
              .snapshots()
          : FirebaseFirestore.instance
              .collection('transaction')
              .where('category', isEqualTo: 'Incomes')
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

        // Apply faculty-specific filtering
        if (widget.currentUser.position == 'Faculty') {
          var studentIds = snapshot.data!.docs.map((doc) {
            return doc['studentId'] as String;
          }).toList();
          filteredTransactions = filteredTransactions.where((transaction) {
            return studentIds.contains(transaction.studentId);
          }).toList();
        }

        double totalIncomes = filteredTransactions.fold(
            0,
            (accumulatedSum, transaction) =>
                accumulatedSum + transaction.amount);

        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.green[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Incomes:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '₹ ${totalIncomes.toStringAsFixed(2)}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIncomesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _selectedDateRange != null
          ? FirebaseFirestore.instance
              .collection('transaction')
              .where('category', isEqualTo: 'Incomes')
              .where('entryDate',
                  isGreaterThanOrEqualTo: _selectedDateRange!.start)
              .where('entryDate', isLessThanOrEqualTo: _selectedDateRange!.end)
              .snapshots()
          : FirebaseFirestore.instance
              .collection('transaction')
              .where('category', isEqualTo: 'Incomes')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading transactions'));
        }

        var incomeTransactions = snapshot.data!.docs.map((doc) {
          return AccountTransaction.fromFirestore(doc);
        }).toList();

        // Apply faculty-specific filtering
        if (widget.currentUser.position == 'Faculty') {
          var studentIds = snapshot.data!.docs.map((doc) {
            return doc['studentId'] as String;
          }).toList();
          incomeTransactions = incomeTransactions.where((transaction) {
            return studentIds.contains(transaction.studentId);
          }).toList();
        }

        if (incomeTransactions.isEmpty) {
          return const Center(child: Text('No income transactions yet'));
        }

        return ListView.builder(
          itemCount: incomeTransactions.length,
          itemBuilder: (context, index) {
            var transaction = incomeTransactions[index];
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
                                  builder: (context) => AddIncomeScreen(
                                    currentUser: widget.currentUser,
                                    transaction: transaction,
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
              const Text('Are you sure you want to delete this income entry?'),
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
                      .doc(transaction.journalNumber)
                      .delete();
                  Navigator.of(context).pop();
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
