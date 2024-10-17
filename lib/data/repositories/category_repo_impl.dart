import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/domain/repositories/category_repo.dart';

class CategoryRepoImpl extends CategoryRepo {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  Future<List<String>> getCategories() async {
    try {
      String managerId = _auth.currentUser!.uid;
      QuerySnapshot querySnapshot = await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('categories')
          .get();

      List<String> categories = [];
      for (var doc in querySnapshot.docs) {
        categories.add(doc['name']);
      }

      return categories;
    } catch (e) {
      throw Exception(e);
    }
  }

  @override
  Future<void> addCategory(String categoryName) async {
    try {
      String managerId = FirebaseAuth.instance.currentUser!.uid;

      // Check if the category already exists
      QuerySnapshot querySnapshot = await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('categories')
          .where('name', isEqualTo: categoryName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // If the category does not exist, add it
        await _firestore
            .collection('managers')
            .doc(managerId)
            .collection('categories')
            .add({'name': categoryName}).catchError((error) {
          throw Exception(error.toString());
        });
      } else {
        // Category already exists, so no need to add it again
        throw Exception('Category "$categoryName" already exists');
      }
    } catch (e) {
      throw Exception('Failed to add category: $e');
    }
  }

  @override
  Future<void> deleteCategory(String categoryName) async {
  try {
    String managerId = _auth.currentUser!.uid;

    // Fetch the category document(s) to delete
    QuerySnapshot categoryQuerySnapshot = await _firestore
        .collection('managers')
        .doc(managerId)
        .collection('categories')
        .where('name', isEqualTo: categoryName)
        .get();

    // Loop through each category document to delete
    for (var categoryDoc in categoryQuerySnapshot.docs) {
      // Fetch the products associated with this category
      QuerySnapshot productQuerySnapshot = await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('products')
          .where('product_category', isEqualTo: categoryName)
          .get();

      // Delete each product associated with the category
      for (var productDoc in productQuerySnapshot.docs) {
        await _firestore
            .collection('managers')
            .doc(managerId)
            .collection('products')
            .doc(productDoc.id)
            .delete()
            .catchError((error) {
          throw Exception("Error deleting product: ${error.toString()}");
        });
      }

      // Delete the category document itself
      await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('categories')
          .doc(categoryDoc.id)
          .delete()
          .catchError((error) {
        throw Exception("Error deleting category: ${error.toString()}");
      });
    }
  } catch (e) {
    throw Exception("Error deleting category and associated products: ${e.toString()}");
  }
}

}
