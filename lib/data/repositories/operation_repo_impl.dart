import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/domain/repositories/operation_repo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../model/operation_model.dart';

class OperationRepoImpl extends OperationRepo {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  Future<void> logOperation(String type, String description,String oldInvoiceId,String newInvoiceId) async {
    try {
      String managerId = _auth.currentUser!.uid;
      String operationId = const Uuid().v4();
      Operation operation = Operation(
        id: operationId,
        type: type,
        description: description,
        oldInvoice: oldInvoiceId,
        newInvoice: newInvoiceId,
        date: DateTime.now(),
      );
      await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('operations')
          .doc(operationId)
          .set(operation.toJson())
          .catchError((error) {
        throw Exception(error.toString());
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<Operation>> getOperations() async {
    try {
      String managerId = _auth.currentUser!.uid;
      QuerySnapshot querySnapshot = await _firestore
          .collection('managers')
          .doc(managerId)
          .collection('operations')
          .orderBy('date', descending: true)
          .get();

      List<Operation> operations = [];
      for (var doc in querySnapshot.docs) {
        operations.add(Operation.fromJson(doc.data() as Map<String, dynamic>));
      }

      return operations;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // New method to get operations from the last week
  @override
  Future<List<Operation>> getOperationsSinceInstallation() async {
  try {
    String managerId = _auth.currentUser!.uid;

    // Retrieve the installation date from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    String? installationDateStr = prefs.getString('installationDate');
    DateTime installationDate = installationDateStr != null
        ? DateTime.parse(installationDateStr)
        : DateTime.now();

    DateTime now = DateTime.now();
    
    // Fetch operations from the installation date up to the current day
    QuerySnapshot querySnapshot = await _firestore
        .collection('managers')
        .doc(managerId)
        .collection('operations')
        .where('date', isGreaterThanOrEqualTo: installationDate.toIso8601String())
        .where('date', isLessThanOrEqualTo: now.toIso8601String())
        .orderBy('date', descending: true)
        .get();

    log('operationss ${querySnapshot.docs.length}');
    List<Operation> operations = [];
    for (var doc in querySnapshot.docs) {
      operations.add(Operation.fromJson(doc.data() as Map<String, dynamic>));
    }

    log('Operations fetched from installation date: ${operations.length}');
    return operations;
  } catch (e) {
    throw Exception(e.toString());
  }
}


}
