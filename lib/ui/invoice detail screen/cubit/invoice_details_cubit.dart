import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/data/model/invoice_model.dart';
import 'package:flutter_application_1/domain/repositories/invoice_repo.dart';
import 'package:flutter_application_1/data/repositories/invoice_repo_impl.dart';

import '../../../data/model/product_model.dart';
import '../../bill screen/product_screen.dart';
import 'invoice_details_state.dart'; // Import the states

class InvoiceDetailCubit extends Cubit<InvoiceDetailState> {
  final InvoiceRepo _invoiceRepo = InvoiceRepoImpl();

  InvoiceDetailCubit() : super(InvoiceDetailInitial());

  Future<void> fetchInvoices(String clientId) async {
    emit(InvoiceDetailLoading());
    try {
      String managerId = FirebaseAuth.instance.currentUser!.uid;
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('managers')
          .doc(managerId)
          .collection('invoices')
          .where('clientInfo.client_id', isEqualTo: clientId)
          .orderBy('date', descending: true)
          .get();

      List<Invoice> invoices = snapshot.docs
          .map((doc) => Invoice.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      emit(InvoiceDetailLoaded(invoices));
    } catch (error) {
      emit(InvoiceDetailError('Error fetching invoices: $error'));
    }
  }

  Future<void> returnProduct(
      Invoice invoice, Product product, BuildContext context) async {
    emit(InvoiceDetailLoading());
    try {
      await _invoiceRepo.returnProduct(invoice.invoiceId, product.productId!,
          invoice.products.indexOf(product), context);
      product.isRefunded = true;
      emit(ProductReturnSuccess());
    } catch (error) {
      emit(InvoiceDetailError('Error returning product: $error'));
    }
  }

  Future<void> exchangeProduct(
      BuildContext context, Invoice invoice, Product product) async {
    emit(InvoiceDetailLoading());
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const InvoiceProductScreen(),
          settings: RouteSettings(
            arguments: {
              'oldInvoice': invoice,
              'isExchange': true,
              'oldProductId': product.productId,
              'index': invoice.products.indexOf(product),
            },
          ),
        ),
      );
      emit(ProductExchangeSuccess());
    } catch (error) {
      emit(InvoiceDetailError('Error exchanging product: $error'));
    }
  }
}
