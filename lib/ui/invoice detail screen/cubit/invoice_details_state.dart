import 'package:flutter_application_1/data/model/invoice_model.dart';

// Base State
abstract class InvoiceDetailState {
  List<Object?> get props => [];
}

// Initial State
class InvoiceDetailInitial extends InvoiceDetailState {}

// Loading State
class InvoiceDetailLoading extends InvoiceDetailState {}

// Success State
class InvoiceDetailSuccess extends InvoiceDetailState {
  final Invoice? invoice;

  InvoiceDetailSuccess(this.invoice);

  @override
  List<Object?> get props => [invoice];
}

// Error State
class InvoiceDetailError extends InvoiceDetailState {
  final String error;

  InvoiceDetailError(this.error);

  @override
  List<Object?> get props => [error];
}

// Product Return Success
class ProductReturnSuccess extends InvoiceDetailState {}

// Product Exchange Success
class ProductExchangeSuccess extends InvoiceDetailState {}

class InvoiceDetailLoaded extends InvoiceDetailState {
List<Invoice> invoices;
InvoiceDetailLoaded(this.invoices);
}
