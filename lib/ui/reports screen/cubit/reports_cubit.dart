import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/data/model/expense_model.dart';
import 'package:flutter_application_1/data/repositories/auth_repo_impl.dart';
import 'package:flutter_application_1/data/repositories/expense_repo_impl.dart';
import 'package:flutter_application_1/domain/repositories/auth_repo.dart';
import 'package:flutter_application_1/domain/repositories/expense_repo.dart';
import 'package:flutter_application_1/domain/repositories/operation_repo.dart';
import 'package:flutter_application_1/ui/widgets/invoice_details_design.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/model/invoice_model.dart';
import '../../../data/model/manager_model.dart';
import '../../../data/model/operation_model.dart';
import '../../../data/model/product_model.dart';
import '../../../data/repositories/invoice_repo_impl.dart';
import '../../../data/repositories/operation_repo_impl.dart';
import '../../../data/repositories/products_repo_impl.dart';
import '../../../domain/repositories/invoice_repo.dart';
import '../../../domain/repositories/products_repo.dart';
import '../../../domain/utils.dart';
import '../../widgets/generate_and_download.dart';
import '../../widgets/invoices_reports_design.dart';
import 'reports_states.dart';
import 'package:flutter/material.dart';
import 'dart:developer';

class ReportsCubit extends Cubit<ReportsStates> {
  List<Invoice> invoices = [];
  List<Operation> operations = [];
  List<Operation> lastWeakperations = [];
  List<Invoice> allInvoices = [];
  List<Expense> expenses = []; // List to hold the expenses
  DateTimeRange? selectedDateRange;
  String? filterOption;
  String? sortOption;
  String? productStatusFilterOption;
  String searchQuery = '';
  InvoiceRepo invoiceRepo = InvoiceRepoImpl();
  OperationRepo operationRepo = OperationRepoImpl();
  ProductsRepo productsRepo = ProductsRepoImpl();
  ExpenseRepo expenseRepo =
      ExpenseRepoImpl(); // Assuming you have an ExpenseRepo for expenses

  AuthRepo authRepo = AuthRepoImpl();
  bool isGeneratingReport = false;
  bool isViewingProductReport = false;
  ManagerModel? manager;

  ReportsCubit() : super(ReportsInitState());

  void getManagerData() {
    emit(ReportsLoadingState());
    authRepo.fetchManagerData().then((onValue) {
      manager = onValue;
      emit(ReportsSuccessState());
    }).catchError((onError) {
      emit(ReportsErrorState(onError.toString()));
    });
  }

  Future<List<Operation>> getOperationsSinceInstallation() async {
    try {
      emit(ReportsLoadingState());

      final operations = await operationRepo.getOperationsSinceInstallation();

      emit(ReportsSuccessState());
      return operations;
    } catch (e) {
      emit(ReportsErrorState(e.toString()));
      return [];
    }
  }

  void setFilterOption(String option) {
    filterOption = option;
    log(filterOption ?? 'nooooooo');
    emit(ReportsSuccessState());
  }

  void setSortOption(String option) {
    sortOption = option;
    emit(ReportsSuccessState());
  }

  void setDateRange(DateTimeRange dateRange) {
    selectedDateRange = dateRange;
    emit(ReportsSuccessState());
  }

  // Set the product status filter
  void setProductStatusFilter(String status) {
    productStatusFilterOption = status;
    emit(ReportsSuccessState());
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    invoices = allInvoices.where((invoice) {
      return invoice.clientModel!.clientName.contains(query) ||
          invoice.invoiceId.contains(query);
    }).toList();
    emit(ReportsSuccessState());
  }

