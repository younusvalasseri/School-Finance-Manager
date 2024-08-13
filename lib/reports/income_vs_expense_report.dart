import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/account_transaction.dart';
import '../custom_date_range_picker.dart';

class IncomeVsExpenseReport extends StatefulWidget {
  const IncomeVsExpenseReport({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _IncomeVsExpenseReportState createState() => _IncomeVsExpenseReportState();
}

class _IncomeVsExpenseReportState extends State<IncomeVsExpenseReport> {
  DateTimeRange? _selectedDateRange;
  Future<List<ChartData>>? _chartDataFuture;

  @override
  void initState() {
    super.initState();
    _chartDataFuture = _prepareChartData();
  }

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
        _chartDataFuture = _prepareChartData();
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _selectedDateRange = null;
      _chartDataFuture = _prepareChartData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Income vs Expense Report'),
      ),
      body: Column(
        children: [
          _buildDateFilter(),
          Expanded(
            child: FutureBuilder<List<ChartData>>(
              future: _chartDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error loading data'));
                } else {
                  return SfCartesianChart(
                    primaryXAxis: DateTimeAxis(
                      dateFormat: DateFormat.yMMMM(),
                      intervalType: DateTimeIntervalType.months,
                    ),
                    series: <CartesianSeries>[
                      ColumnSeries<ChartData, DateTime>(
                        name: 'Income',
                        dataSource: snapshot.data!
                            .where((data) => data.type == 'Income')
                            .toList(),
                        xValueMapper: (ChartData data, _) => data.date,
                        yValueMapper: (ChartData data, _) => data.amount,
                        dataLabelSettings: const DataLabelSettings(
                            isVisible: true), // Enable data labels
                      ),
                      ColumnSeries<ChartData, DateTime>(
                        name: 'Expense',
                        dataSource: snapshot.data!
                            .where((data) => data.type == 'Expense')
                            .toList(),
                        xValueMapper: (ChartData data, _) => data.date,
                        yValueMapper: (ChartData data, _) => data.amount,
                        dataLabelSettings: const DataLabelSettings(
                            isVisible: true), // Enable data labels
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: () => _pickDateRange(context),
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
                  onPressed: _clearDateRange,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<List<ChartData>> _prepareChartData() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('transaction')
        .where('category', whereIn: ['Incomes', 'Expense']).get();

    final transactions = querySnapshot.docs
        .map((doc) => AccountTransaction.fromFirestore(doc))
        .toList();

    final Map<DateTime, double> incomeData = {};
    final Map<DateTime, double> expenseData = {};

    for (var transaction in transactions) {
      final entryDate = transaction.entryDate;
      if (_selectedDateRange != null &&
          (entryDate.isBefore(_selectedDateRange!.start) ||
              entryDate.isAfter(_selectedDateRange!.end))) {
        continue;
      }

      final month = DateTime(entryDate.year, entryDate.month);
      if (transaction.category == 'Incomes') {
        if (incomeData.containsKey(month)) {
          incomeData[month] = incomeData[month]! + transaction.amount;
        } else {
          incomeData[month] = transaction.amount;
        }
      } else if (transaction.category == 'Expense') {
        if (expenseData.containsKey(month)) {
          expenseData[month] = expenseData[month]! + transaction.amount;
        } else {
          expenseData[month] = transaction.amount;
        }
      }
    }

    final List<ChartData> chartData = [
      ...incomeData.entries
          .map((entry) => ChartData(entry.key, entry.value, 'Income')),
      ...expenseData.entries
          .map((entry) => ChartData(entry.key, entry.value, 'Expense')),
    ];

    return chartData;
  }
}

class ChartData {
  final DateTime date;
  final double amount;
  final String type;

  ChartData(this.date, this.amount, this.type);
}
