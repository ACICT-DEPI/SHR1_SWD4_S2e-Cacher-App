import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:connectivity_checker/connectivity_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/domain/utils.dart';
import 'package:flutter_application_1/ui/widgets/invoice_details_design.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/data/repositories/operation_repo_impl.dart';
import 'package:flutter_application_1/domain/repositories/operation_repo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../data/model/cleints_model.dart';
import '../../../data/model/invoice_model.dart';
import '../../../data/model/manager_model.dart';
import '../../../data/model/product_model.dart';
import '../../../data/repositories/auth_repo_impl.dart';
import '../../../data/repositories/invoice_repo_impl.dart';
import '../../../data/repositories/products_repo_impl.dart';
import '../../../domain/repositories/auth_repo.dart';
import '../../../domain/repositories/invoice_repo.dart';
import '../../../domain/repositories/products_repo.dart';
import '../../categories screen/cubit/product_cubit.dart';
import 'invoice_states.dart';

class InvoiceCubit extends Cubit<InvoiceStates> {
  InvoiceCubit() : super(InvoiceStates());

  InvoiceRepo invoicesRepo = InvoiceRepoImpl();
  AuthRepo authRepo = AuthRepoImpl();
  ProductsRepo productsRepo = ProductsRepoImpl();
  ProductCubit productCubit = ProductCubit();
  OperationRepo operationRepo = OperationRepoImpl();

  TextEditingController logoUrl = TextEditingController();
  TextEditingController buyerName = TextEditingController();
  TextEditingController buyerNumber = TextEditingController();
  TextEditingController buyerAddress = TextEditingController();
  TextEditingController paymentMethod = TextEditingController();
  TextEditingController discountAmount = TextEditingController();
  Map<String, int> productCounts = {};
  bool showPaidUpField = false;
  bool isExistingCustomer = true;
  List<Product> products = [];
  List<Product> filteredProducts = [];
  List<Invoice> invoices = [];
  List<ClientModel> clients = [];
  List<ClientModel> filteredClients = [];
  List<Product> selectedProducts = [];
  List<Map<String, dynamic>> offlineUpdates = [];
  Invoice? invoice;
  ManagerModel? manager;
  bool isOffline = false;

  ClientModel? selectedClient;

  Map<String, bool> productLoadingStates = {};

  Product? latestQuickProduct;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  Invoice? originalInvoice;
  Invoice? replacementInvoice;

  bool isSaving = false;
  bool isExporting = false;

  int newQuantity = 0;

  int updatedqq = 0;

  // New State Variables
  String selectedDiscountType = 'quantity';
  double discount = 0.0;
  double total = 0.0;
  double net = 0.0;

  bool _isButtonDisabled = false;
  bool get isButtonDisabled => _isButtonDisabled;

  void setButtonDisabled(bool disabled) {
    _isButtonDisabled = disabled;
    emit(InvoiceStateUpdated());
  }

  Future<bool> checkInternet() async {
    try {
      emit(InvoiceStateLoading()); // Default to offline
      isOffline = !(await ConnectivityWrapper.instance.isConnected);
      emit(InvoiceStateSuccess());
      return isOffline;
    } catch (e) {
      emit(InvoiceStateError(e.toString()));
      return true; // Assume offline if there's an error
    }
  }

  Future<List<Invoice>> getInvoicesSinceInstallation() async {
    try {
      final List<Invoice> invoices =
          await invoicesRepo.getInvoicesSinceInstallation();

      return invoices;
    } catch (e) {
      return [];
    }
  }

  Future<List<Product>> getAllProductsSinceInstallation() async {
    try {
      final List<Product> products = await productsRepo.getProducts();
      return products;
    } catch (e) {
      return [];
    }
  }

