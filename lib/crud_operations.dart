import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/account_transaction.dart';
import 'models/category.dart';
import 'models/employee.dart';
import 'models/student.dart';

class CRUDOperations {
  final CollectionReference transactionsCollection =
      FirebaseFirestore.instance.collection('transaction');
  final CollectionReference categoriesCollection =
      FirebaseFirestore.instance.collection('categories');
  final CollectionReference studentsCollection =
      FirebaseFirestore.instance.collection('students');
  final CollectionReference employeesCollection =
      FirebaseFirestore.instance.collection('employees');

  // Transactions - Read
  Future<List<AccountTransaction>> readAllTransactions() async {
    final snapshot = await transactionsCollection.get();
    return snapshot.docs
        .map((doc) => AccountTransaction.fromFirestore(doc))
        .toList();
  }

  // Transactions - Create
  Future<void> createTransaction(AccountTransaction transaction) async {
    await transactionsCollection.add(transaction.toFirestore());
  }

  // Transactions - Update
  Future<void> updateTransaction(
      String id, AccountTransaction transaction) async {
    await transactionsCollection.doc(id).update(transaction.toFirestore());
  }

  // Transactions - Delete
  Future<void> deleteTransaction(String id) async {
    await transactionsCollection.doc(id).delete();
  }

  // Categories - Read
  Future<List<Category>> readAllCategories() async {
    final snapshot = await categoriesCollection.get();
    return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
  }

  // Categories - Create
  Future<void> createCategory(Category category) async {
    await categoriesCollection.add(category.toFirestore());
  }

  // Categories - Delete
  Future<void> deleteCategory(String id) async {
    await categoriesCollection.doc(id).delete();
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
    await studentsCollection.add(student.toFirestore());
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
    await employeesCollection.add(employee.toFirestore());
  }

  // Employees - Delete
  Future<void> deleteEmployee(String id) async {
    await employeesCollection.doc(id).delete();
  }
}
