import 'dart:math';
import 'package:barcode/barcode.dart';
import 'package:connectivity_checker/connectivity_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/domain/utils.dart';
import 'package:flutter_application_1/ui/categories%20screen/cubit/products_state.dart';
import 'package:flutter_application_1/ui/widgets/custom_dialogs.dart';
import 'package:flutter_application_1/ui/widgets/products_before_search.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:simple_barcode_scanner/enum.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import '../../data/model/invoice_model.dart';
import '../../data/model/product_model.dart';
import '../categories screen/cubit/product_cubit.dart';
import '../connectine cubit/connective_states.dart';
import '../customer screen/cubit/customer_states.dart';
import '../customer screen/cubit/customer_cubit.dart';
import '../widgets/custom_products_field.dart';
import 'cubit/invoice_cubit.dart';
import 'cubit/invoice_states.dart';

class InvoiceProductScreen extends StatelessWidget {
  const InvoiceProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final Invoice? oldInvoice = args?['oldInvoice'] as Invoice?;
    final bool isExchange = args?['isExchange'] as bool? ?? false;
    final String oldProductId = args?['oldProductId'] as String? ?? 'no id';
    final int oldIndex = args?['index'] as int? ?? 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text('إدارة الفاتورة',
                style: TextStyle(color: Colors.white, fontFamily: 'font1')),
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_ios,
                  size: 25, color: Colors.white),
            ),
            backgroundColor: const Color(0xff4e00e8),
            bottom: const TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: 'إضافة المنتجات'),
                Tab(text: 'معلومات الفاتورة'),
              ],
            ),
          ),
          body: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => InvoiceCubit()
                  ..getProducts()
                  ..getCustomers()
                  ..getManagerData(),
              ),
              BlocProvider(create: (_) => CustomerCubit()..getClients()),
              BlocProvider(create: (_) => ProductCubit()..getProducts())
            ],
            child: BlocListener<ProductCubit, ProductsState>(
              listener: (context, state) {
                if (state is ProductsStateSuccess) {
                  context.read<InvoiceCubit>().getProducts();
                }
              },
              child: TabBarView(
                children: [
                  const ProductSelectionTab(),
                  AddBuyerInfo(
                    oldInvoice: oldInvoice,
                    isExchanged: isExchange,
                    oldProductId: oldProductId,
                    oldIndex: oldIndex,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProductSelectionTab extends StatelessWidget {
  const ProductSelectionTab({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController _searchController = TextEditingController();

    return BlocBuilder<InvoiceCubit, InvoiceStates>(
      builder: (context, state) {
        if (state is InvoiceStateLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is InvoiceStateError) {
          return Center(child: Text(state.error));
        } else if (state is InvoiceStateSuccess ||
            state is ProductsStateSuccess) {
          final InvoiceCubit invoiceCubit = context.read<InvoiceCubit>();
          final products = invoiceCubit.filteredProducts;
          final selectedProducts = invoiceCubit.selectedProducts;

          products.sort((a, b) {
            if (selectedProducts.contains(a) && !selectedProducts.contains(b)) {
              return -1;
            } else if (!selectedProducts.contains(a) &&
                selectedProducts.contains(b)) {
              return 1;
            }
            return 0;
          });

          void _addProductToInvoice(String barcode) {
            if (barcode.isNotEmpty) {
              final product = invoiceCubit.products.firstWhere(
                (product) => product.parcode == barcode,
                orElse: () => Product(
                  isRefunded: false,
                  isReplaced: false,
                  isReplacedDone: false,
                ),
              );
              invoiceCubit.incrementLocalProductCount(product, 1, context);
            }
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    BlocProvider(
                      create: (context) => ProductCubit(),
                      child: BlocBuilder<ProductCubit, ProductsState>(
                          builder: (context, state) {
                        return ElevatedButton(
                          onPressed: () async {
                            _showQuickProductDialog(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade900,
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'المنتج السريع',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'البحث بالباركود أو الفئة',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          invoiceCubit.searchProducts(value);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.qr_code),
                      onPressed: () async {
                        var result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SimpleBarcodeScannerPage(
                              scanType: ScanType.barcode,
                              isShowFlashIcon: true,
                            ),
                          ),
                        );
                        if (result != null && result is String) {
                          _addProductToInvoice(result);
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];

                    if (product.category == 'منتج سريع' &&
                        product != invoiceCubit.latestQuickProduct) {
                      return const SizedBox.shrink();
                    }

                    final result = double.parse(product.salary!) -
                        double.parse(product.cost!);
                    final isSelected = selectedProducts.contains(product);
                    return productBeforeSearch(invoiceCubit, product, result,
                        context, true, isSelected);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff4e00e8),
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Icon(Icons.arrow_forward, color: Colors.white),
                    onPressed: () {
                      DefaultTabController.of(context).animateTo(1);
                    },
                  ),
                ),
              ),
            ],
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

void _showQuickProductDialog(BuildContext context) {
  final productCubit = context.read<ProductCubit>();
  final invoiceCubit = context.read<InvoiceCubit>();

  productCubit.name.text = 'منتج سريع';
  productCubit.parcode.text = _generateRandomBarcode();
  productCubit.quantity.text = '999999'; // Very high number to represent "infinite"
  productCubit.cost.text = '0';
  productCubit.salary.clear(); // Clear salary for quick product
  productCubit.category.text = 'منتج سريع';

  bool isAddingProduct = false;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('إضافة منتج سريع'),
              content: _buildQuickProductForm(context, productCubit),
              actions: [
                TextButton(
                  child: const Text('إلغاء'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  onPressed: isAddingProduct
                      ? null
                      : () async {
                          // Parse the salary to double safely and ensure it is greater than zero
                          double? salaryValue = double.tryParse(productCubit.salary.text);

                          // Validate salary (must not be null, empty, or zero)
                          if (salaryValue == null || salaryValue <= 0) {
                            showErrorDialog(context, 'من فضلك أدخل سعر بيع صحيح أكبر من الصفر');
                            return;
                          }

                          setState(() {
                            isAddingProduct = true;
                          });

                          bool isUsed = await productCubit.productsRepo
                              .isBarcodeUsed(productCubit.parcode.text);

                          if (isUsed) {
                            showErrorDialog(context, 'الباركود مستخدم من قبل');
                            setState(() {
                              isAddingProduct = false;
                            });
                          } else {
                            final product = Product(
                              productId: productCubit.parcode.text,
                              name: productCubit.name.text,
                              category: productCubit.category.text,
                              parcode: productCubit.parcode.text,
                              quantity: productCubit.quantity.text,
                              cost: productCubit.cost.text,
                              salary: productCubit.salary.text,
                              isRefunded: false,
                              isReplaced: false,
                              isReplacedDone: false,
                              createdDate: DateTime.now(),
                            );

                            if (context.read<ConnectivityCubit>().state ==
                                ConnectivityState.connected) {
                              // Online mode: Add product directly to Firebase
                              await productCubit.addProduct(context, true);
                            } 

                            // After 4 seconds, close the dialog and refresh the UI
                            if (context.read<ConnectivityCubit>().state !=
                                ConnectivityState.connected) {
                              Future.delayed(const Duration(seconds: 4), () {
                                if (context.mounted) {
                                  setState(() {
                                    isAddingProduct = false;
                                  });
                                  Navigator.of(context).pop();
                                }

                                invoiceCubit.products.add(product);
                                invoiceCubit.refreshProductList(product);
                              });
                            }                          
                          }
                        },
                  child: isAddingProduct
                      ? const Text('تحميل...')
                      : const Text('إضافة'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}


Widget _buildQuickProductForm(BuildContext context, ProductCubit productCubit) {
  return SingleChildScrollView(
    child: Form(
      key: productCubit.formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildTextFormed(
              productCubit.name, 'اسم المنتج', false, productCubit.name.text),
          const SizedBox(height: 16),
          buildBarcodeRow(
              context, productCubit), // Integrate the barcode row with buttons
          const SizedBox(height: 16),
          buildTextFormed(productCubit.quantity, 'الكمية', false,
              productCubit.quantity.text),
          const SizedBox(height: 16),
          buildTextFormed(
              productCubit.cost, 'التكلفة', false, productCubit.cost.text),
          const SizedBox(height: 16),
          buildTextFormed(productCubit.salary, 'سعر البيع', false, ''),
        ],
      ),
    ),
  );
}

Widget buildBarcodeRow(BuildContext context, ProductCubit productCubit) {
  return Padding(
    padding: const EdgeInsets.all(10.0),
    child: Container(
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            style: ButtonStyle(
              fixedSize: WidgetStateProperty.all(const Size(40, 20)),
              backgroundColor: WidgetStateProperty.all<Color>(
                const Color.fromARGB(255, 25, 28, 235),
              ),
            ),
            onPressed: () {
              final random = Random();
              final barcode = Barcode.ean13();
              final digits = List.generate(
                  barcode.minLength - 1, (_) => random.nextInt(10));
              final checksumDigit = calculateChecksumDigit(digits);
              final randomBarcode = digits.join() + checksumDigit.toString();
              productCubit.parcode.text = randomBarcode;
            },
            child: const Text(
              'توليد',
              style: TextStyle(color: Colors.white, fontSize: 8),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 5),
          ElevatedButton(
            style: ButtonStyle(
              fixedSize: WidgetStateProperty.all(const Size(30, 15)),
              backgroundColor: WidgetStateProperty.all<Color>(
                const Color.fromARGB(255, 25, 28, 235),
              ),
            ),
            onPressed: () async {
              var result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SimpleBarcodeScannerPage(
                    scanType: ScanType.barcode,
                    isShowFlashIcon: true,
                  ),
                ),
              );
              if (result != null && result is String) {
                productCubit.parcode.text = result;
              }
            },
            child: const Text(
              'scan',
              style: TextStyle(color: Colors.white, fontSize: 7),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: FormBuilderTextField(
              controller: productCubit.parcode,
              name: 'barcode',
              decoration: const InputDecoration(
                labelText: 'الباركود',
              ),
              keyboardType: TextInputType.number,
              validator: FormBuilderValidators.required(),
            ),
          ),
        ],
      ),
    ),
  );
}

String calculateChecksumDigit(List<int> digits) {
  final sum = digits.asMap().entries.fold(0, (prev, entry) {
    final index = entry.key;
    final digit = entry.value;
    final multiplier = (index % 2 == 0) ? 1 : 3;
    return prev + digit * multiplier;
  });

  final checksumDigit = (10 - (sum % 10)) % 10;
  return checksumDigit.toString();
}

String _generateRandomBarcode() {
  Random random = Random();
  const int barcodeLength = 12;
  String barcode = '';
  for (int i = 0; i < barcodeLength; i++) {
    barcode += random.nextInt(10).toString(); // Generate a random digit (0-9)
  }
  return barcode;
}

class AddBuyerInfo extends StatelessWidget {
  final Invoice? oldInvoice;
  final bool isExchanged;
  final String oldProductId;
  final int oldIndex;

  const AddBuyerInfo({
    Key? key,
    required this.oldInvoice,
    required this.isExchanged,
    required this.oldProductId,
    required this.oldIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceCubit, InvoiceStates>(
      builder: (context, state) {
        if (state is InvoiceStateLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is InvoiceStateError) {
          return Center(child: Text(state.error));
        }

        final InvoiceCubit invoiceCubit = context.read<InvoiceCubit>();

        if (isExchanged && oldInvoice != null) {
          invoiceCubit.buyerName.text = oldInvoice!.clientModel!.clientName;
          invoiceCubit.buyerNumber.text = oldInvoice!.clientModel!.clientPhone;
          invoiceCubit.buyerAddress.text =
              oldInvoice!.clientModel!.cleintAddress;
          invoiceCubit.paymentMethod.text = oldInvoice!.paymentMethod;
        }

        final productCounts = invoiceCubit.productCounts;
        final productList = productCounts.entries.map((entry) {
          final product = invoiceCubit.products.firstWhere(
            (prod) => prod.productId == entry.key || prod.parcode == entry.key,
            orElse: () => Product(
              productId: entry.key,
              name: 'Unknown Product',
              isRefunded: false,
              isReplaced: false,
              isReplacedDone: false,
            ),
          );
          final quantity = entry.value;
          return {
            'product': product,
            'quantity': quantity,
          };
        }).toList();

        List<Product> prr = [];
        for (var list in productList) {
          for (var i = list['quantity'] as int; i > 0; i--) {
            prr.add(list['product'] as Product);
          }
        }

        // Display only the specified products
        return Form(
          key: invoiceCubit.formKey,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display a message if no products are selected
                  if (prr.isEmpty)
                    Center(
                      child: Text(
                        'لا يوجد منتجات محددة بعد',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade900,
                        ),
                      ),
                    )
                  else ...[
                    Text(
                      'المنتجات المحددة:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    _buildProductList(productList), // Show the list of products
                  ],
                  const SizedBox(height: 16),
                  if (isExchanged)
                    _buildCustomerInfo(oldInvoice!)
                  else
                    _buildCustomerSelection(context, invoiceCubit),
                  const SizedBox(height: 16),
                  if (!invoiceCubit.isExistingCustomer)
                    _buildNewCustomerForm(invoiceCubit),
                  _buildDiscountAndTotal(invoiceCubit, prr),
                  _buildPaymentMethod(invoiceCubit),
                  const SizedBox(height: 16),
                  _buildActionButtons(context, invoiceCubit, prr),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductList(List<Map<String, dynamic>> productList) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: productList.length,
      itemBuilder: (context, index) {
        final product = productList[index]['product'] as Product;
        final quantity = productList[index]['quantity'] as int;

        return Card(
          child: ListTile(
            title: Text(product.name ?? 'Unknown Product'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'سعر المنتج الواحد: ${formattedNumber(double.parse(product.salary ?? '0'))} د.ع'),
                Text('الكمية المشتراة: $quantity ${product.name}'),
                Text(
                    'السعر الكلي للمنتج: ${formattedNumber(quantity * double.parse(product.salary ?? '0'))} د.ع'),
                Text('الفئة: ${product.category ?? 'Unknown Category'}'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomerInfo(Invoice oldInvoice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اسم العميل: ${oldInvoice.clientModel?.clientName ?? 'مجهول'}',
          style: TextStyle(fontSize: 20, color: Colors.blue.shade900),
        ),
        Text(
          'هاتف العميل: ${oldInvoice.clientModel?.clientPhone == '' ? 'مجهول' : oldInvoice.clientModel!.clientPhone}',
          style: TextStyle(fontSize: 20, color: Colors.blue.shade900),
        ),
        Text(
          'عنوان العميل: ${oldInvoice.clientModel?.cleintAddress == '' ? 'مجهول' : oldInvoice.clientModel!.cleintAddress}',
          style: TextStyle(fontSize: 20, color: Colors.blue.shade900),
        ),
      ],
    );
  }

  Widget _buildCustomerSelection(
      BuildContext context, InvoiceCubit invoiceCubit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          style:
              ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade900),
          onPressed: () => invoiceCubit.selectNewCustomer(),
          child: const Text('عميل جديد', style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          style:
              ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade900),
          onPressed: () => showDialog(
            context: context,
            builder: (_) => Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                child: _buildCustomerSearch(context),
              ),
            ),
          ),
          child: const Text('اختر عميل', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildCustomerSearch(BuildContext context) {
    return BlocProvider.value(
      value: context.read<CustomerCubit>(),
      child: BlocBuilder<CustomerCubit, CustomerStates>(
        builder: (context, state) {
          if (state is CustomersLoadingState ||
              state is CustomersLoadingFromCacheState) {
            return const Center(
                child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ));
          } else if (state is CustomersErrorState) {
            return Center(child: Text(state.error));
          }
          final customerCubit = context.read<CustomerCubit>();
          final filteredClients = customerCubit.filteredClients;
          return Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'ابحث عن عميل',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  context.read<CustomerCubit>().filterClients(value);
                },
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredClients.length,
                  itemBuilder: (context, index) {
                    final client = filteredClients[index];
                    return ListTile(
                      title: Text(client.clientName.isNotEmpty
                          ? client.clientName
                          : 'مجهول'),
                      subtitle: Text(client.clientPhone.isNotEmpty
                          ? client.clientPhone
                          : 'مجهول'),
                      onTap: () {
                        context
                            .read<InvoiceCubit>()
                            .selectExistingCustomer(client);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('تمت إضافة العميل بنجاح')),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNewCustomerForm(InvoiceCubit invoiceCubit) {
    return Column(
      children: [
        TextFormField(
          controller: invoiceCubit.buyerName,
          decoration: const InputDecoration(
            labelText: 'اسم المشتري',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: invoiceCubit.buyerNumber,
          decoration: const InputDecoration(
            labelText: 'رقم الهاتف',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: invoiceCubit.buyerAddress,
          decoration: const InputDecoration(
            labelText: 'عنوان المشتري',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDiscountAndTotal(InvoiceCubit invoiceCubit, List<Product> prr) {
    double totalCost = invoiceCubit.totalCost(prr);
    double discount = double.parse(invoiceCubit.discountAmount.text.isEmpty
        ? '0'
        : invoiceCubit.discountAmount.text);
    double netAmount;

    if (invoiceCubit.selectedDiscountType == 'quantity') {
      netAmount = totalCost - discount;
    } else if (invoiceCubit.selectedDiscountType == 'percentage') {
      netAmount = totalCost * (1 - discount / 100);
    } else {
      netAmount = totalCost; // Default case, no discount
    }

    // Ensure that netAmount is not negative
    if (netAmount < 0) {
      netAmount = 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: invoiceCubit.discountAmount,
                decoration: const InputDecoration(
                  labelText: 'الخصم',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  invoiceCubit.updateDiscount(value);
                },
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    invoiceCubit.selectDiscountType('quantity');
                  },
                  style: ButtonStyle(
                    backgroundColor:
                        invoiceCubit.selectedDiscountType == 'quantity'
                            ? WidgetStateProperty.all(Colors.blue)
                            : WidgetStateProperty.all(Colors.grey),
                  ),
                  child: const Text(
                    '  بالكمية  ',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    invoiceCubit.selectDiscountType('percentage');
                  },
                  style: ButtonStyle(
                    backgroundColor:
                        invoiceCubit.selectedDiscountType == 'percentage'
                            ? WidgetStateProperty.all(Colors.blue)
                            : WidgetStateProperty.all(Colors.grey),
                  ),
                  child: const Text(
                    'بالنسبة %',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'الخصم: ${formattedNumber(discount)} ${invoiceCubit.selectedDiscountType == 'percentage' ? '%' : 'د.ع'}',
          style: TextStyle(fontSize: 20, color: Colors.blue.shade900),
        ),
        Text(
          'المجموع: ${formattedNumber(totalCost)} د.ع',
          style: TextStyle(fontSize: 20, color: Colors.blue.shade900),
        ),
        Text(
          'الصافي: ${formattedNumber(netAmount)} د.ع',
          style: TextStyle(fontSize: 20, color: Colors.blue.shade900),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildPaymentMethod(InvoiceCubit invoiceCubit) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DropdownButtonFormField<String>(
        value: invoiceCubit.paymentMethod.text.isNotEmpty
            ? invoiceCubit.paymentMethod.text
            : null,
        items: ['نقداً', 'بطاقة الائتمان']
            .map((method) => DropdownMenuItem(
                  value: method,
                  child: Text(method),
                ))
            .toList(),
        decoration: const InputDecoration(
          labelText: 'طريقة الدفع',
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          if (value != null) {
            invoiceCubit.paymentMethod.text = value;
            invoiceCubit.showPaidUpField = false;
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'الرجاء اختيار طريقة الدفع';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, InvoiceCubit invoiceCubit, List<Product> prr) {
    return prr.isEmpty
        ? Container()
        : Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: invoiceCubit.state is AddInvoiceLoading
                        ? Colors.grey
                        : Colors.blue.shade900,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: invoiceCubit.state is AddInvoiceLoading
                      ? null
                      : () async {
                          if (invoiceCubit.state is AddInvoiceLoading) {
                            return;
                          }

                          bool isOffline = invoiceCubit.isOffline;

                          if (invoiceCubit.formKey.currentState!.validate()) {
                            if (isExchanged) {
                              prr.first.isReplacedDone = true;
                              invoiceCubit
                                  .handleExchangeProduct(
                                      oldInvoice!.invoiceId,
                                      oldProductId,
                                      prr.first.productId!,
                                      context,
                                      oldIndex,
                                      '')
                                  .then((_) {
                                invoiceCubit
                                    .addInvoice(
                                  oldInvoice?.invoiceId ?? '',
                                  prr,
                                  false,
                                  context,
                                  oldInvoice?.clientModel?.clientId ?? '',
                                  oldProductId,
                                )
                                    .then((_) {
                                  Navigator.of(context).pop();
                                });
                              });
                            } else {
                              if (isOffline) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'سيتم حفظ الفاتورة في وضع عدم الاتصال و سيتم تحديث الكمية عند الإتصال بالإنترنت مباشرة، وقد يستغرق ذلك وقتًا أطول من المعتاد')),
                                );
                                Navigator.of(context).pop();
                              }
                              invoiceCubit
                                  .addInvoice(
                                oldInvoice?.invoiceId ?? '',
                                prr,
                                false,
                                context,
                                oldInvoice?.clientModel?.clientId ?? '',
                                null,
                              )
                                  .then((_) {
                                Navigator.of(context).pop();
                              });
                            }
                          } else {
                            showErrorDialog(
                                context, 'تأكد من إدخال طريقة الدفع');
                          }
                        },
                  child: BlocBuilder<InvoiceCubit, InvoiceStates>(
                    builder: (context, state) {
                      if (state is InvoiceStateError) {
                        return Text(state.error);
                      } else if (state is AddInvoiceLoading) {
                        return const Center(
                          child: Text(
                            'سيتم حفظ الفاتورة في وضع عدم الاتصال و سيتم تحديث الكمية عند الإتصال بالإنترنت مباشرة، وقد يستغرق ذلك وقتًا أطول من المعتاد\nجار التحميل....',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }
                      return state is InvoiceStateLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'حفظ',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20),
                            );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: invoiceCubit.state is AddInvoiceLoading
                        ? Colors.grey
                        : Colors.blue.shade900,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: invoiceCubit.state is AddInvoiceLoading
                      ? null
                      : () async {
                          if (invoiceCubit.state is AddInvoiceLoading) {
                            return;
                          }
                          bool isOffline =
                              !(await ConnectivityWrapper.instance.isConnected);
                          if (invoiceCubit.formKey.currentState!.validate()) {
                            if (isExchanged) {
                              prr.first.isReplacedDone = true;
                              invoiceCubit
                                  .handleExchangeProduct(
                                      oldInvoice!.invoiceId,
                                      oldProductId,
                                      prr.first.productId!,
                                      context,
                                      oldIndex,
                                      '')
                                  .then((_) {
                                invoiceCubit
                                    .addInvoice(
                                  oldInvoice?.invoiceId ?? '',
                                  prr,
                                  true,
                                  context,
                                  oldInvoice?.clientModel?.clientId ?? '',
                                  oldProductId,
                                )
                                    .then((_) {
                                  invoiceCubit
                                      .generateBDF(
                                    invoiceCubit.invoice!,
                                    prr,
                                    invoiceCubit.manager!,
                                    invoiceCubit.paymentMethod.text,
                                    false,
                                    isOffline,
                                  )
                                      .then((_) {
                                    Navigator.of(context).pop();
                                  });
                                });
                              });
                            } else {
                              invoiceCubit
                                  .addInvoice(
                                oldInvoice?.invoiceId ?? '',
                                prr,
                                true,
                                context,
                                oldInvoice?.clientModel?.clientId ?? '',
                                null,
                              )
                                  .then((_) {
                                invoiceCubit
                                    .generateBDF(
                                  invoiceCubit.invoice!,
                                  prr,
                                  invoiceCubit.manager!,
                                  invoiceCubit.paymentMethod.text,
                                  false,
                                  isOffline,
                                )
                                    .then((_) {
                                  Navigator.of(context).pop();
                                });
                              });
                            }
                          } else {
                            showErrorDialog(
                                context, 'تأكد من إدخال طريقة الدفع');
                          }
                        },
                  child: BlocBuilder<InvoiceCubit, InvoiceStates>(
                    builder: (context, state) {
                      if (state is InvoiceStateError) {
                        showErrorDialog(context, state.error);
                      } else if (state is AddInvoiceLoading) {
                        return const Center(
                          child: Text(
                            'سيتم حفظ الفاتورة في وضع عدم الاتصال و سيتم تحديث الكمية عند الإتصال بالإنترنت مباشرة، وقد يستغرق ذلك وقتًا أطول من المعتاد\nجار التحميل....',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }
                      return state is InvoiceStateLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'تصدير & طباعة',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20),
                            );
                    },
                  ),
                ),
              ),
            ],
          );
  }
}
