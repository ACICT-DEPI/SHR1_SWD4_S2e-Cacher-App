// ignore_for_file: avoid_types_as_parameter_names

import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/model/cleints_model.dart';
import 'package:flutter_application_1/data/model/invoice_model.dart';
import 'package:flutter_application_1/data/model/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/invoice_repo.dart';
import 'dart:math' as Math;

class InvoiceRepoImpl extends InvoiceRepo {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  Future<List<Invoice>> getInvoicesByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      String managerId = _auth.currentUser!.uid;

      // Query Firestore for invoices within the specified date range
      QuerySnapshot querySnapshot = await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('invoices')
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('date', descending: true)
          .get();

      // Convert the query result to a list of Invoice objects
      List<Invoice> invoices = querySnapshot.docs
          .map((doc) => Invoice.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      return invoices;
    } catch (e) {
      throw Exception('Error fetching invoices by date range: $e');
    }
  }

  @override
  Future<void> createInvoice(Invoice invoice) async {
    try {
      String managerId = _auth.currentUser!.uid;
      await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('invoices')
          .doc(invoice.invoiceId)
          .set(invoice.toJson())
          .catchError((error) {
        throw Exception(error.toString());
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<Invoice>> getInvoices() async {
    try {
      String managerId = _auth.currentUser!.uid;
      QuerySnapshot querySnapshot = await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('invoices')
          .orderBy('date', descending: true)
          .get();

      List<Invoice> invoices = [];
      for (var doc in querySnapshot.docs) {
        invoices.add(Invoice.fromJson(doc.data() as Map<String, dynamic>));
      }

      return invoices;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // New method to get the last 20 invoices
  @override
  Future<List<Invoice>> getLast20Invoices() async {
    try {
      String managerId = _auth.currentUser!.uid;
      QuerySnapshot querySnapshot = await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('invoices')
          .orderBy('date', descending: true)
          .limit(20)
          .get();

      List<Invoice> invoices = [];
      for (var doc in querySnapshot.docs) {
        invoices.add(Invoice.fromJson(doc.data() as Map<String, dynamic>));
      }

      return invoices;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<Invoice?> getInvoiceById(String invoiceId) async {
    try {
      String managerId = _auth.currentUser!.uid;
      DocumentSnapshot doc = await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('invoices')
          .doc(invoiceId)
          .get();

      if (doc.exists) {
        return Invoice.fromJson(doc.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // New method to get invoices from the last week
  @override
  Future<List<Invoice>> getInvoicesSinceInstallation() async {
    try {
      String managerId = _auth.currentUser!.uid;

      // Retrieve the installation date from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String? installationDateStr = prefs.getString('installationDate');
      DateTime installationDate = installationDateStr != null
          ? DateTime.parse(installationDateStr)
          : DateTime.now();

      DateTime now = DateTime.now();

      // Fetch invoices from the installation date up to the current day
      QuerySnapshot querySnapshot = await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('invoices')
          .where('date',
              isGreaterThanOrEqualTo: installationDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: now.toIso8601String())
          .orderBy('date', descending: true)
          .get();

      log('${querySnapshot.docs.length}');

      List<Invoice> invoices = [];
      for (var doc in querySnapshot.docs) {
        invoices.add(Invoice.fromJson(doc.data() as Map<String, dynamic>));
      }

      log('Invoices fetched from installation date: $invoices');
      return invoices;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<Invoice?> fetchInvoiceByOldProductId(String oldProductId) async {
    try {
      String managerId = FirebaseAuth.instance.currentUser!.uid;
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('managers')
          .doc(managerId)
          .collection('invoices')
          .where('oldProductId', isEqualTo: oldProductId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot doc = querySnapshot.docs.first;
        return Invoice.fromJson(doc.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<Invoice?> fetchInvoiceByReplacedProductId(
      String replacedProductId) async {
    try {
      String managerId = _auth.currentUser!.uid;
      QuerySnapshot querySnapshot = await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('invoices')
          .where('replacedProductId', isEqualTo: replacedProductId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot doc = querySnapshot.docs.first;
        return Invoice.fromJson(doc.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<ClientModel>> getAllClientInfo() async {
    try {
      final String managerId = FirebaseAuth.instance.currentUser!.uid;
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('managers')
          .doc(managerId)
          .collection('invoices')
          .get();

      final List<ClientModel> customers = [];
      final Set<String> customerIds = {};

      for (var doc in snapshot.docs) {
        final clientModel = ClientModel.fromJson(doc['clientInfo']);
        if (!customerIds.contains(clientModel.clientId)) {
          customers.add(clientModel);
          customerIds.add(clientModel.clientId);
        }
      }
      return customers;
    } catch (e) {
      throw Exception('Failed to retrieve client info');
    }
  }

  // Updated returnProduct method in InvoiceRepoImpl
  @override
  Future<void> returnProduct(String invoiceId, String productId, int index,
      BuildContext context) async {
    try {
      String managerId = _auth.currentUser!.uid;
      DocumentReference invoiceRef = _firestore
          .collection('managers')
          .doc(managerId)
          .collection('invoices')
          .doc(invoiceId);

      DocumentSnapshot invoiceDoc = await invoiceRef.get();
      if (invoiceDoc.exists) {
        Invoice invoice =
            Invoice.fromJson(invoiceDoc.data() as Map<String, dynamic>);

        if (index >= 0 && index < invoice.products.length) {
          // Calculate total price before discount for all non-refunded and non-replaced products
          double totalPriceBeforeDiscount = invoice.products
              .where((product) => !product.isRefunded && !product.isReplaced)
              .fold(0, (sum, product) => sum + double.parse(product.salary!));

          double totalDiscount = double.parse(invoice.discount);

          // Get the product to be returned
          Product productToReturn = invoice.products[index];
          double productPrice = double.parse(productToReturn.salary!);

          // Calculate the proportion of this product's price to the total
          double proportion = totalPriceBeforeDiscount > 0
              ? productPrice / totalPriceBeforeDiscount
              : 0;

          // Calculate the discount for this product
          double productDiscount = totalDiscount * proportion;

          // Calculate the effective price to return
          double effectivePriceToReturn = productPrice - productDiscount;

          // Mark the product as refunded
          productToReturn.isRefunded = true;

          // Calculate new total cost
          double newTotalCost =
              Math.max(0, invoice.totalCoast - effectivePriceToReturn);

          // Calculate new total discount
          double newTotalDiscount =
              Math.max(0, totalDiscount - productDiscount);

          // Update the invoice
          Invoice updatedInvoice = Invoice(
              invoiceId: invoice.invoiceId,
              clientModel: invoice.clientModel,
              paidUp: invoice.paidUp,
              paymentMethod: invoice.paymentMethod,
              firstDiscount: invoice.discount,
              discount: newTotalDiscount.toString(),
              numOfBuyings: invoice.numOfBuyings,
              totalCoast: newTotalCost,
              managerId: invoice.managerId,
              logoUrl: invoice.logoUrl,
              products: invoice.products,
              date: invoice.date);

          // Update the invoice in Firebase
          await invoiceRef.update(updatedInvoice.toJson());

          // Show dialog to ask if the user wants to update the quantity
          await showDialog(
            context: context,
            builder: (context) => Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('تحديث الكمية'),
                content: const Text('هل ترغب في تعديل كمية المنتج المسترجع؟'),
                actions: [
                  TextButton(
                    onPressed: () async {
                      await updateProductQuantity(productToReturn.parcode!, 1);
                      Navigator.of(context).pop();
                    },
                    child: const Text('نعم'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('لا'),
                  ),
                ],
              ),
            ),
          );
        } else {
          throw Exception("Invalid product index");
        }
      } else {
        throw Exception("Invoice not found");
      }
    } catch (e) {
      log(e.toString());
      throw Exception(e.toString());
    }
  }

  // Manual method to delete old invoices when the button is clicked
  @override
  Future<void> deleteOldInvoices() async {
  try {
    String managerId = _auth.currentUser!.uid;
    DateTime thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    // Fetch all invoices from the trash
    QuerySnapshot querySnapshot = await _firestore
        .collection('managers')
        .doc(managerId)
        .collection('trash')
        .get();

    // Filter invoices with trashDate older than 30 days
    List<QueryDocumentSnapshot> oldInvoices = querySnapshot.docs.where((doc) {
      String trashDateString = doc['trashDate'];  // Assuming trashDate is stored as a string
      DateTime trashDate = DateTime.parse(trashDateString);
      return trashDate.isBefore(thirtyDaysAgo);
    }).toList();

    if (oldInvoices.isEmpty) {
      log('No invoices older than 30 days found.');
      return;
    }

    // Delete each invoice that is older than 30 days
    for (var doc in oldInvoices) {
      try {
        await doc.reference.delete();
        log('Deleted invoice with ID: ${doc.id}');
      } catch (e) {
        log('Failed to delete invoice with ID: ${doc.id}. Error: $e');
      }
    }

    log('Successfully deleted old invoices.');
  } catch (e) {
    log('Error during invoice deletion: $e');
    throw Exception('Error during invoice deletion: $e');
  }
}


  Future<void> updateProductQuantity(String barcode, int quantityChange) async {
    log('message');
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
        int currentQuantity = int.parse(productDoc['product_quantity']);
        int newQuantity = (currentQuantity + quantityChange);
        log('new quantity is $currentQuantity');
        await _firestore
            .collection('managers')
            .doc(managerId)
            .collection('products')
            .doc(productDoc.id)
            .update({'product_quantity': newQuantity.toString()});
      } else {
        throw Exception("Product with barcode $barcode not found");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> deleteInvoice(String invoiceId) async {
    try {
      String managerId = _auth.currentUser!.uid;
      await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('invoices')
          .doc(invoiceId)
          .delete()
          .catchError((error) {
        throw Exception(error.toString());
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> exchangeProduct(
      String invoiceId,
      String oldProductId,
      String newProductId,
      int oldProductIndex,
      BuildContext context,
      String movedToInvoice) async {
    try {
      String managerId = _auth.currentUser!.uid;
      DocumentReference invoiceRef = _firestore
          .collection('managers')
          .doc(managerId)
          .collection('invoices')
          .doc(invoiceId);

      DocumentSnapshot invoiceDoc = await invoiceRef.get();
      if (invoiceDoc.exists) {
        Invoice invoice =
            Invoice.fromJson(invoiceDoc.data() as Map<String, dynamic>);

        if (oldProductIndex >= 0 && oldProductIndex < invoice.products.length) {
          Product oldProduct = invoice.products[oldProductIndex];

          // Calculate total price before discount for all non-replaced products
          double totalPriceBeforeDiscount = invoice.products
              .where((product) => !product.isReplaced || !product.isRefunded)
              .fold(0, (sum, product) => sum + double.parse(product.salary!));

          log('totalPriceBeforeDiscount $totalPriceBeforeDiscount');

          double totalDiscount = double.parse(invoice.discount);
          log('totalDiscount $totalDiscount');

          // Calculate the proportion of the old product's price to the total
          double oldProductPrice = double.parse(oldProduct.salary!);
          double proportion = oldProductPrice / totalPriceBeforeDiscount;
          log('oldProductPrice $oldProductPrice');
          log('proportion $proportion');

          // Calculate the discount for the old product
          double oldProductDiscount = totalDiscount * proportion;
          log('oldProductDiscount $oldProductDiscount');

          // Calculate the effective price of the old product
          double effectivePriceOfOldProduct =
              oldProductPrice - oldProductDiscount;
          log('effectivePriceOfOldProduct $effectivePriceOfOldProduct');

          // Fetch the new product details
          Product? newProduct = await getProductById(newProductId);
          if (newProduct != null) {
            newProduct.isReplaced = false;
            newProduct.isReplacedDone = true;

            // Calculate the new total cost
            double newTotalCost =
                Math.max(0, invoice.totalCoast - effectivePriceOfOldProduct);

            log('newTotalCost $newTotalCost');

            // Calculate the new total discount
            double newTotalDiscount =
                Math.max(0, totalDiscount - oldProductDiscount);
            log('newTotalDiscount $newTotalDiscount');

            // Mark the old product as replaced
            oldProduct.isReplaced = true;
            invoice.products[oldProductIndex] = oldProduct;

            // Add the new product to the invoice
            //invoice.products.add(newProduct);

            Invoice updatedInvoice = Invoice(
              invoiceId: invoice.invoiceId,
              clientModel: invoice.clientModel,
              paidUp: invoice.paidUp,
              paymentMethod: invoice.paymentMethod,
              firstDiscount: invoice.discount,
              discount: newTotalDiscount.toString(),
              numOfBuyings: invoice.numOfBuyings,
              totalCoast: newTotalCost,
              managerId: invoice.managerId,
              logoUrl: invoice.logoUrl,
              products: invoice.products,
              date: invoice.date,
            );

            // Update the invoice in Firebase
            await invoiceRef.update(updatedInvoice.toJson());

            // Show dialog to ask if the user wants to update the quantity
            await showDialog(
              context: context,
              builder: (context) => Directionality(
                textDirection: TextDirection.rtl,
                child: AlertDialog(
                  title: const Text('تحديث الكمية'),
                  content: const Text('هل ترغب في تعديل كمية المنتج المستبدل؟'),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        await updateProductQuantity(oldProduct.parcode!, 1);
                        Navigator.of(context).pop();
                      },
                      child: const Text('نعم'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('لا'),
                    ),
                  ],
                ),
              ),
            );
          } else {
            throw Exception("New product not found");
          }
        } else {
          throw Exception("Product index out of range");
        }
      } else {
        throw Exception("Invoice not found");
      }
    } catch (e) {
      log(e.toString());
      throw Exception(e.toString());
    }
  }

  @override
  Future<Product?> getProductById(String id) async {
    try {
      String managerId = _auth.currentUser!.uid;
      QuerySnapshot querySnapshot = await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('products')
          .where('productId', isEqualTo: id)
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
  Future<void> moveToTrash(String invoiceId) async {
    try {
      String managerId = _auth.currentUser!.uid;
      DocumentSnapshot invoiceDoc = await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('invoices')
          .doc(invoiceId)
          .get();

      if (invoiceDoc.exists) {
        Invoice invoice =
            Invoice.fromJson(invoiceDoc.data() as Map<String, dynamic>);
        invoice.trashDate = DateTime.now();
        await _firestore
            .collection('managers')
            .doc(managerId)
            .collection('trash')
            .doc(invoiceId)
            .set(invoice.toJson());

        await deleteInvoice(invoiceId);
      } else {
        throw Exception("Invoice not found");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<Invoice>> getTrashInvoices() async {
    try {
      String managerId = _auth.currentUser!.uid;
      QuerySnapshot querySnapshot = await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('trash')
          .get();

      List<Invoice> invoices = [];
      for (var doc in querySnapshot.docs) {
        invoices.add(Invoice.fromJson(doc.data() as Map<String, dynamic>));
      }

      return invoices;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  void scheduleTrashCleanup() {
    Timer.periodic(const Duration(days: 1), (timer) async {
      String managerId = _auth.currentUser!.uid;
      DateTime oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));

      QuerySnapshot querySnapshot = await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('trash')
          .where('trashDate', isLessThan: oneWeekAgo)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    });
  }

  @override
  Future<void> restoreInvoice(String invoiceId) async {
    try {
      String managerId = _auth.currentUser!.uid;
      DocumentSnapshot invoiceDoc = await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('trash')
          .doc(invoiceId)
          .get();

      if (invoiceDoc.exists) {
        Invoice invoice =
            Invoice.fromJson(invoiceDoc.data() as Map<String, dynamic>);
        invoice.trashDate = null; // Clear the trashDate
        await _firestore
            .collection('managers')
            .doc(managerId)
            .collection('invoices')
            .doc(invoiceId)
            .set(invoice.toJson());

        await _firestore
            .collection('managers')
            .doc(managerId)
            .collection('trash')
            .doc(invoiceId)
            .delete();
      } else {
        throw Exception("Invoice not found in trash");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
