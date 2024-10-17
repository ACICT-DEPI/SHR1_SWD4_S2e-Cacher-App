
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../categories screen/cubit/product_cubit.dart';
import '../categories screen/cubit/products_state.dart';

Widget buildCategoryRow(BuildContext context, ProductCubit productCubit) {
  return Padding(
    padding: const EdgeInsets.all(10.0),
    child: Column(
      children: [
        Row(
          children: [
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(
                  const Color.fromARGB(255, 25, 28, 235),
                ),
                shape: WidgetStateProperty.all(const CircleBorder(
                  side: BorderSide(
                    color: Colors.transparent,
                    width: 1,
                  ),
                )),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    String newCategory = '';
                    return AlertDialog(
                      title: const Text('إضافة صنف جديد'),
                      content: TextField(
                        onChanged: (value) {
                          newCategory = value;
                        },
                        decoration:
                            const InputDecoration(hintText: "اسم الصنف"),
                      ),
                      actions: [
                        TextButton(
                          child: const Text('إلغاء'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text('إضافة'),
                          onPressed: () {
                            if (newCategory.isNotEmpty) {
                              productCubit.addCategory(newCategory);
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Icon(Icons.add, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: BlocBuilder<ProductCubit, ProductsState>(
                builder: (context, state) {
                  if (state is CategoriesStateLoading || productCubit.categories.isEmpty) {
                    return const Center(
                      child: SizedBox(
                        height: 30,
                        width: 30,
                        child: CircularProgressIndicator(),
                      ),
                    );
                  } else if (state is CategoriesStateSuccess || state is ProductsStateSuccess) {
                    // Set the initial category as the product's category, or an empty string
                    final String? initialCategory = productCubit.product?.category;

                    return FormBuilderDropdown<String>(
                      name: 'category',
                      decoration: const InputDecoration(
                        labelText: 'الصنف',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: initialCategory, // Set product category as initial value
                      items: productCubit.categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        productCubit.category.text = newValue ?? '';
                      },
                      validator: FormBuilderValidators.required(),
                    );
                  } else {
                    return const Text('حدث خطأ أثناء تحميل الأصناف');
                  }
                },
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
