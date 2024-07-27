import 'package:cloud_firestore/cloud_firestore.dart';

class Employee {
  String empNumber;
  String name;
  String position;
  String phone;
  String address;
  String? password;
  String role;
  bool isActive;
  String? profilePicture;
  String? username;
  double? previousSalary;
  double? currentSalary;

  Employee({
    required this.empNumber,
    required this.name,
    required this.position,
    required this.phone,
    required this.address,
    this.password,
    required this.role,
    required this.isActive,
    this.profilePicture,
    this.username,
    this.previousSalary,
    this.currentSalary,
  });

  // Convert a Firestore DocumentSnapshot into an Employee
  factory Employee.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Employee(
      empNumber: data['empNumber'] ?? '',
      name: data['name'] ?? '',
      position: data['position'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      password: data['password'],
      role: data['role'] ?? 'General',
      isActive: data['isActive'] ?? true,
      profilePicture: data['profilePicture'],
      username: data['username'],
      previousSalary: data['previousSalary']?.toDouble() ?? 0.0,
      currentSalary: data['currentSalary']?.toDouble() ?? 0.0,
    );
  }

  // Convert an Employee into a Firestore Document
  Map<String, dynamic> toFirestore() {
    return {
      'empNumber': empNumber,
      'name': name,
      'position': position,
      'phone': phone,
      'address': address,
      'password': password,
      'role': role,
      'isActive': isActive,
      'profilePicture': profilePicture,
      'username': username,
      'previousSalary': previousSalary,
      'currentSalary': currentSalary,
    };
  }
}
