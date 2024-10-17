import 'package:flutter/material.dart';
import 'package:flutter_application_1/ui/categories%20screen/cubit/products_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/model/product_model.dart';
import '../../domain/utils.dart';
import 'cubit/product_cubit.dart';

class BestSellingProductsScreen extends StatelessWidget {
  const BestSellingProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'أفضل المنتجات مبيعاً',
            style: TextStyle(color: Colors.white, fontSize: 28, fontFamily: 'font1'),
          ),
          backgroundColor: const Color(0xff4e00e8),
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
        ),
        body: BlocProvider(
          create: (_) => ProductCubit()..fetchAndFilterProducts(),
          child: BlocBuilder<ProductCubit, ProductsState>(
            builder: (context, state) {
              if (state is ProductsStateLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ProductsStateError) {
                return Center(child: Text(state.error));
              } else if (state is ProductsStateSuccess) {
                final productCubit = context.read<ProductCubit>();
                final products = productCubit.filteredProducts;
      
                return Column(
                  children: [
                    _buildFilterOptions(context, productCubit),
                    Expanded(
                      child: products.isEmpty
                          ? const Center(child: Text('لا توجد منتجات متاحة'))
                          : ListView.builder(
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                return _buildProductCard(product);
                              },
                            ),
                    ),
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

  Widget _buildFilterOptions(BuildContext context, ProductCubit productCubit) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: productCubit.filterOption,
            hint: const Text('اختر الفترة الزمنية'),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            items: [
              'اليوم',
              'الشهر الحالي',
              'السنة الحالية',
              'تاريخ مخصص',
            ]
                .map((option) => DropdownMenuItem(
                      value: option,
                      child: Text(option),
                    ))
                .toList(),
            onChanged: (value) async {
              productCubit.setFilterOption(value!);
              if (value == 'تاريخ مخصص') {
                DateTimeRange? dateRange = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (dateRange != null) {
                  productCubit.setDateRange(dateRange);
                }
              }
            },
          ),
        ),
        const SizedBox(width: 8), // Add spacing between Dropdown and IconButton
        IconButton(
          icon: const Icon(Icons.filter_list, color: Colors.black),
          onPressed: () {
            _showSortOptionsDialog(context,productCubit);
          },
        ),
      ],
    ),
  );
}


  Widget _buildProductCard(Product product) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name ?? 'بدون اسم',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              'الفئة: ${product.category ?? 'غير محدد'}',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              'الباركود: ${product.parcode ?? 'غير محدد'}',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              'السعر: ${formattedNumber(double.parse(product.salary ?? '0'))} د.ع',
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              'الكمية المباعة: ${product.quantity ?? '0'}',
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              'الربح: ${formattedNumber(product.profit ?? 0)} د.ع',
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortOptionsDialog(BuildContext context,ProductCubit productCubit) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'فرز حسب',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.trending_up),
                title: const Text('الأكثر مبيعاً'),
                onTap: () {
                  productCubit.fetchAndFilterProducts();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.trending_down),
                title: const Text('الأقل مبيعاً'),
                onTap: () {
                  productCubit.sortByLowestSelling();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('الفئة أبجديًا'),
                onTap: () {
                  productCubit.sortByCategoryAlphabetically();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('الأحدث حسب تاريخ البيع'),
                onTap: () {
                  productCubit.sortByLatestSale();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
