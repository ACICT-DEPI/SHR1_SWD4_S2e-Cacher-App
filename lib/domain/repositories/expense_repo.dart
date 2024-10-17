import 'package:flutter_application_1/data/model/expense_model.dart';

abstract class ExpenseRepo {
  Future<List<Expense>> getExpenses();
}
