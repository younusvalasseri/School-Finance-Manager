import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'employee.g.dart';

@HiveType(typeId: 2)
class Employee extends HiveObject {
  @HiveField(0)
  late String empNumber;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String position;

  @HiveField(3)
  late String phone;

  @HiveField(4)
  late String address;

  @HiveField(5)
  String? password;

  @HiveField(6)
  late String role;

  @HiveField(7)
  late bool isActive;

  @HiveField(8)
  String? profilePicture;

  @HiveField(9)
  String? username;

  @HiveField(10)
  double? previousSalary;

  @HiveField(11)
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
