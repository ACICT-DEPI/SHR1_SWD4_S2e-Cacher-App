import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/repositories/category_repo_impl.dart';
import 'package:flutter_application_1/data/repositories/operation_repo_impl.dart';
import 'package:flutter_application_1/domain/utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/model/invoice_model.dart';
import '../../../data/model/product_model.dart';
import '../../../data/repositories/invoice_repo_impl.dart';
import '../../../data/repositories/products_repo_impl.dart';
import '../../../domain/repositories/invoice_repo.dart';
import '../../../domain/repositories/products_repo.dart';
import '../../../domain/repositories/category_repo.dart';
import '../../../domain/repositories/operation_repo.dart';
import '../../bill screen/cubit/invoice_cubit.dart';
import 'products_state.dart';

class ProductCubit extends Cubit<ProductsState> {
  ProductCubit() : super(ProductsState());
  ProductsRepo productsRepo = ProductsRepoImpl();
  CategoryRepo categoryRepo = CategoryRepoImpl();
  OperationRepo operationRepo = OperationRepoImpl();
  TextEditingController name = TextEditingController();
  TextEditingController category = TextEditingController();
  TextEditingController parcode = TextEditingController();
  TextEditingController quantity = TextEditingController();
  TextEditingController salary = TextEditingController();
  TextEditingController cost = TextEditingController();
  final formKey = GlobalKey<FormBuilderState>();
  List<Product> products = [];
  List<String> categories = [];
  List<String> getCategories = [];
  List<Product> filteredProducts = [];
  List<Product> latestProducts = [];
  List<Product> lowStockProducts = [];
  List<Product> outOfStockProducts = [];
  List<String> expandedCategories = [];
  Product? product;

  final InvoiceRepo invoiceRepo = InvoiceRepoImpl();
  String? filterOption;
  DateTimeRange? dateRange;

  // Set filter option (e.g., "اليوم", "الشهر الحالي", etc.)
  void setFilterOption(String option) {
    filterOption = option;
    fetchAndFilterProducts();
  }

  // Set a custom date range for filtering
  void setDateRange(DateTimeRange range) {
    dateRange = range;
    fetchAndFilterProducts();
  }

  // Fetch and filter products based on invoices
  Future<void> fetchAndFilterProducts() async {
    try {
      emit(ProductsStateLoading());

      List<Invoice> invoices = await _fetchInvoicesByTimePeriod();
      Map<String, List<Product>> productSales = {};

      for (Invoice invoice in invoices) {
        print('Processing invoice: ${invoice.invoiceId}');
        for (Product product in invoice.products) {
          if (product.productId != null) {
            String productId = product.productId!;

            print('Product: ${product.name}, ID: $productId');

            if (!productSales.containsKey(productId)) {
              productSales[productId] = [];
            }

            productSales[productId]!.add(product);
          }
        }
      }

      filteredProducts = productSales.entries.map((entry) {
        String productId = entry.key;
        List<Product> products = entry.value;

        // We'll use the first product in the list for basic info
        Product firstProduct = products.first;

        return Product(
          productId: productId,
          name: firstProduct.name,
          category: firstProduct.category,
          quantity: products.length.toString(),
          parcode: firstProduct.parcode,
          salary: firstProduct.salary,
          cost: firstProduct.cost,
          profit: firstProduct.profit,
          firstQuantity: firstProduct.firstQuantity,
          isRefunded: firstProduct.isRefunded,
          isReplaced: firstProduct.isReplaced,
          isReplacedDone: firstProduct.isReplacedDone,
          createdDate: firstProduct.createdDate,
        );
      }).toList();

      filteredProducts.sort((a, b) {
        int aQuantity = int.tryParse(a.quantity ?? '0') ?? 0;
        int bQuantity = int.tryParse(b.quantity ?? '0') ?? 0;
        return bQuantity.compareTo(aQuantity);
      });

      for (var product in filteredProducts) {
        print('${product.name}: Quantity sold: ${product.quantity}');
      }

      emit(ProductsStateSuccess());
    } catch (e) {
      emit(ProductsStateError(e.toString()));
    }
  }

