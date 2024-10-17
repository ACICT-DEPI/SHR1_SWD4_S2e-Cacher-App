import 'package:flutter/material.dart';
import 'package:flutter_application_1/domain/utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import '../../data/model/product_model.dart';
import '../widgets/custom_dialogs.dart';
import 'BarcodeCreationScreen.dart';
import 'cubit/product_cubit.dart';
import 'cubit/products_state.dart';
import 'products_tab.dart';
import 'update_product_screen.dart';

class CategoriesTab extends StatelessWidget {
  const CategoriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => ProductCubit()
              ..fetchCategories()
              ..getLatest20Products()
              ..getTopLowStockProducts()
              ..getOutOfStockProducts(),
          ),
        ],
        child: BlocBuilder<ProductCubit, ProductsState>(
          builder: (context, state) {
            if (state is CategoriesStateLoading ||
                state is ProductsStateLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is CategoriesStateError ||
                state is ProductsStateError) {
              return Center(child: Text((state as dynamic).error));
            } else if (state is CategoriesStateEmpty) {
              return const Center(child: Text('لا توجد فئات حالياً'));
            } else if (state is ProductsStateEmpty) {
              return const Center(child: Text('لا توجد منتجات حالياً'));
            } else if (state is CategoriesStateSuccess ||
                state is ProductsStateSuccess) {
              final productCubit = context.read<ProductCubit>();
              final categories = productCubit.categories;
              final latestProducts = productCubit.latestProducts;
              final lowStockProducts = productCubit.lowStockProducts;
              final outOfStockProducts = productCubit.outOfStockProducts;

              return RefreshIndicator(
                onRefresh: () async {
                  productCubit.fetchCategories();
                  productCubit.getLatest20Products();
                  productCubit.getTopLowStockProducts();
                  productCubit.getOutOfStockProducts();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      const Center(
                        child: Text(
                          'اسحب للاسفل بعد كل عملية للتحديث',
                          style:
                              TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade900,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProductsScreen(),
                                    settings: const RouteSettings(
                                        arguments: 'all'),
                                  ),
                                );
                              },
                              child: const Text(
                                'عرض كل المنتجات',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(
                            left: 16.0, right: 16, bottom: 8, top: 8),
                        child: Text(
                          'الفئات',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      categories.isEmpty
                          ? Center(
                              child: Image.asset(
                                  'assets/images/no_products.gif'),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 2.5,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: categories.length,
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                return GestureDetector(
                                  onLongPress: () {
                                    showConfirmationDialog(
                                      'هل أنت متأكد من حذف الفئة "$category"؟',
                                      context,
                                      () {
                                        productCubit.deleteCategory(category);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'تم حذف الفئة "$category" بنجاح.'),
                                          ),
                                        );
                                      },
                                      'delete_category_dialog',
                                    );
                                  },
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.blue.shade800,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ProductsScreen(),
                                          settings: RouteSettings(
                                              arguments: category),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      category,
                                      style: const TextStyle(
                                          color: Colors.white),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              },
                            ),
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'منتجات علي وشك النفاذ',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      lowStockProducts.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.only(right: 15.0),
                              child: Text('لا توجد منتجات حالياً'),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(8.0),
                              itemCount: lowStockProducts.length,
                              itemBuilder: (context, index) {
                                final product = lowStockProducts[index];
                                return ProductCard(product: product);
                              },
                            ),
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'منتجات منتهية',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      outOfStockProducts.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.only(right: 15.0),
                              child: Text('لا توجد منتجات منتهية حالياً'),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(8.0),
                              itemCount: outOfStockProducts.length,
                              itemBuilder: (context, index) {
                                final product = outOfStockProducts[index];
                                return ProductCard(product: product);
                              },
                            ),
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'أحدث المنتجات',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      latestProducts.isEmpty
                          ? const Center(
                              child: Text('لا توجد منتجات حالياً'))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(8.0),
                              itemCount: latestProducts.length,
                              itemBuilder: (context, index) {
                                final product = latestProducts[index];
                                return ProductCard(product: product);
                              },
                            ),
                    ],
                  ),
                ),
              );
            } else {
              return const Center(child: Text('حالة غير معروفة'));
            }
          },
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UpdateProductScreen(
                barcode: product.parcode ?? '',
                fromTab: true,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name ?? 'بدون اسم',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (product.category != "منتج سريع")
                      IconButton(
                        icon: const Icon(Icons.qr_code, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BarcodeCreationScreen(product: product),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'الفئة: ${product.category ?? 'غير محدد'}',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  'الباركود: ${product.parcode ?? 'غير محدد'}',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'السعر: ${formattedNumber(double.parse(product.salary ?? '0'))} د.ع',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    Text(
                      'التكلفة: ${formattedNumber(double.parse(product.cost ?? '0'))} د.ع',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الكمية الحالية: ${product.quantity ?? '0'}',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    Text(
                      'الربح: ${formattedNumber(product.profit ?? 0)} د.ع',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'الكمية الأولية: ${formattedNumber(product.firstQuantity ?? 0.0)}',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  'تاريخ الإنشاء: ${product.createdDate != null ? intl.DateFormat('yyyy-MM-dd').format(product.createdDate!) : 'غير محدد'}',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
