import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/model/invoice_model.dart';
import 'package:flutter_application_1/data/repositories/invoice_repo_impl.dart';
import 'package:flutter_application_1/domain/repositories/invoice_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../main.dart';
import '../../bill screen/cubit/invoice_cubit.dart';
import '../../reports screen/cubit/reports_cubit.dart';
import '../../widgets/bacup_pdf.dart';
import 'home_states_manage.dart';

class HomeCubitManage extends Cubit<HomeTabStates> {
  HomeCubitManage() : super(HomeTabStates());

  List<Invoice> invoices = [];
  List<Invoice> lastInvoices = [];
  InvoiceRepo invoiceRepo = InvoiceRepoImpl();

  Future<void> getAllInvoices() async {
    try {
      emit(HomeTabStateLoading());
      invoices = await invoiceRepo.getInvoices();
      emit(HomeTabSuccessState());
    } catch (e) {
      emit(HomeTabStateError(e.toString()));
    }
  }

  Future<void> printBackupBdf(BuildContext context) async {
    try {
      emit(HomeTabStateLoading());
      final invoiceCubit = context.read<InvoiceCubit>();
      final reportsCubit = context.read<ReportsCubit>();

      final invoices = (await invoiceCubit.getInvoicesSinceInstallation());
      final operations = await reportsCubit.getOperationsSinceInstallation();
      final products = await invoiceCubit.getAllProductsSinceInstallation();

      if (invoices.isNotEmpty || operations.isNotEmpty || products.isNotEmpty) {
        final backupPath =
            await generateComprehensiveBackupPDF(invoices, operations, products);

        emit(HomeTabSuccessState());

        if (backupPath != null) {
          // Notify the user using a system notification
          _showBackupCompletedNotification(backupPath);
        }
      }
    } catch (e) {
      log('Error during backup: $e');
      emit(HomeTabStateError(e.toString()));
    }
  }

  void _showBackupCompletedNotification(String backupPath) {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('channel_id', 'Backup Notifications',
            channelDescription: 'Channel for backup completion notifications',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    flutterLocalNotificationsPlugin.show(
        0,
        'تم عمل نسخ احتياطي يومي',
        'Backup completed successfully at $backupPath',
        platformChannelSpecifics,
        payload: backupPath);
  }

  Future<void> getLast20Invo() async {
    try {
      emit(HomeTabStateLoading());
      lastInvoices = await invoiceRepo.getLast20Invoices();
      emit(HomeTabSuccessState());
    } catch (e) {
      emit(HomeTabStateError(e.toString()));
    }
  }

  // Daily summary methods

  double calculateDailySales() {
    List<Invoice> dailyInvoices = _getFilteredInvoicesByDay();
    return _calculateTotalSalesForInvoices(dailyInvoices);
  }

  double calculateDailyDiscounts() {
    List<Invoice> dailyInvoices = _getFilteredInvoicesByDay();
    return _calculateTotalDiscountsForInvoices(dailyInvoices);
  }

  double calculateDailyCost() {
    List<Invoice> dailyInvoices = _getFilteredInvoicesByDay();
    return _totalCostOfProductsFromInvoices(dailyInvoices);
  }

  double calculateDailyProfit() {
    List<Invoice> dailyInvoices = _getFilteredInvoicesByDay();
    double sales = _calculateTotalSalesForInvoices(dailyInvoices);
    double cost = _totalCostOfProductsFromInvoices(dailyInvoices);
    double discounts = _calculateTotalDiscountsForInvoices(dailyInvoices);
    return sales - cost - discounts;
  }

  // Private helper methods for calculation

  List<Invoice> _getFilteredInvoicesByDay() {
    DateTime now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month, now.day);
    DateTime endDate = startDate.add(const Duration(days: 1));

    return invoices.where((invoice) {
      return invoice.date.isAfter(startDate) && invoice.date.isBefore(endDate);
    }).toList();
  }

  double _calculateTotalSalesForInvoices(List<Invoice> invoices) {
    double total = 0.0;
    for (var invoice in invoices) {
      for (var product in invoice.products) {
        if (!product.isRefunded && !product.isReplaced) {
          total += double.parse(product.salary!);
        }
      }
    }
    return total;
  }

  double _calculateTotalDiscountsForInvoices(List<Invoice> invoices) {
    double total = 0.0;
    for (var invoice in invoices) {
      double totalPriceBeforeDiscount = invoice.products.fold(
          0,
          (sum, product) =>
              sum +
              (product.isRefunded || product.isReplaced
                  ? 0.0
                  : double.parse(product.salary!)));
      double totalDiscount = double.parse(invoice.discount);

      for (var product in invoice.products) {
        if (!product.isRefunded && !product.isReplaced) {
          double proportion =
              double.parse(product.salary!) / totalPriceBeforeDiscount;
          double productDiscount = totalDiscount * proportion;
          total += productDiscount;
        }
      }
    }
    return total;
  }

  double _totalCostOfProductsFromInvoices(List<Invoice> invoices) {
    double total = 0.0;
    for (var invoice in invoices) {
      for (var product in invoice.products) {
        if (!product.isRefunded && !product.isReplaced) {
          total += double.parse(product.cost!);
        }
      }
    }
    return total;
  }
}
