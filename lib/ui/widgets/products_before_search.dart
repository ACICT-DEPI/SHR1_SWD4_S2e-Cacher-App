import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/domain/utils.dart';
import 'package:flutter_application_1/ui/categories%20screen/update_product_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/model/product_model.dart';
import '../bill screen/cubit/invoice_cubit.dart';
import '../bill screen/cubit/invoice_states.dart';

Widget productBeforeSearch(InvoiceCubit invoiceCubit, Product product,
    double result, BuildContext context, bool isInvoice, bool isSelected) {
  return ListTile(
    tileColor: Colors.white,
    title: Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueAccent),
      ),
      child: Column(
        children: [
          ListTile(
            tileColor: isSelected == true
                ? Colors.blue.shade800.withOpacity(0.6)
                : null,
            style: ListTileStyle.drawer,
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  'تكلفة الشراء: ${formattedNumber(double.parse(product.cost!))} د.ع',
                  style: TextStyle(
                      color: isSelected == true ? Colors.white : Colors.black),
                ),
                Text(
                  'تكلفة البيع: ${formattedNumber(double.parse(product.salary!))} د.ع',
                  style: TextStyle(
                      color: isSelected == true ? Colors.white : Colors.black),
                ),
                isInvoice == true
                    ? const SizedBox()
                    : Text(
                        result > 0
                            ? 'الربح بمقدار: ${formattedNumber(result)} د.ع'
                            : 'الخسارة بمقدار: ${formattedNumber(result)} د.ع',
                        style: TextStyle(
                            color: result >= 0 ? Colors.green : Colors.red),
                      ),
              ],
            ),
            title: Text(
              product.name!,
              style: TextStyle(
                  color: isSelected == true ? Colors.white : Colors.black),
            ),
            subtitle: Text(
              'الفئة: ${product.category ?? "لم يتم التحديد"}',
              style: TextStyle(
                  color: isSelected == true ? Colors.white : Colors.black),
            ),
            onTap: isInvoice == true
                ? () {}
                : () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => UpdateProductScreen(
                                  barcode: product.parcode ?? '',
                                  fromTab: false,
                                )));
                  },
          ),
          isInvoice == true
              ? productCounter(invoiceCubit, product, context)
              : const SizedBox(),
        ],
      ),
    ),
  );
}

Widget productCounter(
    InvoiceCubit invoiceCubit, Product product, BuildContext context) {
  return BlocBuilder<InvoiceCubit, InvoiceStates>(
    builder: (context, state) {
      // Get the current product count from the cubit
      final productCount = invoiceCubit.productCounts[product.productId ?? product.parcode] ?? 0;
      final isLoading = invoiceCubit.productLoadingStates[product.productId ?? product.parcode] ?? false;

      // Check if the product is a quick product and has not been added yet
      if (product.category == 'منتج سريع' && productCount == 0) {
        // Add the product with a count of 1 automatically
        WidgetsBinding.instance.addPostFrameCallback((_) {
          invoiceCubit.incrementLocalProductCount(product, 1, context);
        });
        return const SizedBox.shrink(); // Hide the UI until the product is added
      }

      if (productCount == 0) {
        // Show "Add" button if the product count is 0
        return ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.blue.shade900),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
                side: const BorderSide(color: Colors.blue, width: 2),
              ),
            ),
          ),
          onPressed: () {
            invoiceCubit.incrementLocalProductCount(product, 1, context);
          },
          child: const Text(
            'إضافة +',
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
        );
      }

      // Return the counter UI if the product count is greater than 0
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          isLoading
              ? const CircularProgressIndicator()
              : IconButton(
                  icon: const Icon(Icons.add_circle),
                  color: Colors.blue.shade900,
                  onPressed: () {
                    invoiceCubit.incrementLocalProductCount(product, 1, context);
                  },
                ),
          Text(
            '$productCount',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          isLoading
              ? const CircularProgressIndicator()
              : productCount > 1
                  ? IconButton(
                      icon: Icon(
                        Icons.remove_circle,
                        color: Colors.red.shade900,
                      ),
                      onPressed: () {
                        invoiceCubit.decrementLocalProductCount(product, 1);
                      },
                    )
                  : ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.red.shade900),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            side: const BorderSide(color: Colors.red, width: 2),
                          ),
                        ),
                      ),
                      onPressed: () {
                        invoiceCubit.decrementLocalProductCount(product, 1);
                      },
                      child: const Text(
                        'حذف -',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ),
        ],
      );
    },
  );
}
