import 'package:cloud_firestore/cloud_firestore.dart';

class AccountTransaction {
  String journalNumber;
  String entryNumber;
  DateTime entryDate;
  String category;
  String mainCategory;
  String subCategory;
  double amount;
  String? note;
  String? studentId;
  String? employeeId;

  AccountTransaction({
    required this.journalNumber,
    required this.entryNumber,
    required this.entryDate,
    required this.category,
    required this.mainCategory,
    required this.subCategory,
    required this.amount,
    this.note,
    this.studentId,
    this.employeeId,
  });

  // Convert a Firestore DocumentSnapshot into an AccountTransaction object
  factory AccountTransaction.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AccountTransaction(
      journalNumber: data['journalNumber'] ?? '',
      entryNumber: data['entryNumber'] ?? '',
      entryDate: (data['entryDate'] as Timestamp).toDate(),
      category: data['category'] ?? '',
      mainCategory: data['mainCategory'] ?? '',
      subCategory: data['subCategory'] ?? '',
      amount: data['amount']?.toDouble() ?? 0.0,
      note: data['note'],
      studentId: data['studentId'],
      employeeId: data['employeeId'],
    );
  }

  // Convert an AccountTransaction object into a Firestore Document
  Map<String, dynamic> toFirestore() {
    return {
      'journalNumber': journalNumber,
      'entryNumber': entryNumber,
      'entryDate': entryDate,
      'category': category,
      'mainCategory': mainCategory,
      'subCategory': subCategory,
      'amount': amount,
      'note': note,
      'studentId': studentId,
      'employeeId': employeeId,
    };
  }
}
