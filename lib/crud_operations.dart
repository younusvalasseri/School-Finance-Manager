// ignore_for_file: unrelated_type_equality_checks

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'models/account_transaction.dart';
import 'models/category.dart';
import 'models/employee.dart';
import 'models/student.dart';
import 'models/courses.dart';

class CRUDOperations {
  final CollectionReference transactionsCollection =
      FirebaseFirestore.instance.collection('transaction');
  final CollectionReference categoriesCollection =
      FirebaseFirestore.instance.collection('categories');
  final CollectionReference studentsCollection =
      FirebaseFirestore.instance.collection('students');
  final CollectionReference employeesCollection =
      FirebaseFirestore.instance.collection('employees');
  final CollectionReference coursesCollection =
      FirebaseFirestore.instance.collection('courses');

  // Transactions - Read
  Future<List<AccountTransaction>> readAllTransactions() async {
    final snapshot = await transactionsCollection.get();
    return snapshot.docs
        .map((doc) => AccountTransaction.fromFirestore(doc))
        .toList();
  }

  // Transactions - Create
  Future<void> createTransaction(AccountTransaction transaction) async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      await transactionsCollection
          .doc(transaction.compositeKey)
          .set(transaction.toFirestore());
    } else {
      var transactionsBox = Hive.box<AccountTransaction>('transactions');
      transactionsBox.put(transaction.compositeKey, transaction);
    }
  }

  // Transactions - Update
  Future<void> updateTransaction(
      String compositeKey, AccountTransaction transaction) async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      await transactionsCollection
          .doc(compositeKey)
          .update(transaction.toFirestore());
    } else {
      var transactionsBox = Hive.box<AccountTransaction>('transactions');
      transactionsBox.put(compositeKey, transaction);
    }
  }

  // Transactions - Delete
  Future<void> deleteTransaction(String compositeKey) async {
    await transactionsCollection.doc(compositeKey).delete();
  }

  // Categories - Read
  Future<List<Category>> readAllCategories() async {
    final snapshot = await categoriesCollection.get();
    return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
  }

  // Categories - Create
  Future<void> createCategory(Category category) async {
    await categoriesCollection
        .doc(category.description)
        .set(category.toFirestore());
  }

  // Categories - Delete
  Future<void> deleteCategory(String description) async {
    await categoriesCollection.doc(description).delete();
  }

  // Students - Read
  Future<List<Student>> readAllStudents() async {
    final snapshot = await studentsCollection.get();
    return snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList();
  }

  // Students - Update
  Future<void> updateStudent(String id, Student student) async {
    await studentsCollection.doc(id).update(student.toFirestore());
  }

  // Students - Create
  Future<void> createStudent(Student student) async {
    await studentsCollection.doc(student.admNumber).set(student.toFirestore());
  }

  // Students - Delete
  Future<void> deleteStudent(String id) async {
    await studentsCollection.doc(id).delete();
  }

  // Employees - Read
  Future<List<Employee>> readAllEmployees() async {
    final snapshot = await employeesCollection.get();
    return snapshot.docs.map((doc) => Employee.fromFirestore(doc)).toList();
  }

  // Employees - Update
  Future<void> updateEmployee(String id, Employee employee) async {
    await employeesCollection.doc(id).update(employee.toFirestore());
  }

  // Employees - Create
  Future<void> createEmployee(Employee employee) async {
    await employeesCollection
        .doc(employee.empNumber)
        .set(employee.toFirestore());
  }

  // Employees - Delete
  Future<void> deleteEmployee(String id) async {
    await employeesCollection.doc(id).delete();
  }

  // Courses - Read
  Future<List<Courses>> readAllCourses() async {
    final snapshot = await coursesCollection.get();
    return snapshot.docs.map((doc) => Courses.fromFirestore(doc)).toList();
  }

  // Courses - Create
  Future<void> createCourse(Courses course) async {
    await coursesCollection.doc(course.courseName).set(course.toFirestore());
  }

  // Courses - Update
  Future<void> updateCourse(String id, Courses course) async {
    await coursesCollection.doc(id).update(course.toFirestore());
  }

  // Courses - Delete
  Future<void> deleteCourse(String id) async {
    await coursesCollection.doc(id).delete();
  }

  // Sync Hive data to Firestore for Transactions
  static Future<void> syncTransactionsDataToFirestore() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      var transactionsBox = Hive.box<AccountTransaction>('transactions');
      var transactionsCollection =
          FirebaseFirestore.instance.collection('transaction');

      for (var transaction in transactionsBox.values) {
        var docSnapshot =
            await transactionsCollection.doc(transaction.compositeKey).get();
        if (!docSnapshot.exists) {
          await transactionsCollection
              .doc(transaction.compositeKey)
              .set(transaction.toFirestore());
        } else {
          await transactionsCollection
              .doc(transaction.compositeKey)
              .update(transaction.toFirestore());
        }
      }

      // Clear Hive transactions after syncing
      transactionsBox.clear();
    }
  }

  // Sync Hive data to Firestore for Students
  static Future<void> syncHiveDataToFirestore() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      var studentsBox = Hive.box<Student>('students');
      var studentsCollection =
          FirebaseFirestore.instance.collection('students');

      for (var student in studentsBox.values) {
        var docSnapshot = await studentsCollection.doc(student.admNumber).get();
        if (!docSnapshot.exists) {
          await studentsCollection
              .doc(student.admNumber)
              .set(student.toFirestore());
        }
      }
    }
  }

  // Sync Hive data to Firestore for Courses
  static Future<void> syncCoursesDataToFirestore() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      var coursesBox = Hive.box<Courses>('courses');
      var coursesCollection = FirebaseFirestore.instance.collection('courses');

      for (var course in coursesBox.values) {
        var docSnapshot = await coursesCollection.doc(course.courseName).get();
        if (!docSnapshot.exists) {
          await coursesCollection
              .doc(course.courseName)
              .set(course.toFirestore());
        }
      }
    }
  }

  // Sync Hive data to Firestore for Employees
  static Future<void> syncEmployeesDataToFirestore() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      var employeesBox = Hive.box<Employee>('employees');
      var employeesCollection =
          FirebaseFirestore.instance.collection('employees');

      for (var employee in employeesBox.values) {
        var docSnapshot =
            await employeesCollection.doc(employee.empNumber).get();
        if (!docSnapshot.exists) {
          await employeesCollection
              .doc(employee.empNumber)
              .set(employee.toFirestore());
        }
      }
    }
  }

  // Sync Hive data to Firestore for Categories
  static Future<void> syncCategoriesDataToFirestore() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      var categoriesBox = Hive.box<Category>('categories');
      var categoriesCollection =
          FirebaseFirestore.instance.collection('categories');

      for (var category in categoriesBox.values) {
        var docSnapshot =
            await categoriesCollection.doc(category.description).get();
        if (!docSnapshot.exists) {
          await categoriesCollection
              .doc(category.description)
              .set(category.toFirestore());
        }
      }
    }
  }

  // Start syncing transactions periodically
  void startSyncingTransactions() {
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        syncEmployeesDataToFirestore();
      }
    });

    Timer.periodic(const Duration(minutes: 5), (timer) {
      CRUDOperations.syncTransactionsDataToFirestore();
    });
  }
}
