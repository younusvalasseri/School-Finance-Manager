import 'package:flutter/material.dart';
import 'package:week7_institute_project_2/models/employee.dart';
import 'package:week7_institute_project_2/screens/categories_screen.dart';
import 'package:week7_institute_project_2/password_reset_page.dart';
import 'package:week7_institute_project_2/users_panel.dart';
import 'course_details.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key, required Employee currentUser});

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
                    bottomRight: Radius.circular(20),
                  ),
                ),
                height: 150,
              ),
              Positioned(
                top: 40,
                left: 0,
                right: 0,
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: const Text('Admin Panel'),
                  centerTitle: true,
                  automaticallyImplyLeading: true,
                ),
              ),
            ],
          ),
          // const SizedBox(height: 50),
          Expanded(child: _buildList(context)),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildCard(
            context,
            'User\'s Panel',
            Icons.people,
            const UsersPanel(), // Navigate to UsersPanel
          ),
          const SizedBox(height: 16),
          _buildCard(
            context,
            'Password Reset',
            Icons.lock_reset,
            const PasswordResetPage(), // Navigate to PasswordResetPage
          ),
          const SizedBox(height: 16),
          _buildCard(
            context,
            'Categories',
            Icons.category,
            const CategoriesScreen(), // Navigate to CategoriesScreen
          ),
          const SizedBox(height: 16),
          _buildCard(
            context,
            'Courses',
            Icons.school,
            const CourseDetailsScreen(),
          ),
          // Add other cards similarly
        ],
      ),
    );
  }

  Widget _buildCard(
      BuildContext context, String title, IconData icon, Widget screen) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => screen));
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 30, color: Colors.blueAccent),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
