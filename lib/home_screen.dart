import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:week7_institute_project_2/generated/l10n.dart';
import 'package:week7_institute_project_2/models/employee.dart';
import 'package:week7_institute_project_2/admin_screen.dart';
import 'package:week7_institute_project_2/screens/employees_screen.dart';
import 'package:week7_institute_project_2/screens/expenses_screen.dart';
import 'package:week7_institute_project_2/screens/income_screen.dart';
import 'package:week7_institute_project_2/screens/students_screen.dart';
import 'package:week7_institute_project_2/screens/transactions_screen.dart';

import 'screens/students_attendance.dart';

class HomeScreen extends StatefulWidget {
  final Employee currentUser;
  const HomeScreen({super.key, required this.currentUser});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20)),
                ),
                height: 150,
              ),
              Positioned(
                child: _buildHeader(),
              )
            ],
          ),
          _buildListView(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 200,
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: const Color.fromARGB(255, 214, 188, 111),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Institute of Automobile Technology',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: widget.currentUser.profilePicture != null
                          ? NetworkImage(widget.currentUser.profilePicture!)
                          : const AssetImage('assets/iat_logo.jpg')
                              as ImageProvider,
                    ),
                    const CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage('assets/iat_logo.jpg'),
                    ),
                  ],
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('transaction')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    double totalIncome = 0;
                    double totalExpense = 0;
                    for (var doc in snapshot.data!.docs) {
                      var transaction = doc.data() as Map<String, dynamic>;
                      if (transaction['category'] == 'Incomes') {
                        totalIncome += transaction['amount'];
                      } else if (transaction['category'] == 'Expense') {
                        totalExpense += transaction['amount'];
                      }
                    }
                    double balance = totalIncome - totalExpense;

                    return Column(
                      children: [
                        Text(
                          'User: ${widget.currentUser.name}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text('Total Balance: ₹ ${balance.toStringAsFixed(2)}'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListView(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildCard(
                    context,
                    S.of(context).Income,
                    Icons.arrow_upward,
                    IncomeScreen(currentUser: widget.currentUser),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildCard(
                    context,
                    S.of(context).Expenses,
                    Icons.arrow_downward,
                    ExpensesScreen(currentUser: widget.currentUser),
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildCard(
                    context,
                    S.of(context).Employees,
                    Icons.people,
                    EmployeesScreen(currentUser: widget.currentUser),
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildCard(
                    context,
                    S.of(context).Students,
                    Icons.school,
                    StudentsScreen(currentUser: widget.currentUser),
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildCard(
              context,
              S.of(context).Transaction,
              Icons.receipt_long,
              TransactionsScreen(currentUser: widget.currentUser),
              color: Colors.amber,
            ),
            const SizedBox(height: 15),
            _buildCard(
              context,
              'Students Attendance',
              Icons.calendar_today,
              StudentsAttendanceScreen(currentUser: widget.currentUser),
              color: Colors.orange,
            ),
            const SizedBox(height: 15),
            if (widget.currentUser.username == 'admin')
              _buildCard(
                context,
                S.of(context).adminPanel,
                Icons.admin_panel_settings,
                AdminScreen(currentUser: widget.currentUser),
                color: Colors.red,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String title,
    IconData icon,
    Widget screen, {
    Color color = Colors.black,
  }) {
    return Card(
      margin: const EdgeInsets.all(2.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => screen));
        },
        child: ListTile(
          leading: Icon(
            icon,
            size: 30,
            color: color,
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