  void setSearchDecimalQuery(String barcodeQuery) {
    try {
      log('barcodeQuery $barcodeQuery');
      // Decode the Base64 encoded search query to retrieve the original invoice ID

      // Filter invoices by matching the decoded invoice ID
      invoices = allInvoices.where((invoice) {
        log(invoice.invoiceId);
        final String invoiceBarcode =
            invoice.invoiceId; // Assuming invoiceId is a String
        final double decimalBarcode =
            double.parse(invoiceBarcode.hashCode.toString());
        log('invoiceId $decimalBarcode');
        return decimalBarcode.toString() == barcodeQuery;
      }).toList();

      emit(ReportsSuccessState());
    } catch (e) {
      // If decoding fails, emit an error state or handle it appropriately
      emit(ReportsErrorState('Barcode not found or invalid.'));
    }
  }

  // Fetch expenses from Firebase
  void getAllExpenses() {
    emit(ReportsLoadingState());
    expenseRepo.getExpenses().then((onValue) {
      expenses = onValue;
      emit(ReportsSuccessState());
    }).catchError((onError) {
      emit(ReportsErrorState(onError.toString()));
    });
  }

  // Method to filter expenses by date
  // Method to filter expenses by date
List<Expense> getFilteredExpensesByTime() {
  DateTime now = DateTime.now();
  DateTime startDate;
  DateTime endDate;

  switch (filterOption) {
    case 'اليوم':
      startDate = DateTime(now.year, now.month, now.day);
      endDate = startDate.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)); // End of the day
      break;
    case 'الشهر الحالي':
      startDate = DateTime(now.year, now.month);
      endDate = DateTime(now.year, now.month + 1).subtract(const Duration(milliseconds: 1)); // End of the month
      break;
    case 'السنة الحالية':
      startDate = DateTime(now.year);
      endDate = DateTime(now.year + 1).subtract(const Duration(milliseconds: 1)); // End of the year
      break;
    case 'تاريخ مخصص':
      if (selectedDateRange != null) {
        startDate = DateTime(
          selectedDateRange!.start.year,
          selectedDateRange!.start.month,
          selectedDateRange!.start.day,
        );
        endDate = DateTime(
          selectedDateRange!.end.year,
          selectedDateRange!.end.month,
          selectedDateRange!.end.day,
        ).add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)); // End of the range
      } else {
        startDate = DateTime(2000);
        endDate = now;
      }
      break;
    default:
      startDate = DateTime(2000);
      endDate = now;
  }

  // Include expenses that match the date range inclusively
  return expenses.where((expense) {
    return (expense.date.isAtSameMomentAs(startDate) || expense.date.isAfter(startDate)) &&
           expense.date.isBefore(endDate);
  }).toList();
}


  List<Operation> getFilteredOperations() {
    DateTime now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (filterOption) {
      case 'اليوم':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
        break;
      case 'الشهر الحالي':
        startDate = DateTime(now.year, now.month);
        endDate = DateTime(now.year, now.month + 1);
        break;
      case 'السنة الحالية':
        startDate = DateTime(now.year);
        endDate = DateTime(now.year + 1);
        break;
      case 'تاريخ مخصص':
        if (selectedDateRange != null) {
          startDate = selectedDateRange!.start;
          endDate = selectedDateRange!.end.add(const Duration(days: 1));
        } else {
          return operations;
        }
        break;
      default:
        return operations;
    }

    return operations.where((operation) {
      return operation.date.isAfter(startDate) &&
          operation.date.isBefore(endDate);
    }).toList();
  }

  // Separate method to filter invoices based on product status
  List<Invoice> getFilteredInvoicesByProductStatus() {
    if (productStatusFilterOption == null ||
        productStatusFilterOption!.isEmpty) {
      return invoices; // No filtering if no option is selected
    }

    return invoices.where((invoice) {
      // Check each product in the invoice for the selected product status
      return invoice.products.any((product) {
        switch (productStatusFilterOption) {
          case 'تحتوي علي منتج بديل':
            return product.isReplacedDone;
          case 'تحتوي علي منتج مستبدل':
            return product.isReplaced;
          case 'تحتوي علي منتج مسترجع':
            return product.isRefunded;
          case 'بدون عمليات':
            return !product.isReplacedDone &&
                !product.isReplaced &&
                !product.isRefunded;
          default:
            return false;
        }
      });
    }).toList();
  }

  List<Invoice> getFilteredInvoices() {
    // Step 1: Filter based on the time or date range first
    List<Invoice> filteredInvoices = getFilteredInvoicesByTime();

    // Step 2: Apply the product status filter on the filtered invoices from Step 1
    if (productStatusFilterOption != null &&
        productStatusFilterOption!.isNotEmpty) {
      filteredInvoices = filteredInvoices.where((invoice) {
        return invoice.products.any((product) {
          switch (productStatusFilterOption) {
            case 'تحتوي علي منتج بديل':
              return product.isReplacedDone;
            case 'تحتوي علي منتج مستبدل':
              return product.isReplaced;
            case 'تحتوي علي منتج مسترجع':
              return product.isRefunded;
            case 'بدون عمليات': // Without operations - exclude any with operations
              // Ensuring that the invoice is excluded if even one product has operations
              return invoice.products.every((product) =>
                  !product.isReplacedDone &&
                  !product.isReplaced &&
                  !product.isRefunded);
            default:
              return true;
          }
        });
      }).toList();
    }

    return filteredInvoices;
  }

  // Existing method for filtering invoices by time/date
