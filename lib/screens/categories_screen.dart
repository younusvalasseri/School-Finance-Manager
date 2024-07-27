import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:week7_institute_project_2/generated/l10n.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).categories),
      ),
      body: _buildCategoryList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context),
        tooltip: 'Add Category',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = snapshot.data!.docs
            .map((doc) => Category.fromFirestore(doc))
            .toList();

        if (categories.isEmpty) {
          return const Center(child: Text('No categories yet'));
        }

        categories.sort((a, b) => a.description.compareTo(b.description));

        return ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return ListTile(
              leading: Icon(
                category.type == 'Income'
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                color: category.type == 'Income' ? Colors.green : Colors.red,
              ),
              title: Text(category.description),
              subtitle: Text(
                  '${category.type} | Taxable: ${category.isTaxable ? 'Yes' : 'No'}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditCategoryDialog(context, category),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteCategory(context, category),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String description = '';
    String type = 'Income';
    bool isTaxable = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Category'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => description = value!,
                  ),
                  DropdownButtonFormField<String>(
                    value: type,
                    items: ['Income', 'Expense'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      type = newValue!;
                    },
                    decoration: const InputDecoration(labelText: 'Type'),
                  ),
                  SwitchListTile(
                    title: const Text('Taxable'),
                    value: isTaxable,
                    onChanged: (bool value) {
                      isTaxable = value;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  _addCategory(description, type, isTaxable);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _addCategory(String description, String type, bool isTaxable) {
    final newCategory = Category(
      description: description,
      type: type,
      isTaxable: isTaxable,
    );

    CRUDOperations.createCategory(newCategory);
  }

  void _showEditCategoryDialog(BuildContext context, Category category) {
    final formKey = GlobalKey<FormState>();
    String description = category.description;
    String type = category.type;
    bool isTaxable = category.isTaxable;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Category'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: description,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => description = value!,
                  ),
                  DropdownButtonFormField<String>(
                    value: type,
                    items: ['Income', 'Expense'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      type = newValue!;
                    },
                    decoration: const InputDecoration(labelText: 'Type'),
                  ),
                  SwitchListTile(
                    title: const Text('Taxable'),
                    value: isTaxable,
                    onChanged: (bool value) {
                      isTaxable = value;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  category.description = description;
                  category.type = type;
                  category.isTaxable = isTaxable;
                  CRUDOperations.updateCategory(category);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteCategory(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this category?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                CRUDOperations.deleteCategory(category);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

// Updated CRUD operations to interact with Firestore
class CRUDOperations {
  static Future<void> createCategory(Category category) async {
    await FirebaseFirestore.instance
        .collection('categories')
        .add(category.toFirestore());
  }

  static Future<void> updateCategory(Category category) async {
    await FirebaseFirestore.instance
        .collection('categories')
        .doc(category.id) // Assuming 'id' is the document ID
        .update(category.toFirestore());
  }

  static Future<void> deleteCategory(Category category) async {
    await FirebaseFirestore.instance
        .collection('categories')
        .doc(category.id) // Assuming 'id' is the document ID
        .delete();
  }
}

// Firestore model for Category
class Category {
  String id; // Document ID
  String description;
  String type;
  bool isTaxable;

  Category({
    this.id = '',
    required this.description,
    required this.type,
    required this.isTaxable,
  });

  // Convert a Firestore DocumentSnapshot into a Category object
  factory Category.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      description: data['description'] ?? '',
      type: data['type'] ?? '',
      isTaxable: data['isTaxable'] ?? false,
    );
  }

  // Convert a Category object into a Firestore Document
  Map<String, dynamic> toFirestore() {
    return {
      'description': description,
      'type': type,
      'isTaxable': isTaxable,
    };
  }
}
