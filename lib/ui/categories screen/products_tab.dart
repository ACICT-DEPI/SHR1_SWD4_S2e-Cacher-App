import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/domain/utils.dart';
import 'package:flutter_application_1/ui/categories%20screen/update_product_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bill screen/cubit/invoice_cubit.dart';
import 'BarcodeCreationScreen.dart';
import 'cubit/product_cubit.dart';
import 'cubit/products_state.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final category = ModalRoute.of(context)?.settings.arguments as String?;

    return productShowScreen(category, context);
  }

  Widget productShowScreen(String? category, BuildContext context) {
    log(category ?? '');
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'المنتجات',
            style: TextStyle(color: Colors.white, fontFamily: 'font1'),
          ),
          centerTitle: true,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_ios,
              size: 25,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xff4e00e8),
        ),
        body: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) {
                final cubit = ProductCubit();
                if (category == 'all') {
                  cubit.getProducts();
                } else if (category != null) {
                  cubit.getProductsByCategory(category);
                }
                return cubit;
              },
            ),
            BlocProvider(create: (_) => InvoiceCubit()),
          ],
          child: BlocBuilder<ProductCubit, ProductsState>(
            builder: (context, state) {
              if (state is ProductsStateLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ProductsStateError) {
                return Center(child: Text(state.error));
              } else if (state is ProductsStateEmpty) {
                return const Center(
                  child: Text(
                    'لا توجد منتجات مطابقة للبحث',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                );
              } else if (state is LowStockLoaded) {
                ProductCubit productCubit = context.read<ProductCubit>();
                final products = state.lowStockProducts;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (value) {
                                productCubit.searchProducts(value);
                              },
                              decoration: InputDecoration(
                                hintText: 'البحث بالاسم، الفئة أو الباركود',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                prefixIcon: const Icon(Icons.search),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.filter_list),
                            onPressed: () {
                              _showFilterMenu(context, productCubit);
                            },
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      flex: 9,
                      child: products.isEmpty
                          ? const Center(
                              child: Text(
                                'لا توجد منتجات مطابقة للبحث',
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 18),
                              ),
                            )
                          : ListView.builder(
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                final profit =
                                    double.parse(product.salary ?? '0') -
                                        double.parse(product.cost ?? '0');
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  elevation: 4.0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 12.0, horizontal: 16.0),
                                    title: Text(
                                      product.name ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'الفئة: ${product.category ?? "لم يتم التحديد"}'),
                                        Text(
                                            'تكلفة الشراء: ${formattedNumber(double.parse(product.cost ?? '0.0'))} د.ع'),
                                        Text(
                                            'تكلفة البيع: ${formattedNumber(double.parse(product.salary ?? '0.0'))} د.ع'),
                                        Text(
                                            'الكمية الأولية: ${formattedNumber(product.firstQuantity!)}'),
                                        Text(
                                            'الكمية الحالية: ${product.quantity ?? ""}'),
                                        Text(
                                          profit > 0
                                              ? 'الربح بمقدار: ${formattedNumber(profit)} د.ع'
                                              : 'الخسارة بمقدار: ${formattedNumber(profit)} د.ع',
                                          style: TextStyle(
                                            color: profit >= 0
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Icon(Icons.arrow_forward_ios,
                                        color: Colors.blue.shade900),
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => UpdateProductScreen(
                                            barcode: product.parcode ?? '',
                                            fromTab: false,
                                          ),
                                        ),
                                      );
                                      if (result == true) {
                                        if (category == 'all') {
                                          productCubit.getProducts();
                                        } else if (category != null) {
                                          productCubit
                                              .getProductsByCategory(category);
                                        }
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              } else if (state is ProductsStateSuccess) {
                ProductCubit productCubit = context.read<ProductCubit>();
                final products = productCubit.filteredProducts;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (value) {
                                productCubit.searchProducts(value);
                              },
                              decoration: InputDecoration(
                                hintText: 'البحث بالاسم، الفئة أو الباركود',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                prefixIcon: const Icon(Icons.search),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.filter_list),
                            onPressed: () {
                              _showFilterMenu(context, productCubit);
                            },
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                        flex: 9,
                        child: products.isEmpty
                            ? const Center(
                                child: Text(
                                  'لا توجد منتجات مطابقة للبحث',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 18),
                                ),
                              )
                            : ListView.builder(
                                itemCount: products.length,
                                itemBuilder: (context, index) {
                                  final product = products[index];
                                  final profit =
                                      double.parse(product.salary ?? '0') -
                                          double.parse(product.cost ?? '0');

                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8.0, horizontal: 16.0),
                                    elevation: 4.0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 12.0, horizontal: 16.0),
                                      title: Text(
                                        product.name ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              'الفئة: ${product.category ?? "لم يتم التحديد"}'),
                                          Text(
                                              'تكلفة الشراء: ${formattedNumber(double.parse(product.cost ?? '0.0'))} د.ع'),
                                          Text(
                                              'تكلفة البيع: ${formattedNumber(double.parse(product.salary ?? '0.0'))} د.ع'),
                                          Text(
                                              'الكمية الأولية: ${formattedNumber(product.firstQuantity!)}'),
                                          Text(
                                              'الكمية الحالية: ${product.quantity ?? ""}'),
                                          Text(
                                            profit > 0
                                                ? 'الربح بمقدار: ${formattedNumber(profit)} د.ع'
                                                : 'الخسارة بمقدار: ${formattedNumber(profit)} د.ع',
                                            style: TextStyle(
                                                color: profit >= 0
                                                    ? Colors.green
                                                    : Colors.red),
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if(product.category != "منتج سريع")
                                          IconButton(
                                            icon: Icon(Icons.qr_code,
                                                color: Colors.blue.shade900),
                                            onPressed: () async {
                                              final result =
                                                  await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      BarcodeCreationScreen(
                                                          product: product),
                                                ),
                                              );
                                            },
                                          ),
                                          //Icon(Icons.arrow_forward_ios, color: Colors.blue.shade900),
                                        ],
                                      ),
                                      onTap: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => UpdateProductScreen(
                                              barcode: product.parcode ?? '',
                                              fromTab: false,
                                            ),
                                          ),
                                        );
                                        if (result == true) {
                                          if (category == 'all') {
                                            productCubit.getProducts();
                                          } else if (category != null) {
                                            productCubit.getProductsByCategory(
                                                category);
                                          }
                                        }
                                      },
                                    ),
                                  );
                                },
                              )),
                  ],
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

  void _showFilterMenu(BuildContext context, ProductCubit cubit) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(0.0, 90.0, 25.0, 0.0),
      items: [
        const PopupMenuItem<String>(
          value: 'bestseller',
          child: Text('الأكثر مبيعاً'),
        ),
        const PopupMenuItem<String>(
          value: 'lowstock',
          child: Text('على وشك النفاذ'),
        ),
        const PopupMenuItem<String>(
          value: 'profitable',
          child: Text('الأكثر ربحاً'),
        ),
        const PopupMenuItem<String>(
          value: 'mostNew',
          child: Text('الأحدث'),
        ),
      ],
      elevation: 8.0,
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'bestseller':
            cubit.sortByBestSelling();
            break;
          case 'lowstock':
            cubit.getProductsByQuantity();
            break;
          case 'profitable':
            cubit.sortByMostProfitable();
            break;
          case 'mostNew':
            cubit.getLatestProduct();
            break;
        }
      }
    });
  }
}
