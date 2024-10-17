import 'package:flutter/material.dart';

import '../../data/model/cleints_model.dart';
import '../../data/model/invoice_model.dart';
import '../../data/model/product_model.dart';

abstract class InvoiceRepo {
  Future<List<Invoice>> getInvoicesByDateRange(
      DateTime startDate, DateTime endDate);
  Future<void> createInvoice(Invoice invoice);
  Future<List<Invoice>> getInvoices();
  Future<Invoice?> getInvoiceById(String invoiceId);
  Future<List<Invoice>> getInvoicesSinceInstallation();
  Future<List<Invoice>> getLast20Invoices();
  Future<void> deleteOldInvoices();
  Future<List<ClientModel>> getAllClientInfo();
  Future<Invoice?> fetchInvoiceByOldProductId(String oldProductId);
  Future<Invoice?> fetchInvoiceByReplacedProductId(String replacedProductId);
  Future<void> returnProduct(
      String invoiceId, String productId, int index, BuildContext context);
  Future<void> exchangeProduct(
      String invoiceId,
      String oldProductId,
      String newProductId,
      int oldProductIndex,
      BuildContext context,
      String movedToInvoice);
  Future<void> deleteInvoice(String invoiceId);
  Future<Product?> getProductById(String id);
  Future<void> moveToTrash(String invoiceId);
  Future<List<Invoice>> getTrashInvoices();
  void scheduleTrashCleanup();
  Future<void> restoreInvoice(String invoiceId);
}
