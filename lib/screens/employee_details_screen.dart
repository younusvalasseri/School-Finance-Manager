// ignore_for_file: unrelated_type_equality_checks

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/employee.dart';
import 'employee_salary_details.dart';

class EmployeeDetailsScreen extends StatefulWidget {
  final Employee employee;
  final Employee currentUser;
  final VoidCallback onUpdate; // Add this callback

  const EmployeeDetailsScreen({
    super.key,
    required this.employee,
    required this.currentUser,
    required this.onUpdate, // Add this callback
  });

  @override
  State<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen> {
  late Employee _employee;
  final TextEditingController _previousSalaryController =
      TextEditingController();
  final TextEditingController _currentSalaryController =
      TextEditingController();
  final NumberFormat _numberFormat = NumberFormat('#,##0.##');
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _employee = widget.employee;
    _previousSalaryController.text =
        _numberFormat.format(_employee.previousSalary ?? 0);
    _currentSalaryController.text =
        _numberFormat.format(_employee.currentSalary ?? 0);

    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        syncEmployeeDataToFirestore();
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedImage =
          await picker.pickImage(source: ImageSource.gallery);

      if (pickedImage == null) {
        // User canceled the picker
        return;
      }

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedImage.path,
        aspectRatio:
            const CropAspectRatio(ratioX: 1, ratioY: 1), // Square aspect ratio
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        // Preview the image
        final result = await _showImagePreviewDialog(croppedFile.path);

        if (result == true) {
          setState(() {
            _selectedImage = File(croppedFile.path);
          });
          await _saveProfilePictureToHive();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking or cropping image: $e')),
      );
    }
  }

  Future<bool?> _showImagePreviewDialog(String imagePath) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Preview'),
          content: Image.file(File(imagePath)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveProfilePictureToHive() async {
    if (_selectedImage != null) {
      _employee.profilePicture = _selectedImage!.path;
      var employeesBox = Hive.box<Employee>('employees');
      await employeesBox.put(_employee.empNumber, _employee);
      setState(() {});
      widget.onUpdate(); // Notify the parent screen about the update
    }
  }

  Future<void> _deleteProfilePicture() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      setState(() {
        _employee.profilePicture = null;
        _selectedImage = null;
      });

      var employeesBox = Hive.box<Employee>('employees');
      await employeesBox.put(_employee.empNumber, _employee);
      widget.onUpdate(); // Notify the parent screen about the update
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error deleting image: $e')),
      );
    }
  }

  Future<void> _updateEmployeeInFirestore() async {
    await FirebaseFirestore.instance
        .collection('employees')
        .doc(_employee.empNumber)
        .update(_employee.toFirestore());
  }

  Future<void> syncEmployeeDataToFirestore() async {
    var employeesBox = Hive.box<Employee>('employees');
    for (var employee in employeesBox.values) {
      await FirebaseFirestore.instance
          .collection('employees')
          .doc(employee.empNumber)
          .set(employee.toFirestore());
    }
  }

  Future<void> _saveSalaries() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (widget.currentUser.username == 'admin') {
      _employee.previousSalary =
          double.tryParse(_previousSalaryController.text.replaceAll(',', '')) ??
              0.00;
      _employee.currentSalary =
          double.tryParse(_currentSalaryController.text.replaceAll(',', '')) ??
              0.00;

      var employeesBox = Hive.box<Employee>('employees');
      await employeesBox.put(_employee.empNumber, _employee);

      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        await _updateEmployeeInFirestore();
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Salaries updated successfully')),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
              content: Text(
                  'No internet connection. Salaries updated locally and will be synced when online.')),
        );
      }
      widget.onUpdate(); // Notify the parent screen about the update
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
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : _employee.profilePicture != null
                            ? _employee.profilePicture!.startsWith('http')
                                ? NetworkImage(_employee.profilePicture!)
                                : FileImage(File(_employee.profilePicture!))
                                    as ImageProvider
                            : null,
                    child: _employee.profilePicture == null &&
                            _selectedImage == null
                        ? const Icon(Icons.add_a_photo, size: 40)
                        : null,
                  ),
                ),
                if (_employee.profilePicture != null || _selectedImage != null)
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
            ElevatedButton(
              onPressed: _saveProfilePictureToHive,
              child: const Text('Save Image'),
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
