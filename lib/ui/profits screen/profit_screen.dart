import 'package:flutter/material.dart';
import 'package:flutter_application_1/domain/utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubit/profit_cubit.dart';
import 'cubit/profit_states.dart';
import '../../../data/model/product_model.dart';

class ProfitPage extends StatelessWidget {
  const ProfitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocProvider(
        create: (context) => ProfitCubit()..fetchProductsFromInvoices(),
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'أرباح المنتجات',
              style: TextStyle(color: Colors.white, fontFamily: 'font1'),
            ),
            backgroundColor: const Color(0xff4e00e8),
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
            centerTitle: true,
          ),
          body: BlocBuilder<ProfitCubit, ProfitStates>(
            builder: (context, state) {
              if (state is ProfitLoadingState) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ProfitErrorState) {
                return Center(child: Text(state.error));
              }
              ProfitCubit profitCubit = context.read<ProfitCubit>();
              List<Product?> products = profitCubit.products;

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];

                        return Card(
                          margin: const EdgeInsets.all(10),
                          child: ListTile(
                            title: Text(product?.name ?? 'no name', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('الفئة: ${product?.category ?? "لم يتم التحديد"}', style: const TextStyle(fontSize: 16)),
                                Text('التكلفة: ${formattedNumber(double.parse(product?.cost ?? '0.0'))} د.ع', style: const TextStyle(fontSize: 16)),
                                Text('السعر: ${formattedNumber(double.parse(product?.salary ?? '0.0'))} د.ع', style: const TextStyle(fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(
                                  (double.parse(product?.salary ?? '0.0') - double.parse(product?.cost ?? '0.0')) > 0
                                      ? 'الربح: ${formattedNumber(product?.profit ?? 0.0)} د.ع'
                                      : 'الخسارة: ${formattedNumber(product?.profit ?? 0.0)} د.ع',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: (product?.profit ?? 0.0) >= 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.blue.shade900,
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8))),
                    child: Text(
                      'الأرباح الكلية: ${formattedNumber(profitCubit.totalProfit())} د.ع',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
