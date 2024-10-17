import 'dart:developer';

import 'package:connectivity_checker/connectivity_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/ui/categories%20screen/cubit/product_cubit.dart';
import 'package:flutter_application_1/ui/categories%20screen/cubit/products_state.dart';
import 'package:flutter_application_1/ui/categories%20screen/update_product_screen.dart';
import 'package:flutter_application_1/ui/widgets/custom_dialogs.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../widgets/build_barcode_row.dart';
import '../widgets/build_category_row.dart';
import '../widgets/custom_products_field.dart';

class ProductFormScreen extends StatelessWidget {
  const ProductFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductCubit()..fetchCategories(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            leading: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 25,
                  color: Colors.white,
                )),
            backgroundColor: const Color(0xff4e00e8),
            centerTitle: true,
            title: const Text(
              'إضافة منتج جديد',
              style: TextStyle(
                  color: Colors.white, fontSize: 28, fontFamily: 'font1'),
              textAlign: TextAlign.center,
            ),
          ),
          body: BlocBuilder<ProductCubit, ProductsState>(
            builder: (context, state) {
              ProductCubit productCubit = context.read<ProductCubit>();
              log('$state');
              if (state is CategoriesStateLoading ||
                  state is ProductsStateLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is CategoriesStateError ||
                  state is ProductsStateError) {
                return Center(child: Text((state as dynamic).error));
              } else if (state is CategoriesStateSuccess ||
                  state is ProductsStateSuccess ||
                  state is CategoriesStateEmpty) {
                return Directionality(
                  textDirection: TextDirection.rtl,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: FormBuilder(
                      key: productCubit.formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          children: <Widget>[
                            buildTextFormed(
                                productCubit.name, 'اسم المنتج', false, ''),
                            const SizedBox(height: 16),
                            buildCategoryRow(context, productCubit),
                            const SizedBox(height: 16),
                            buildBarcodeRow(context, productCubit),
                            const SizedBox(height: 16),
                            buildTextFormed(
                                productCubit.quantity, 'الكمية', false, ''),
                            const SizedBox(height: 16),
                            buildTextFormed(
                                productCubit.cost, 'التكلفة', false, ''),
                            const SizedBox(height: 16),
                            buildTextFormed(
                                productCubit.salary, 'سعر البيع', false, ''),
                            const SizedBox(height: 16),
                            Center(
                              child: BlocListener<ProductCubit, ProductsState>(
                                listener: (context, state) {
                                  if (state is ProductsStateSuccess) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('تمت الإضافة بنجاح'),
                                      ),
                                    );
                                  }
                                },
                                child: ElevatedButton(
                                  style: ButtonStyle(
                                    shape: WidgetStateProperty.all<
                                        RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    backgroundColor:
                                        WidgetStateProperty.all<Color>(
                                      const Color.fromARGB(255, 25, 28, 235),
                                    ),
                                    minimumSize: WidgetStateProperty.all<Size>(
                                      const Size(double.infinity, 50),
                                    ),
                                  ),
                                  onPressed: () async {
                                    bool isOffline = (await ConnectivityWrapper
                                        .instance.isConnected);
                                    // Check if the barcode is already used
                                    if (isOffline) {
                                      bool isUsed = await productCubit
                                          .productsRepo
                                          .isBarcodeUsed(
                                              productCubit.parcode.text);
                                      if (isUsed) {
                                        // Emit state for UI handling
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return Directionality(
                                              textDirection: TextDirection.rtl,
                                              child: AlertDialog(
                                                title: const Text(
                                                    'لا يمكن اضافة هذا المنتج!'),
                                                content: const Text(
                                                    'هذا الباركود مستخدم من قبل'),
                                                actions: [
                                                  TextButton(
                                                    child: const Text('إلغاء'),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                  TextButton(
                                                    child: const Text('تعديل'),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              UpdateProductScreen(
                                                            barcode:
                                                                productCubit
                                                                    .parcode
                                                                    .text,
                                                            fromTab: false,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      } else {
                                        // Add the product
                                        productCubit.addProduct(context, false);
                                      }
                                    } else {
                                      showErrorDialog(context,
                                          'تحقق من اتصالك بالإنترنت ثم اعد المحاولة');
                                    }
                                  },
                                  child: state is ProductsStateLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : const Text('إضافة',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 25)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                return const Center(child: Text('حالة غير معروفة'));
              }
            },
          ),
        ),
      ),
    );
  }
}