List<Invoice> getFilteredInvoicesByTime() {
  DateTime now = DateTime.now();
  DateTime startDate;
  DateTime endDate;

  switch (filterOption) {
    case 'اليوم':
      startDate = DateTime(now.year, now.month, now.day);
      endDate = startDate.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
      break;
    case 'الشهر الحالي':
      startDate = DateTime(now.year, now.month);
      endDate = DateTime(now.year, now.month + 1).subtract(const Duration(milliseconds: 1));
      break;
    case 'السنة الحالية':
      startDate = DateTime(now.year);
      endDate = DateTime(now.year + 1).subtract(const Duration(milliseconds: 1));
      break;
    case 'تاريخ مخصص':
      if (selectedDateRange != null) {
        startDate = DateTime(
          selectedDateRange!.start.year,
          selectedDateRange!.start.month,
          selectedDateRange!.start.day,
        );
        endDate = DateTime(
          selectedDateRange!.end.year,
          selectedDateRange!.end.month,
          selectedDateRange!.end.day,
        ).add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
      } else {
        startDate = DateTime(2000);
        endDate = now;
      }
      break;
    default:
      startDate = DateTime(2000);
      endDate = now;
  }

  return invoices.where((invoice) {
    return (invoice.date.isAtSameMomentAs(startDate) || invoice.date.isAfter(startDate)) &&
           invoice.date.isBefore(endDate);
  }).toList();
}

  void fetchOperations() async {
    try {
      emit(ReportsLoadingState());
      operations = await operationRepo.getOperations();
      emit(ReportsSuccessState());
    } catch (e) {
      emit(ReportsErrorState(e.toString()));
    }
  }

  void getAllInvoices() {
    emit(ReportsLoadingState());
    invoiceRepo.getInvoices().then((onValue) {
      invoices = onValue;
      allInvoices = onValue; // Keep the original list of invoices
      emit(ReportsSuccessState());
    }).catchError((onError) {
      emit(ReportsErrorState(onError.toString()));
    });
  }

  Future<Invoice?> getInvoiceById(String invoiceId) async {
    try {
      emit(ReportsLoadingState());
      Invoice? invoice = await invoiceRepo.getInvoiceById(invoiceId);
      emit(ReportsSuccessState());
      return invoice;
    } catch (e) {
      emit(ReportsErrorState(e.toString()));
      return null;
    }
  }

  Future<double> calculateTotalExpenses(List<Expense> expenses) async {
    double totalExpenses = 0.0;

    for (var doc in expenses) {
      totalExpenses += doc.amount;
    }

    return totalExpenses;
  }

  Future<Invoice?> fetchInvoiceByProductId(String productId) async {
    try {
      emit(ReportsLoadingState());
      Invoice? invoice =
          await invoiceRepo.fetchInvoiceByOldProductId(productId);
      emit(ReportsSuccessState());
      return invoice;
    } catch (e) {
      emit(ReportsErrorState(e.toString()));
      return null;
    }
  }

  Future<void> handleReturnProduct(String invoiceId, String productId,
      int index, BuildContext context) async {
    try {
      await invoiceRepo
          .returnProduct(invoiceId, productId, index, context)
          .then((onValue) async {
        final invoice = await invoiceRepo.getInvoiceById(invoiceId);
        operationRepo.logOperation(
            'إرجاع منتج في الفاتورة',
            'اسم المنتج: ${invoice!.products[index].name}\nفئة المنتج: ${invoice.products[index].category}\nاسم العميل: ${invoice.clientModel!.clientName}\nالتكلفة الكلية للفاتورة: ${invoice.totalCoast}\nالتكلفة السابقة: ${invoice.paidUp}',
            '',
            '');
      });
      emit(ReportsSuccessState());
    } catch (e) {
      emit(ReportsErrorState(e.toString()));
    }
  }

  Future<void> getTrashInvoices() async {
    try {
      emit(ReportsLoadingState());

      // Get all trash invoices from the repository
      List<Invoice> invoices = await invoiceRepo.getTrashInvoices();

      // Calculate the date 30 days ago
      DateTime thirtyDaysAgo =
          DateTime.now().subtract(const Duration(days: 30));

      // Filter out invoices that are older than 30 days
      List<Invoice> oldInvoices = invoices.where((invoice) {
        return invoice.trashDate!.isBefore(thirtyDaysAgo);
      }).toList();

      // Emit state with both all invoices and invoices older than 30 days
      emit(ReportsTrashState(invoices: invoices, oldInvoices: oldInvoices));
    } catch (e) {
      emit(ReportsErrorState(e.toString()));
    }
  }

  Future<void> deleteOldTrashInvoices() async {
    try {
      emit(ReportsLoadingState());
      await invoiceRepo.deleteOldInvoices();
      emit(ReportsSuccessState());
    } catch (e) {
      emit(ReportsErrorState(e.toString()));
    }
  }

  Future<Invoice?> fetchInvoiceByOldProductId(String oldProductId) async {
    try {
      emit(ReportsLoadingState());
      Invoice? invoice =
          await invoiceRepo.fetchInvoiceByOldProductId(oldProductId);
      emit(ReportsSuccessState());
      return invoice;
    } catch (e) {
      emit(ReportsErrorState(e.toString()));
      return null;
    }
  }

  Future<void> handleDeleteInvoice(String invoiceId) async {
    try {
      Invoice? deletInvo = await invoiceRepo.getInvoiceById(invoiceId);
      await invoiceRepo.deleteInvoice(invoiceId).then((_) {
        operationRepo.logOperation(
            'حذف فاتورة',
            'كود الفاتورة: ${deletInvo?.invoiceId.substring(0, 12) ?? 'no id'}\nالفاتورة باسم: ${deletInvo?.clientModel?.clientName ?? 'بلا اسم'}\nالفاتورة بسعر صافي: ${formattedNumber(double.parse(deletInvo?.paidUp ?? '0.0'))} د.ع',
            '',
            '');
      });
      getAllInvoices();
    } catch (e) {
      emit(ReportsErrorState(e.toString()));
    }
  }

  Future<void> moveToTrash(String invoiceId) async {
    try {
      emit(ReportsLoadingState());
      await invoiceRepo.moveToTrash(invoiceId);
      getAllInvoices();
    } catch (e) {
      emit(ReportsErrorState(e.toString()));
    }
  }

  Future<void> restoreInvoice(String invoiceId) async {
    try {
      emit(ReportsLoadingState());
      await invoiceRepo.restoreInvoice(invoiceId);
      getTrashInvoices();
    } catch (e) {
      emit(ReportsErrorState(e.toString()));
    }
  }

  List<Product> getProductsFromInvoices(List<Invoice> invo) {
    List<Product> products = [];
    for (var invoice in invo) {
      products.addAll(invoice.products);
    }
    return products;
  }

  double calculateTotalSalesForInvoices(List<Invoice> invoices) {
    double total = 0.0;
    for (var invoice in invoices) {
      for (var product in invoice.products) {
        if (!product.isRefunded && !product.isReplaced) {
          total += double.parse(product.salary!);
        }
      }
    }
    log("Total sales for invoice is $total");
    return total;
  }

  double calculateTotalDiscountsForInvoices(List<Invoice> invoices) {
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
    log("Total discounts for invoice is $total");
    return total;
  }

  double totalCostOfProductsFromInvoices(List<Invoice> invoices) {
    double total = 0.0;
    for (var invoice in invoices) {
      for (var product in invoice.products) {
        if (!product.isRefunded && !product.isReplaced) {
          total += double.parse(product.cost!);
        }
      }
    }
    log("Total cost of production is $total");
    return total;
  }

  double totalSalaryOfProductsFromInvoices(List<Invoice> invoices) {
    double total = 0.0;
    for (var invoice in invoices) {
      for (var product in invoice.products) {
        if (!product.isRefunded && !product.isReplaced) {
          total += double.parse(product.salary!);
        }
      }
    }
    log("Total salary of products is $total");
    return total;
  }

  Future<void> invoiceReport(List<Invoice> invoices, ReportsCubit reportsCubit,
      Set<String> selectedOptions) async {
    isGeneratingReport = true;
    emit(ReportsSuccessState());
    DateTime startDate = selectedDateRange?.start ?? DateTime(2000);
    DateTime endDate = selectedDateRange?.end ?? DateTime.now();

    await Future.delayed(const Duration(seconds: 2), () {
      // Generate the invoice report with the selected options
      generateInvoiceReport(
          invoices, reportsCubit, startDate, endDate, selectedOptions);
    });

    isGeneratingReport = false;
    emit(ReportsSuccessState());
  }

  Future<void> viewProductReport(List<Invoice> invoices) async {
    isViewingProductReport = true;
    emit(ReportsSuccessState());
    await Future.delayed(const Duration(seconds: 2));
    isViewingProductReport = false;
    emit(ReportsSuccessState());
  }

  Future<void> generateAndSaveBDF(
    BuildContext context, // Add BuildContext parameter
    Invoice? invo,
    List<Product> prr,
    ManagerModel mang,
    String payMethod,
    bool isSaved,
    bool offline,
  ) async {
    if (invo != null) {
      try {
        emit(ReportsLoadingState());
        await generateAndDownloadPdf(invo, prr, mang, payMethod, offline)
            .then((_) {
          emit(ReportsSuccessState());
          // Check if the widget is still mounted
          if (context.mounted) {
            showSnackbar(context, 'تم الحفظ بنجاح في مسار Download الخاص بك');
          }
        }).catchError((onError) {
          emit(ReportsErrorState(onError.toString()));
        });
      } catch (e) {
        emit(ReportsErrorState(e.toString()));
      }
    } else {
      emit(ReportsErrorState('لا توجد فاتورة'));
    }
  }

  Future<void> generateAndprintBDF(Invoice? invo, List<Product> prr,
      ManagerModel mang, String payMethod, bool isSaved, bool offline) async {
    if (invo != null) {
      try {
        emit(ReportsLoadingState());
        await generatePdf(invo, prr, mang, payMethod, offline).then((_) {
          emit(ReportsSuccessState());
        }).catchError((onError) {
          emit(ReportsErrorState(onError.toString()));
        });
      } catch (e) {
        emit(ReportsErrorState(e.toString()));
      }
    } else {
      emit(ReportsErrorState('لا توجد فاتورة'));
    }
  }
}
