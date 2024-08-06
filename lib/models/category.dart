import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'category.g.dart';

@HiveType(typeId: 4)
class Category {
  @HiveField(0)
  late String description;

  @HiveField(1)
  late String type; // "income" or "expense"

  @HiveField(2)
  late bool isTaxable;

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
