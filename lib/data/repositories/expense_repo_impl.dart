import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/data/model/expense_model.dart';
import 'package:flutter_application_1/domain/repositories/expense_repo.dart';

class ExpenseRepoImpl implements ExpenseRepo {
  @override
  Future<List<Expense>> getExpenses() async {
    String managerId = FirebaseAuth.instance.currentUser!.uid;
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('managers')
        .doc(managerId)
        .collection('expenses')
        .get();

    return snapshot.docs.map((doc) {
      return Expense.fromFirestore(doc);
    }).toList();
  }
}
