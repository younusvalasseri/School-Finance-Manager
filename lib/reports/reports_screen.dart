import 'package:flutter/material.dart';
import 'package:week7_institute_project_2/generated/l10n.dart';
import 'package:week7_institute_project_2/models/employee.dart';
import 'income_vs_expense_report.dart';
import 'student_fee_collection_report.dart';
import 'students_collection_vs_pending_report.dart';
import 'students_per_course.dart';
import 'transactions_per_category.dart';
import 'attendance_report.dart'; // Import the attendance report screen

class ReportsScreen extends StatelessWidget {
  final Employee currentUser;
  const ReportsScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).reports),
      ),
      body: Column(
        children: [
          _buildCard(
            context,
            'Fee Collection Chart',
            Icons.bar_chart,
            const StudentsCollectionVsPendingReport(),
          ),
          _buildCard(
            context,
            'Income vs Expense Report',
            Icons.pie_chart,
            const IncomeVsExpenseReport(),
          ),
          _buildCard(
            context,
            'Fee Collection Report',
            Icons.school,
            const StudentFeeCollectionReport(),
          ),
          _buildCard(
            context,
            'Students per Course',
            Icons.people,
            StudentsPerCourse(currentUser: currentUser),
          ),
          _buildCard(
            context,
            'Transactions per Category',
            Icons.category,
            const TransactionsPerCategory(),
          ),
          _buildCard(
            context,
            'Attendance Report', // New card for Attendance Report
            Icons.event_note, // You can choose a different icon if you prefer
            const AttendanceReport(), // This should navigate to your attendance report screen
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
      BuildContext context, String title, IconData icon, Widget screen) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: ListTile(
        leading: Icon(icon, size: 48),
        title: Text(title, style: const TextStyle(fontSize: 20)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
      ),
    );
  }
}
