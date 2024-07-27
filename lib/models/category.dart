import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  String description;
  String type; // Income or Expense
  bool isTaxable;

  Category({
    required this.description,
    required this.type,
    required this.isTaxable,
  });

  // Convert a Firestore DocumentSnapshot into a Category
  factory Category.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Category(
      description: data['description'] ?? '',
      type: data['type'] ?? '',
      isTaxable: data['isTaxable'] ?? false,
    );
  }

  // Convert a Category into a Firestore Document
  Map<String, dynamic> toFirestore() {
    return {
      'description': description,
      'type': type,
      'isTaxable': isTaxable,
    };
  }
}
