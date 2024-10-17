import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../domain/repositories/products_repo.dart';
import '../model/product_model.dart';

class ProductsRepoImpl extends ProductsRepo {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  Future<void> addProduct(String name, String category, String parcode,
      String quantity, String salary, String cost) async {
    try {
      String managerId = _auth.currentUser!.uid;
      String productId = const Uuid().v4();
      Product product = Product(
          productId: productId,
          name: name,
          category: category,
          parcode: parcode,
          quantity: quantity,
          salary: salary,
          cost: cost,
          profit: double.parse(salary) - double.parse(cost),
          isRefunded: false,
          isReplaced: false,
          isReplacedDone: false,
          firstQuantity: double.parse(quantity)
          );
      await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('products')
          .doc(productId)
          .set(product.toJson())
          .catchError((error) {
        throw Exception(error.toString());
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      String managerId = _auth.currentUser!.uid;
      QuerySnapshot querySnapshot = await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('products')
          .where('product_parcode', isEqualTo: barcode)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var productDoc = querySnapshot.docs.first;
        return Product.fromJson(productDoc.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<Product?> getProductById(String productId) async {
    try {
      String managerId = _auth.currentUser!.uid;
      QuerySnapshot querySnapshot = await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('products')
          .where('productId', isEqualTo: productId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var productDoc = querySnapshot.docs.first;
        return Product.fromJson(productDoc.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<Product>> getProducts() async {
    try {
      String managerId = _auth.currentUser!.uid;
      QuerySnapshot querySnapshot = await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('products')
          .orderBy('product_createdDate', descending: true)
          .get();

      List<Product> products = [];
      for (var doc in querySnapshot.docs) {
        products.add(Product.fromJson(doc.data() as Map<String, dynamic>));
      }

      return products;
    } catch (e) {
      throw Exception(e);
    }
  }

  @override
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      String managerId = _auth.currentUser!.uid;
      QuerySnapshot querySnapshot = await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('products')
          .where('product_category', isEqualTo: category)
          .get();

      List<Product> products = [];
      for (var doc in querySnapshot.docs) {
        products.add(Product.fromJson(doc.data() as Map<String, dynamic>));
      }

      return products;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> updateProduct(
      String barcode, Map<String, dynamic> updatedData) async {
    try {
      String managerId = _auth.currentUser!.uid;
      QuerySnapshot querySnapshot = await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('products')
          .where('product_parcode', isEqualTo: barcode)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var productDoc = querySnapshot.docs.first;
        await _firestore
            .collection('managers')
            .doc(managerId)
            .collection('products')
            .doc(productDoc.id)
            .update(updatedData)
            .catchError((error) {
          throw Exception(error.toString());
        });
      } else {
        throw Exception("Product with barcode $barcode not found");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> updateProductQuantity(String barcode, int quantityChange) async {
  try {
    String managerId = _auth.currentUser!.uid;

    // Perform the query based on the barcode
    QuerySnapshot querySnapshot = await _firestore
        .collection('managers')
        .doc(managerId)
        .collection('products')
        .where('product_parcode', isEqualTo: barcode) // Matching the barcode
        .get();
    log(querySnapshot.docs.first.data().toString());
    // Check if the product exists
    if (querySnapshot.docs.isNotEmpty) {
      var productDoc = querySnapshot.docs.first;
      var currentQuantity = productDoc['product_quantity'];
      
      log('${int.parse(currentQuantity)}');
      log('${quantityChange}');
      
      // Update product quantity
      await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('products')
          .doc(productDoc.id)
          .update({'product_quantity': quantityChange.toString()});      
    } else {
      // If no product was found, throw an error
      throw Exception("Product with barcode $barcode not found");
    }
  } catch (e) {
    // Log and rethrow the error for further debugging
    log('Error in updating product quantity: ${e.toString()}');
    throw Exception(e.toString());
  }
}


  @override
  Future<void> deleteProduct(String barcode) async {
    try {
      String managerId = _auth.currentUser!.uid;
      QuerySnapshot querySnapshot = await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('products')
          .where('product_parcode', isEqualTo: barcode)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var productDoc = querySnapshot.docs.first;
        await _firestore
            .collection('managers')
            .doc(managerId)
            .collection('products')
            .doc(productDoc.id)
            .delete()
            .catchError((error) {
          throw Exception(error.toString());
        });
      } else {
        throw Exception("Product with barcode $barcode not deleted");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<bool> isBarcodeUsed(String barcode) async {
    try {
      String managerId = _auth.currentUser!.uid;
      QuerySnapshot querySnapshot = await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('products')
          .where('product_parcode', isEqualTo: barcode)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<Product>> getLatestProducts({int limit = 50}) async {
    try {
      String managerId = _auth.currentUser!.uid;
      QuerySnapshot querySnapshot = await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('products')
          .orderBy('product_createdDate', descending: true)
          .limit(limit)
          .get();

      List<Product> products = [];
      for (var doc in querySnapshot.docs) {
        products.add(Product.fromJson(doc.data() as Map<String, dynamic>));
      }

      return products;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