  // Helper function to fetch invoices based on the selected time period
  Future<List<Invoice>> _fetchInvoicesByTimePeriod() async {
    DateTime now = DateTime.now();
    DateTime startDate, endDate;

    if (filterOption == 'اليوم') {
      startDate = DateTime(now.year, now.month, now.day);
      endDate = startDate.add(const Duration(days: 1));
    } else if (filterOption == 'الشهر الحالي') {
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 1);
    } else if (filterOption == 'السنة الحالية') {
      startDate = DateTime(now.year, 1, 1);
      endDate = DateTime(now.year + 1, 1, 1);
    } else if (filterOption == 'تاريخ مخصص' && dateRange != null) {
      startDate = dateRange!.start;
      endDate = dateRange!.end.add(const Duration(days: 1));
    } else {
      // Default to fetching all invoices if no filter is applied
      startDate = DateTime(2000);
      endDate = DateTime(2100);
    }

    return await invoiceRepo.getInvoicesByDateRange(startDate, endDate);
  }

  void sortByLowestSelling() {
    filteredProducts.sort((a, b) {
      int aQuantity = int.tryParse(a.quantity ?? '0') ?? 0;
      int bQuantity = int.tryParse(b.quantity ?? '0') ?? 0;
      return aQuantity.compareTo(bQuantity); // Least sold first
    });
    emit(ProductsStateSuccess());
  }

  void sortByCategoryAlphabetically() {
    filteredProducts
        .sort((a, b) => (a.category ?? '').compareTo(b.category ?? ''));
    emit(ProductsStateSuccess());
  }

  void sortByLatestSale() {
    // Assuming `createdDate` is the sale date in the `Product` model
    filteredProducts.sort((a, b) => b.createdDate!.compareTo(a.createdDate!));
    emit(ProductsStateSuccess());
  }

  void fetchCategories() async {
    try {
      emit(CategoriesStateLoading());
      categories = await categoryRepo.getCategories();
      if (categories.isEmpty) {
        emit(CategoriesStateEmpty());
      } else {
        emit(CategoriesStateSuccess());
      }
    } catch (e) {
      emit(CategoriesStateError(e.toString()));
    }
  }

  void getProductsByCategory(String category) async {
    try {
      emit(ProductsStateLoading());
      products = await productsRepo.getProductsByCategory(category);
      await _applyOfflineUpdatesToList(products);
      if (products.isEmpty) {
        emit(ProductsStateEmpty());
      } else {
        filteredProducts = products;
        emit(ProductsStateSuccess());
      }
    } catch (e) {
      emit(ProductsStateError(e.toString()));
    }
  }

  void refreshProductList(Product product) {
    // Add the product to the list of filtered products
    filteredProducts.add(product);
    // Ensure the UI is aware of the new product
    emit(ProductsStateSuccess());
  }

  Future<void> addCategory(String categoryName) async {
    try {
      if (!categories.contains(categoryName)) {
        emit(CategoriesStateLoading());
        await categoryRepo.addCategory(categoryName);
        categories.add(categoryName);
        emit(CategoriesStateSuccess());
      }
    } catch (e) {
      emit(CategoriesStateError(e.toString()));
    }
  }

  Future<void> getOutOfStockProducts() async {
    try {
      emit(ProductsStateLoading());

      // Fetch all products from the repository
      List<Product> products = await productsRepo.getProducts();

      // Apply offline updates if any
      await _applyOfflineUpdatesToList(products);

      // Filter out products that are completely out of stock
      outOfStockProducts = products.where((product) {
        return int.parse(product.quantity!) == 0;
      }).toList();

      // Emit the appropriate state
      emit(ProductsStateSuccess());
    } catch (e) {
      emit(ProductsStateError(e.toString()));
    }
  }

  void getLatest20Products() async {
    try {
      emit(ProductsStateLoading());

      // Fetch the latest 20 products from the repository
      latestProducts = await productsRepo.getLatestProducts(limit: 20);

      // Apply offline updates if any
      await _applyOfflineUpdatesToList(latestProducts);

      // Emit the appropriate state
      if (latestProducts.isEmpty) {
        emit(ProductsStateEmpty());
      } else {
        emit(ProductsStateSuccess());
      }
    } catch (e) {
      emit(ProductsStateError(e.toString()));
    }
  }

  void deleteCategory(String categoryName) async {
    try {
      emit(CategoriesStateLoading());
      await categoryRepo.deleteCategory(categoryName);
      categories.remove(categoryName);
      if (categories.isEmpty) {
        emit(CategoriesStateEmpty());
      } else {
        emit(CategoriesStateSuccess());
      }
    } catch (e) {
      emit(CategoriesStateError(e.toString()));
    }
  }

  void sortByBestSelling() {
    filteredProducts.sort((a, b) {
      // Use 0 as a fallback value for null quantities
      double aFirstQuantity = a.firstQuantity ?? 0;
      double aQuantity = double.tryParse(a.quantity ?? '0') ?? 0;
      double bFirstQuantity = b.firstQuantity ?? 0;
      double bQuantity = double.tryParse(b.quantity ?? '0') ?? 0;

      return (bFirstQuantity - bQuantity).compareTo(aFirstQuantity - aQuantity);
    });
    emit(ProductsStateSuccess());
  }

  Future<void> getTopLowStockProducts() async {
    try {
      emit(ProductsStateLoading());

      // Fetch all products from the repository
      List<Product> products = await productsRepo.getProducts();

      // Apply offline updates if any
      await _applyOfflineUpdatesToList(products);

      // Load the threshold from shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int threshold = prefs.getInt('lowStockThreshold') ?? 10;

      // Filter and sort the products by quantity
      lowStockProducts = products.where((product) {
        int quantity = int.parse(product.quantity!);
        return quantity > 0 &&
            quantity <= threshold; // Only products with quantity > 0
      }).toList();

      lowStockProducts.sort(
          (a, b) => int.parse(a.quantity!).compareTo(int.parse(b.quantity!)));

      // Emit the appropriate state
      emit(ProductsStateSuccess());
    } catch (e) {
      emit(ProductsStateError(e.toString()));
    }
  }

  Future<void> getProductsByQuantity() async {
    try {
      emit(ProductsStateLoading());

      // Sort the filtered products by quantity
      filteredProducts.sort(
          (a, b) => int.parse(a.quantity!).compareTo(int.parse(b.quantity!)));

      // Apply offline updates if any
      await _applyOfflineUpdatesToList(filteredProducts);

      // Emit the appropriate state
      emit(ProductsStateSuccess());
    } catch (e) {
      emit(ProductsStateError(e.toString()));
    }
  }

  void sortByMostProfitable() {
    filteredProducts.sort((a, b) {
      double aProfit = double.parse(a.salary!) - double.parse(a.cost!);
      double bProfit = double.parse(b.salary!) - double.parse(b.cost!);
      return bProfit.compareTo(aProfit);
    });
    emit(ProductsStateSuccess());
  }

  Future<void> getLatestProduct() async {
    try {
      emit(ProductsStateLoading());

      // Fetch all products from the repository
      List<Product> products = await productsRepo.getProducts();

      // Apply offline updates if any
      await _applyOfflineUpdatesToList(products);

      // Sort the products by creation date
      products.sort((a, b) => b.createdDate!.compareTo(a.createdDate!));

      // Emit the appropriate state
      emit(ProductsStateSuccess());
    } catch (e) {
      emit(ProductsStateError(e.toString()));
    }
  }

  void emitIfNotClosed(ProductsState state) {
    if (!isClosed) {
      emit(state);
    }
  }

  Future<void> saveProductToLocal(Product product) async {
    // Save product locally
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> offlineProducts = prefs.getStringList('offlineProducts') ?? [];

    String productJson = jsonEncode(product.toJson());
    offlineProducts.add(productJson);
    await prefs.setStringList('offlineProducts', offlineProducts);

    log('Product saved locally: ${product.name}');

    // Attempt to add product to Firebase after 5 seconds
    Future.delayed(const Duration(seconds: 4), () async {
      try {
        await productsRepo.addProduct(
          product.name!,
          product.category!,
          product.parcode!,
          product.quantity!,
          product.salary!,
          product.cost!,
        );
        log('Product successfully synced to Firebase: ${product.name}');
      } catch (e) {
        log('Failed to sync product to Firebase: ${product.name}, Error: $e');
      }
    });
  }

  Future<void> addProduct(BuildContext context, bool isFastProduct) async {
    log('in add product');
    try {
      if (isFastProduct) {
        category.text = 'منتج سريع';
      }
      log('in add product2');

      if (isFastProduct ||
          (formKey.currentState != null && formKey.currentState!.validate())) {
        log('in add product3');
        emit(ProductsStateLoading());

        // If cost is empty, set it to the same value as the salary
        if (cost.text.isEmpty || cost.text == '0') {
          cost.text = salary.text;
        }

        log('in add product4');

        await addCategory(category.text);

        log('in add product5');

        log(name.text);
        log(category.text);
        log(parcode.text);
        log(quantity.text);
        log(salary.text);
        log(cost.text);

        await productsRepo
            .addProduct(name.text, category.text, parcode.text, quantity.text,
                salary.text, cost.text)
            .then((_) async {
          await operationRepo.logOperation(
              "إضافة منتج",
              'تمت إضافة المنتج بنجاح و لعرض المنتج يرجي الذهاب لصفحة المنتجات',
              '',
              '');
        });
        log('in add product6');

        product = await productsRepo.getProductByBarcode(parcode.text);
        products.add(product!);

        if (isFastProduct) {
          // Increment the product count in the invoice to 1 immediately
          context
              .read<InvoiceCubit>()
              .incrementLocalProductCount(product!, 1, context);
          emit(ProductsStateSuccess());
        }

        refreshProductList(product!);

        // Notify the InvoiceCubit to refresh its product list
        context.read<InvoiceCubit>().getProducts();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة المنتج بنجاح')),
        );

        if (!isFastProduct) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      emit(ProductsStateError(e.toString()));
    }
  }

  void getProducts() async {
    try {
      emit(ProductsStateLoading());

      // Fetch products from the repository (Firebase or any other source)
      products = await productsRepo.getProducts();

      // Check if there are any offline updates stored in SharedPreferences
      await _applyOfflineUpdatesToList(products);

      // Filter products if needed or assign the fetched list directly
      if (products.isEmpty) {
        emit(ProductsStateEmpty());
      } else {
        filteredProducts = products;
        emit(ProductsStateSuccess());
      }
    } catch (e) {
      log('Error in product get');
      emit(ProductsStateError(e.toString()));
    }
  }

  void getProductByBarcode(String barcode) async {
    try {
      emit(ProductsStateLoading());

      // Fetch the product by barcode from the repository
      product = await productsRepo.getProductByBarcode(barcode);

      fetchCategories();

      // Apply offline updates if any
      await _applyOfflineUpdatesToProduct(product);

      // Update text fields with product details
      if (product != null) {
        name.text = product?.name ?? '';
        category.text = product?.category ?? '';
        parcode.text = product?.parcode ?? '';
        quantity.text = product?.quantity ?? '';
        salary.text = product?.salary ?? '';
        cost.text = product?.cost ?? '';
        emit(ProductsStateSuccess());
      } else {
        emit(ProductsStateError('لا يوجد منتج يحتوي علي هذا الباركود'));
      }
    } catch (e) {
      emit(ProductsStateError(e.toString()));
    }
  }

  Future<void> _applyOfflineUpdatesToList(List<Product> productList) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final offlineData = prefs.getStringList('offline_updates') ?? [];

    if (offlineData.isNotEmpty) {
      for (String data in offlineData) {
        final parsedData = Map<String, dynamic>.from(json.decode(data));
        final barcode = parsedData['barcode'];
        final updatedQuantity = parsedData['quantity'];

        for (var product in productList) {
          if (product.parcode == barcode) {
            product.quantity = updatedQuantity.toString();
          }
        }
      }
    }
  }

  Future<void> _applyOfflineUpdatesToProduct(Product? product) async {
    if (product == null) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final offlineData = prefs.getStringList('offline_updates') ?? [];

    if (offlineData.isNotEmpty) {
      for (String data in offlineData) {
        final parsedData = Map<String, dynamic>.from(json.decode(data));
        final barcode = parsedData['barcode'];
        final updatedQuantity = parsedData['quantity'];

        if (product.parcode == barcode) {
          product.quantity = updatedQuantity.toString();
        }
      }
    }
  }

  void updateProduct(BuildContext context) async {
    try {
      if (formKey.currentState != null && formKey.currentState!.validate()) {
        if (isClosed) return; // Ensure the Cubit isn't closed before emitting

        emit(ProductsStateLoading());

        // Track the old values before updating
        final oldName = product!.name;
        final oldCategory = product!.category;
        final oldParcode = product!.parcode;
        final oldQuantity = product!.quantity;
        final oldSalary = product!.salary;
        final oldCost = product!.cost;

        // Prepare update data
        final updateData = {
          'product_name': name.text,
          'product_category': category.text,
          'product_parcode': parcode.text,
          'product_quantity': quantity.text,
          'product_salary': salary.text,
          'product_cost': cost.text,
          'product_profit':
              (double.parse(salary.text) - double.parse(cost.text))
        };

        // Perform the update
        await productsRepo
            .updateProduct(product!.parcode!, updateData)
            .then((_) {
          // Prepare a list of changes
          List<String> changes = [];

          if (oldName != name.text) {
            changes.add('اسم المنتج: $oldName -> ${name.text}');
          }
          if (oldCategory != category.text) {
            changes.add('الفئة: $oldCategory -> ${category.text}');
          }
          if (oldParcode != parcode.text) {
            changes.add('الباركود: $oldParcode -> ${parcode.text}');
          }
          if (oldQuantity != quantity.text) {
            changes.add('الكمية: $oldQuantity -> ${quantity.text}');
          }
          if (oldSalary != salary.text) {
            changes.add('سعر البيع: $oldSalary -> ${salary.text}');
          }
          if (oldCost != cost.text) {
            changes.add('التكلفة: $oldCost -> ${cost.text}');
          }

          // Display the changes in the snackbar
          if (changes.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('تم تعديل:\n${changes.join('\n')}')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('لم يتم إجراء أي تغييرات')),
            );
          }

          Navigator.pop(context, true);
        });

        if (isClosed) return; // Ensure the Cubit isn't closed before emitting
        emit(OperationsStateLoading());

        // Log the update operation
        final prod = await productsRepo.getProductById(product!.productId!);
        await operationRepo.logOperation(
            "تعديل منتج",
            'تم تعديل ${prod!.name}:\nالفئة: ${prod.category}\nالتكلفة: ${formattedNumber(double.parse(prod.cost!))} د.ع\nالسعر: ${formattedNumber(double.parse(prod.salary!))} د.ع\nالكمية: ${prod.quantity}\nالباركود: ${prod.parcode}',
            '',
            '');

        if (isClosed) return; // Ensure the Cubit isn't closed before emitting
        emit(OperationsStateSuccess());
        emit(ProductsStateSuccess());
      }
    } catch (e) {
      log(e.toString());
      if (isClosed) return; // Ensure the Cubit isn't closed before emitting
      emit(ProductsStateError(e.toString()));
    }
  }

  Future<void> deleteProduct() async {
    if (isClosed) return;
    try {
      emit(ProductsStateLoading());
      Product? productInfo =
          await productsRepo.getProductByBarcode(product!.parcode!);
      await productsRepo.deleteProduct(product!.parcode!);
      if (isClosed) return;
      emit(ProductsStateSuccess());

      emit(OperationsStateLoading());
      await operationRepo.logOperation(
          "حذف منتج",
          'تم حذف ${productInfo?.name ?? 'لا اسم'}\nبباركود: ${productInfo?.parcode ?? 'بلا باركود'}',
          '',
          '');
      if (isClosed) return;
      emit(OperationsStateSuccess());
    } catch (e) {
      if (isClosed) return;
      emit(ProductsStateError(e.toString()));
    }
  }

  void adjustProductQuantity(Product product, int quantityToSubtract) async {
    try {
      int currentQuantity = int.parse(product.quantity ?? '0');
      if (currentQuantity < quantityToSubtract) {
        emit(ProductsStateError('الكمية الحالية غير كافية'));
        return;
      }
      int newQuantity = currentQuantity - quantityToSubtract;
      await productsRepo.updateProduct(product.parcode!, {
        'product_quantity': newQuantity.toString(),
      });
      if (newQuantity < 3) {
        emit(ProductsStateWarning('الكمية على وشك النفاذ'));
      }
      if (newQuantity == 0) {
        emit(ProductsStateError('المنتج نفذ من المخزون'));
      } else {
        emit(ProductsStateSuccess());
      }
    } catch (e) {
      emit(ProductsStateError(e.toString()));
    }
  }

  void searchProducts(String query) {
    final lowerCaseQuery = query.toLowerCase();
    filteredProducts = products.where((product) {
      return product.name!.toLowerCase().contains(lowerCaseQuery) ||
          product.category!.toLowerCase().contains(lowerCaseQuery) ||
          product.parcode!.contains(lowerCaseQuery);
    }).toList();
    if (filteredProducts.isEmpty) {
      emit(ProductsStateEmpty());
    } else {
      emit(ProductsStateSuccess());
    }
  }

  void toggleCategoryExpanded(int index) {
    final category = categories[index];
    if (expandedCategories.contains(category)) {
      expandedCategories.remove(category);
    } else {
      expandedCategories.add(category);
    }
    emit(CategoriesStateSuccess());
  }
}
