import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'account_transaction.g.dart';

@HiveType(typeId: 3)
class AccountTransaction {
  @HiveField(0)
  late String journalNumber;

  @HiveField(1)
  late String entryNumber;

  @HiveField(2)
  late DateTime entryDate;

  @HiveField(3)
  late String category;

  @HiveField(4)
  late String mainCategory;

  @HiveField(5)
  late String subCategory;

  @HiveField(6)
  late double amount;

  @HiveField(7)
  String? note;

  @HiveField(8)
  String? studentId;

  @HiveField(9)
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
// Generate composite key
  String get compositeKey => '$journalNumber-$entryNumber';

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
