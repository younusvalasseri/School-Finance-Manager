import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/account_transaction.dart';
import '../custom_date_range_picker.dart';

class TransactionsPerCategory extends StatefulWidget {
  const TransactionsPerCategory({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TransactionsPerCategoryState createState() =>
      _TransactionsPerCategoryState();
}

class _TransactionsPerCategoryState extends State<TransactionsPerCategory> {
  String _selectedCategory = 'All';
  DateTimeRange? _selectedDateRange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions per Category'),
      ),
      body: Column(
        children: [
          _buildCategoryDropdown(),
          _buildDateFilter(),
          Expanded(child: _buildTransactionList()),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        List<String> categories = snapshot.data!.docs
            .map((doc) => AccountTransaction.fromFirestore(doc).mainCategory)
            .toSet()
            .toList()
          ..sort();

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Select Category',
              border: OutlineInputBorder(),
            ),
            items: ['All', ...categories].map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedCategory = newValue!;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildDateFilter() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: () async {
              DateTimeRange? picked = await showDialog<DateTimeRange>(
                context: context,
                builder: (BuildContext context) {
                  return CustomDateRangePicker(
                    initialDateRange: _selectedDateRange,
                  );
                },
              );

              if (picked != null) {
                setState(() {
                  _selectedDateRange = picked;
                });
              }
            },
            child: const Text('Select Date Range'),
          ),
          if (_selectedDateRange != null)
            Column(
              children: [
                Text(
                  '${DateFormat('dd/MMM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MMM/yyyy').format(_selectedDateRange!.end)}',
                  style: const TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _selectedDateRange = null;
                    });
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        List<AccountTransaction> transactions = snapshot.data!.docs
            .map((doc) => AccountTransaction.fromFirestore(doc))
            .toList();

        if (_selectedCategory != 'All') {
          transactions = transactions
              .where((transaction) =>
                  transaction.mainCategory == _selectedCategory)
              .toList();
        }

        if (_selectedDateRange != null) {
          transactions = transactions.where((transaction) {
            return transaction.entryDate.isAfter(_selectedDateRange!.start
                    .subtract(const Duration(days: 1))) &&
                transaction.entryDate.isBefore(
                    _selectedDateRange!.end.add(const Duration(days: 1)));
          }).toList();
        }

        if (transactions.isEmpty) {
          return const Center(child: Text('No transactions found'));
        }

        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return ListTile(
              title: Text(transaction.subCategory),
              subtitle: Text(
                  'Date: ${DateFormat('dd-MMM-yyyy').format(transaction.entryDate)}'),
              trailing: Text('₹${transaction.amount.toStringAsFixed(2)}'),
            );
          },
        );
      },
    );
  }
}
