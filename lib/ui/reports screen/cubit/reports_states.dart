import '../../../data/model/invoice_model.dart';

abstract class ReportsStates {}

class ReportsInitState extends ReportsStates {}

class ReportsSuccessState extends ReportsStates {}

class ReportsErrorState extends ReportsStates {
  String error;
  ReportsErrorState(this.error);
}

class ReportsLoadingState extends ReportsStates {}

class ReportsTrashState extends ReportsStates {
  final List<Invoice> invoices;
  final List<Invoice> oldInvoices;

  ReportsTrashState({required this.invoices, required this.oldInvoices});
}
