import 'package:flutter_application_1/data/model/product_model.dart';

import '../../../data/model/invoice_model.dart';

class InvoiceStates {}

class InvoiceInitial extends InvoiceStates{}

class InvoiceLoaded extends InvoiceStates {
  List<Invoice>? invoices;
  InvoiceLoaded({this.invoices});
}

class InvoiceStateLoading extends InvoiceStates {}

class InvoiceStateSuccess extends InvoiceStates {}

class ManagerStateSuccess extends InvoiceStates {}

class ManagerStateLoading extends InvoiceStates {}



class ManagerStateError extends InvoiceStates {
  String error;
  ManagerStateError(this.error);
}

class InvoiceStateError extends InvoiceStates {
  String error;
  InvoiceStateError(this.error);
}

class InvoiceStateItemsUpdated extends InvoiceStates {
  List<Product> products;
  InvoiceStateItemsUpdated(this.products);
}

class InvoiceStateUpdated extends InvoiceStates {
  
}

class InvoiceStateOfflineSuccess extends InvoiceStates {}

class AddInvoiceLoading extends InvoiceStates {}

class AddInvoiceError extends InvoiceStates {
  String error;
  AddInvoiceError(this.error);
}

class AddInvoiceSuccess extends InvoiceStates {}

class InvoiceUpdatedState extends InvoiceStates {
  
}
