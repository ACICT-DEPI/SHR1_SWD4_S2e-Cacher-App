import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String party;
  final double amount;
  final DateTime date;

  Expense({
    required this.party,
    required this.amount,
    required this.date,
  });

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Expense(
      party: data['party'],
      amount: data['amount'],
      date: (data['date'] as Timestamp).toDate(),
    );
  }
}
