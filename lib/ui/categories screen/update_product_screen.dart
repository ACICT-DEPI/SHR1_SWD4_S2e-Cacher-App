import 'package:flutter/material.dart';
import 'package:flutter_application_1/ui/categories%20screen/cubit/product_cubit.dart';
import 'package:flutter_application_1/ui/categories%20screen/cubit/products_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../widgets/build_barcode_row.dart';
import '../widgets/build_category_row.dart';
import '../widgets/custom_dialogs.dart';
import '../widgets/custom_products_field.dart';

class UpdateProductScreen extends StatelessWidget {
  final String barcode;
  final bool fromTab;

  const UpdateProductScreen(
      {super.key, required this.barcode, required this.fromTab});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ProductCubit()..getProductByBarcode(barcode), // Fetch categories
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              icon: const Icon(
                Icons.arrow_back_ios,
                size: 25,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xff4e00e8),
            centerTitle: true,
            title: const Text(
              'تعديل المنتج',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'font1',
                fontSize: 28,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          body: BlocBuilder<ProductCubit, ProductsState>(
            builder: (context, state) {
              ProductCubit productCubit = context.read<ProductCubit>();

              if (state is ProductsStateLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return Directionality(
                textDirection: TextDirection.rtl,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FormBuilder(
                    key: productCubit.formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          buildTextFormed(productCubit.name, 'اسم المنتج', true,
                              productCubit.product?.name ?? "لا يوجد اسم"),
                          const SizedBox(height: 16),
                          buildCategoryRow(context,
                              productCubit), // Ensure categories appear here
                          const SizedBox(height: 16),
                          buildBarcodeRow(context, productCubit),
                          const SizedBox(height: 16),
                          buildTextFormed(productCubit.quantity, 'الكمية', true,
                              productCubit.product?.quantity ?? 'لا يوجد كمية'),
                          const SizedBox(height: 16),
                          buildTextFormed(productCubit.cost, 'التكلفة', true,
                              productCubit.product?.cost ?? 'لا يوجد تكلفة'),
                          const SizedBox(height: 16),
                          buildTextFormed(
                              productCubit.salary,
                              'سعر البيع',
                              true,
                              productCubit.product?.salary ??
                                  'لا يوجد سعر بيع'),
                          const SizedBox(height: 16),
                          Center(
                            child: BlocListener<ProductCubit, ProductsState>(
                              listener: (context, state) {
                                if (state is ProductsStateError) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(state.error)),
                                  );
                                }
                              },
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ButtonStyle(
                                        shape: WidgetStateProperty.all<
                                            RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                        ),
                                        backgroundColor:
                                            WidgetStateProperty.all<Color>(
                                          const Color.fromARGB(
                                              255, 25, 28, 235),
                                        ),
                                      ),
                                      onPressed: () {
                                        showConfirmationDialog(
                                            'هل انت متأكد من التعديلات؟',
                                            context, () {
                                          productCubit.updateProduct(context); // Return true indicating success
                                        }, 'coniformUpdate');
                                      },
                                      child: const Text('حفظ',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 25)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}


/*const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ButtonStyle(
                                        shape: WidgetStateProperty.all<
                                            RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                        ),
                                        backgroundColor:
                                            WidgetStateProperty.all<Color>(
                                          const Color.fromARGB(
                                              255, 25, 28, 235),
                                        ),
                                      ),
                                      onPressed: () {
                                        showConfirmationDialog(
                                            'هل انت متأكد انك تريد حذف المنتج؟',
                                            context, () {
                                          productCubit
                                              .deleteProduct()
                                              .then((_) {
                                            showSnackbar(
                                                context, 'تم الحذف بنجاح');
                                            if (fromTab == true) {
                                              Navigator.pop(context, false);
                                            } else {
                                              Navigator.pop(context, false);
                                              Navigator.pop(context);
                                            } // Return false indicating deletion
                                          }).catchError((error) {
                                            showSnackbar(
                                                context, 'فشل في الحذف');
                                          });
                                        }, 'deleteProduct');
                                      },
                                      child: const Text('حذف',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 25)),
                                    ),
                                  ),*/