  void getProducts() async {
    try {
      emit(InvoiceStateLoading());

      products = await productsRepo.getProducts();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final offlineData = prefs.getStringList('offline_updates') ?? [];

      if (offlineData.isNotEmpty) {
        for (String data in offlineData) {
          final parsedData = Map<String, dynamic>.from(json.decode(data));
          final barcode = parsedData['barcode'];
          final quantity = parsedData['quantity'];

          final product = products.firstWhere(
            (prod) => prod.parcode == barcode,
            orElse: () => Product(
                isRefunded: false,
                isReplaced: false,
                isReplacedDone:
                    false), // Return null or handle it appropriately
          );

          if (product != null) {
            product.quantity = quantity.toString();
          } else {
            log('Product with barcode $barcode not found in the list');
          }
        }
      }

      filteredProducts = products;
      emit(InvoiceStateSuccess());
    } catch (e) {
      log('Error in invoice get: $e');
      emit(InvoiceStateError(e.toString()));
    }
  }

  void searchProducts(String query) {
    final lowerCaseQuery = query.toLowerCase();
    filteredProducts = products.where((product) {
      return product.parcode!.contains(lowerCaseQuery) ||
          product.category!.toLowerCase().contains(lowerCaseQuery);
    }).toList();
    emit(InvoiceStateSuccess());
  }

  void getCustomers() {
    try {
      emit(InvoiceStateLoading());
      invoicesRepo.getAllClientInfo().then((onValue) {
        clients = onValue;
        filteredClients = clients;
        emit(InvoiceStateSuccess());
      }).catchError((onError) {
        emit(InvoiceStateError(onError.toString()));
      });
    } catch (e) {
      emit(InvoiceStateError(e.toString()));
    }
  }

  void filterClients(String query) {
    final lowerCaseQuery = query.toLowerCase();
    filteredClients = clients.where((client) {
      return client.clientName.toLowerCase().contains(lowerCaseQuery);
    }).toList();
    emit(InvoiceStateSuccess());
  }

  void getManagerData() {
    emit(ManagerStateLoading());
    authRepo.fetchManagerData().then((onValue) {
      manager = onValue;
      emit(ManagerStateSuccess());
    }).catchError((onError) {
      emit(ManagerStateError(onError.toString()));
    });
  }

  double totalCost(List<Product> productsAdded) {
    double total = 0;
    for (var product in productsAdded) {
      total += double.parse(product.salary!);
    }
    return total;
  }

