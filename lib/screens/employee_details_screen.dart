import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/employee.dart';
import 'employee_salary_details.dart';

class EmployeeDetailsScreen extends StatefulWidget {
  final Employee employee;
  final Employee currentUser;

  const EmployeeDetailsScreen({
    super.key,
    required this.employee,
    required this.currentUser,
  });

  @override
  _EmployeeDetailsScreenState createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen> {
  late Employee _employee;
  final TextEditingController _previousSalaryController =
      TextEditingController();
  final TextEditingController _currentSalaryController =
      TextEditingController();
  final NumberFormat _numberFormat = NumberFormat('#,##0.##');

  @override
  void initState() {
    super.initState();
    _employee = widget.employee;
    _previousSalaryController.text =
        _numberFormat.format(_employee.previousSalary ?? 0);
    _currentSalaryController.text =
        _numberFormat.format(_employee.currentSalary ?? 0);
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final ScaffoldMessengerState scaffoldMessenger =
          ScaffoldMessenger.of(context);
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures/${_employee.empNumber}');
        await storageRef.putFile(File(image.path));
        final downloadUrl = await storageRef.getDownloadURL();

        setState(() {
          _employee.profilePicture = downloadUrl;
        });
        await _updateEmployee();
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
  }

  Future<void> _deleteProfilePicture() async {
    final ScaffoldMessengerState scaffoldMessenger =
        ScaffoldMessenger.of(context);
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures/${_employee.empNumber}');
      await storageRef.delete();

      setState(() {
        _employee.profilePicture = null;
      });
      await _updateEmployee();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error deleting image: $e')),
      );
    }
  }

  Future<void> _updateEmployee() async {
    await FirebaseFirestore.instance
        .collection('employees')
        .doc(_employee.empNumber)
        .update(_employee.toFirestore());
  }

  Future<void> _saveSalaries() async {
    final ScaffoldMessengerState scaffoldMessenger =
        ScaffoldMessenger.of(context);
    if (widget.currentUser.username == 'admin') {
      _employee.previousSalary =
          double.tryParse(_previousSalaryController.text.replaceAll(',', '')) ??
              0.00;
      _employee.currentSalary =
          double.tryParse(_currentSalaryController.text.replaceAll(',', '')) ??
              0.00;
      await _updateEmployee();
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Salaries updated successfully')),
      );
    }
  }

  @override
  void dispose() {
    _previousSalaryController.dispose();
    _currentSalaryController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone dialer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_employee.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: _employee.profilePicture != null
                        ? NetworkImage(_employee.profilePicture!)
                        : null,
                    child: _employee.profilePicture == null
                        ? const Icon(Icons.add_a_photo, size: 40)
                        : null,
                  ),
                ),
                if (_employee.profilePicture != null)
                  Positioned(
                    right: -10,
                    top: -10,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: _deleteProfilePicture,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _employee.name,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoTile('Position', _employee.position),
            _buildPhoneTile('Phone', _employee.phone),
            _buildInfoTile('Address', _employee.address),
            if (widget.currentUser.username == 'admin') ...[
              _buildEditableTile('Previous Salary', _previousSalaryController),
              _buildEditableTile('Current Salary', _currentSalaryController),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _saveSalaries,
                    child: const Text('Save Salaries'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EmployeeSalaryDetails(employee: _employee),
                        ),
                      );
                    },
                    child: const Text('Salary Transactions'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneTile(String label, String phone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _makePhoneCall(phone),
              child: Text(
                phone,
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableTile(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: const [],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