  void showQuantityExpiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('خطأ في الكمية'),
            content: const Text('الكمية المتوفرة من المنتج غير كافية.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('موافق'),
              ),
            ],
          ),
        );
      },
    );
  }

  void incrementLocalProductCount(
      Product product, int quantity, BuildContext context) {
    final productKey =
        product.productId ?? product.parcode; // Ensure consistent key usage

    if (productKey != null) {
      newQuantity = (productCounts[productKey] ?? 0) + quantity;

      if (product.category == 'منتج سريع' ||
          newQuantity <= int.parse(product.quantity!)) {
        productCounts[productKey] = newQuantity;
        if (!selectedProducts.contains(product)) {
          selectedProducts.add(product);
        }
        emit(InvoiceStateSuccess()); // Emit new state to trigger UI update
      } else {
        showQuantityExpiredDialog(context);
      }
    } else {
      log("Error: Product does not have a valid identifier.");
    }
  }

  void decrementLocalProductCount(Product product, int quantity) {
    final productKey = product.productId ?? product.parcode;
    if (productCounts.containsKey(productKey)) {
      productCounts[productKey!] = (productCounts[productKey]! - quantity)
          .clamp(0, double.infinity)
          .toInt();
      if (productCounts[productKey] == 0) {
        productCounts.remove(productKey);
        selectedProducts.remove(product);
      }
      emit(InvoiceStateSuccess()); // Emit new state to trigger UI update
    }
  }

  //TODO: solve here
  void refreshProductList(Product product) {
    if (product.category == 'منتج سريع') {
      // Remove any existing quick products from the list
      products.removeWhere((p) => p.category == 'منتج سريع');
      filteredProducts.removeWhere((p) => p.category == 'منتج سريع');

      // Add the new quick product only to products list
      products.add(product);

      // Store the latest quick product
      latestQuickProduct = product;

      // Initialize the product count for the quick product
      productCounts[product.productId ?? product.parcode!] = 0;
    } else {
      // For non-quick products, add to selected products as before
      selectedProducts.add(product);
    }

    emit(InvoiceStateSuccess());
  }

  void selectExistingCustomer(ClientModel client) {
    isExistingCustomer = true;
    selectedClient = client;
    buyerName.text = client.clientName;
    buyerNumber.text = client.clientPhone;
    buyerAddress.text = client.cleintAddress;
    emit(InvoiceStateSuccess());
  }

  void selectNewCustomer() {
    isExistingCustomer = false;
    log('$isExistingCustomer');
    buyerName.clear();
    buyerNumber.clear();
    buyerAddress.clear();
    emit(InvoiceStateSuccess());
  }

  Future<void> syncOfflineUpdates() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final offlineData = prefs.getStringList('offline_updates') ?? [];

  if (offlineData.isNotEmpty) {
    for (String data in offlineData) {
      final parsedData = Map<String, dynamic>.from(json.decode(data));
      final barcode = parsedData['barcode'];
      final quantity = parsedData['quantity'];

      // Sync to Firebase
      await productsRepo.updateProductQuantity(barcode, quantity);
      log('Synced product $barcode with quantity $quantity to Firebase.');
    }
    
    // Clear offline updates after syncing
    await prefs.remove('offline_updates');
  }
}


  // Add this method to sync offline updates
  Future<void> addInvoice(
  String oldInvoiId,
  List<Product> productsAdded,
  bool tasdear,
  BuildContext context,
  String oldClientId,
  String? oldProductId, // This now receives the oldProductId
) async {
  emit(InvoiceStateLoading());

  bool isOffline = !(await ConnectivityWrapper.instance.isConnected);

  final invoiceId = const Uuid().v4();
  final clientId = oldClientId.isEmpty
      ? selectedClient?.clientId ?? const Uuid().v4()
      : oldClientId;

  int numOfBuyings = productsAdded.length;

  // Calculate total cost, discount, and net
  total = totalCost(productsAdded);
  calculateNetTotal();

  double discountAmount = selectedDiscountType == 'quantity'
      ? discount
      : total * (discount / 100);

  final newInvoice = Invoice(
    invoiceId: invoiceId,
    clientModel: ClientModel(
        clientId: clientId,
        clientName: buyerName.text.isEmpty ? 'مجهول' : buyerName.text,
        cleintAddress: buyerAddress.text.isEmpty ? 'مجهول' : buyerAddress.text,
        clientPhone: buyerNumber.text.isEmpty ? 'مجهول' : buyerNumber.text),
    paidUp: totalCost(productsAdded).toString(),
    paymentMethod: paymentMethod.text,
    firstDiscount: discountAmount.toString(),
    discount: discountAmount.toString(),
    numOfBuyings: numOfBuyings,
    totalCoast: net,
    managerId: FirebaseAuth.instance.currentUser!.uid,
    logoUrl: manager?.logoPath! ?? 'no path',
    products: productsAdded,
    date: DateTime.now(),
    oldProductId: oldProductId, // Assign oldProductId here if relevant
    replacedinvoiceId: oldInvoiId, // Assign oldInvoiId here if relevant
  );

  invoice = newInvoice;

  for (var entry in productCounts.entries) {
    final productId = entry.key;
    final count = entry.value;
    final product = products.firstWhere((prod) => prod.productId == productId);
    int newQuantity = int.parse(product.quantity!) - count;

    if (newQuantity >= 0) {
      if (isOffline) {
        // Store updates offline
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final offlineUpdates = prefs.getStringList('offline_updates') ?? [];
        offlineUpdates.add(json.encode({
          'barcode': product.parcode,
          'quantity': newQuantity,
        }));
        await prefs.setStringList('offline_updates', offlineUpdates);
        log('Stored offline update for product: ${product.parcode} with quantity $newQuantity');

        // Update product quantity in local state
        product.quantity = newQuantity.toString();  // This updates the product in-memory
        emit(InvoiceStateSuccess());  // Emit success to trigger UI update
        log('update product in offline');
      } else {
        // Directly update the product quantity in online mode
        log('update product in online');
        await productsRepo.updateProductQuantity(product.parcode!, newQuantity);
      }
    } else {
      emit(InvoiceStateError('لا توجد كمية كافية'));
      isSaving = false;
      return;
    }
  }

  emit(InvoiceStateSuccess());

  if (isOffline) {
    // Offline logic for saving the invoice
    emit(AddInvoiceLoading());

    await Future.delayed(const Duration(seconds: 5), () async {
      isSaving = true;

      try {
        await Future.any([
          invoicesRepo.createInvoice(newInvoice).then((onValue) {
            operationRepo.logOperation(
                'إضافة فاتورة',
                'تم إضافة فاتورة جديدة:\n'
                    'كود الفاتورة: ${newInvoice.invoiceId.substring(0, 12)}\n'
                    'اسم العميل: ${newInvoice.clientModel?.clientName ?? 'غير معروف'}\n'
                    'رقم الهاتف: ${newInvoice.clientModel?.clientPhone ?? 'غير معروف'}\n'
                    'عنوان العميل: ${newInvoice.clientModel?.cleintAddress ?? 'غير معروف'}\n'
                    'طريقة الدفع: ${newInvoice.paymentMethod}\n'
                    'الخصم: ${formattedNumber(double.parse(newInvoice.discount))} د.ع\n'
                    'التكلفة الكلية: ${formattedNumber(double.parse(newInvoice.paidUp))} د.ع\n'
                    'التكلفة النهائية: ${formattedNumber(newInvoice.totalCoast)} د.ع\n'
                    'التاريخ: ${intl.DateFormat('yyyy/MM/dd').format(newInvoice.date)}\n\n'
                    'المنتجات:\n${_generateProductListString(newInvoice.products)}',
                '',
                '');
          }),
          Future.delayed(const Duration(seconds: 5),
              () => throw TimeoutException('createInvoice timed out'))
        ]);

        invoice = newInvoice;
        isSaving = false;
        emit(InvoiceStateOfflineSuccess());
      } catch (error) {
        emit(InvoiceStateError('Error in adding invoice: $error'));
        isSaving = false;
      }
    });
  } else {
    // Online logic for saving the invoice
    isSaving = true;
    emit(InvoiceStateLoading());

    try {
      await invoicesRepo.createInvoice(newInvoice).then((onValue) {
        operationRepo.logOperation(
            'إضافة فاتورة',
            'تم إضافة فاتورة جديدة:\n'
                'كود الفاتورة: ${newInvoice.invoiceId.substring(0, 12)}\n'
                'اسم العميل: ${newInvoice.clientModel?.clientName ?? 'غير معروف'}\n'
                'رقم الهاتف: ${newInvoice.clientModel?.clientPhone ?? 'غير معروف'}\n'
                'عنوان العميل: ${newInvoice.clientModel?.cleintAddress ?? 'غير معروف'}\n'
                'طريقة الدفع: ${newInvoice.paymentMethod}\n'
                'الخصم: ${formattedNumber(double.parse(newInvoice.discount))} د.ع\n'
                'التكلفة الكلية: ${formattedNumber(double.parse(newInvoice.paidUp))} د.ع\n'
                'التكلفة النهائية: ${formattedNumber(newInvoice.totalCoast)} د.ع\n'
                'التاريخ: ${intl.DateFormat('yyyy/MM/dd').format(newInvoice.date)}\n\n'
                'المنتجات:\n${_generateProductListString(newInvoice.products)}',
            '',
            '');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت إضافة الفاتورة بنجاح'),
        ),
      );
      emit(InvoiceStateSuccess());
      isSaving = false;
    } catch (error) {
      emit(InvoiceStateError('Error in adding invoice: $error'));
      isSaving = false;
    }
  }
}




  String _generateProductListString(List<Product> products) {
    return products.map((product) {
      final profit =
          double.parse(product.salary!) - double.parse(product.cost!);
      return 'الاسم: ${product.name}\n'
          'الفئة: ${product.category}\n'
          'الباركود: ${product.parcode}\n'
          'الكمية: ${product.quantity}\n'
          'السعر: ${formattedNumber(double.parse(product.salary!))} د.ع\n'
          'التكلفة: ${formattedNumber(double.parse(product.cost!))} د.ع\n'
          'الربح: ${formattedNumber(profit)} د.ع\n'
          'تاريخ الإنشاء: ${intl.DateFormat('yyyy/MM/dd').format(product.createdDate!)}\n'
          '--------------\n';
    }).join('\n');
  }

  Future<void> generateBDF(Invoice? invo, List<Product> prr, ManagerModel mang,
      String payMethod, bool isSaved, bool offline) async {
    if (invo != null) {
      try {
        isExporting = true;
        emit(InvoiceStateLoading());
        await generatePdf(invo, prr, mang, payMethod, offline).then((_) {
          emit(offline ? InvoiceStateOfflineSuccess() : InvoiceStateSuccess());
          isExporting = false;
        }).catchError((onError) {
          emit(InvoiceStateError(onError.toString()));
          isExporting = false;
        });
      } catch (e) {
        emit(InvoiceStateError(e.toString()));
        isExporting = false;
      }
    } else {
      emit(InvoiceStateError('لا توجد فاتورة'));
      isExporting = false;
    }
    prr.clear();
    productCounts.clear();
    buyerName.clear();
    buyerNumber.clear();
    buyerAddress.clear();
    paymentMethod.clear();
    discountAmount.clear();
    discount = 0.0;
    selectedDiscountType = 'quantity';
  }

  Future<void> handleExchangeProduct(
      String invoiceId,
      String oldProductId,
      String newProductId,
      BuildContext context,
      int oldProductIndex,
      String movedToInvoice) async {
    try {
      emit(InvoiceStateLoading());

      final isReplaced = await invoicesRepo.getProductById(oldProductId);
      final isReplacedWith = await invoicesRepo.getProductById(newProductId);

      log(invoiceId);
      log(movedToInvoice);

      if (isReplacedWith != null) {
        isReplacedWith.isReplacedDone = true;
        await invoicesRepo.exchangeProduct(invoiceId, oldProductId,
            newProductId, oldProductIndex, context, movedToInvoice);

        log(invoiceId);
        log(movedToInvoice);

        await operationRepo.logOperation(
          'استبدال منتج',
          'تم استبدال المنتج:\n'
              'الاسم: ${isReplaced!.name}\n'
              'الفئة: ${isReplaced.category}\n'
              'الباركود: ${isReplaced.parcode}\n'
              'الكمية: ${isReplaced.quantity}\n'
              'السعر: ${formattedNumber(double.parse(isReplaced.salary!))} د.ع\n'
              'التكلفة: ${formattedNumber(double.parse(isReplaced.cost!))} د.ع\n'
              'الربح: ${formattedNumber(isReplaced.profit!)} د.ع\n'
              'تاريخ الإنشاء: ${intl.DateFormat('yyyy/MM/dd').format(isReplaced.createdDate!)}\n\n'
              'بالمنتج:\n'
              'الاسم: ${isReplacedWith.name}\n'
              'الفئة: ${isReplacedWith.category}\n'
              'الباركود: ${isReplacedWith.parcode}\n'
              'الكمية: ${isReplacedWith.quantity}\n'
              'السعر: ${formattedNumber(double.parse(isReplacedWith.salary!))} د.ع\n'
              'التكلفة: ${formattedNumber(double.parse(isReplacedWith.cost!))} د.ع\n'
              'الربح: ${formattedNumber(isReplacedWith.profit!)} د.ع\n'
              'تاريخ الإنشاء: ${intl.DateFormat('yyyy/MM/dd').format(isReplacedWith.createdDate!)}',
          invoiceId,
          movedToInvoice,
        );
      }

      emit(InvoiceStateSuccess());
    } catch (e) {
      emit(InvoiceStateError(e.toString()));
    }
  }

  // New methods for discount type selection and calculation
  void selectDiscountType(String type) {
    selectedDiscountType = type;
    calculateNetTotal();
    emit(InvoiceUpdatedState());
  }

  void updateDiscount(String value) {
    discount = double.tryParse(value) ?? 0.0;
    calculateNetTotal();
    emit(InvoiceUpdatedState());
  }

  void calculateNetTotal() {
    total = productCounts.entries.fold(0.0, (sum, entry) {
      final product =
          products.firstWhere((prod) => prod.productId == entry.key);
      return sum + (entry.value * double.parse(product.salary!));
    });
    if (selectedDiscountType == 'quantity') {
      net = total - discount;
    } else {
      net = total - (total * (discount / 100));
    }
  }
}
