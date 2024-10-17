import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/model/invoice_model.dart';
import 'package:flutter_application_1/domain/utils.dart';
import 'package:flutter_application_1/ui/add%20expense%20screen/add_expense_screen.dart';
import 'package:flutter_application_1/ui/categories%20screen/products_tab.dart';
import 'package:flutter_application_1/ui/home%20screen/cubit%20manage/home_cubit_manage.dart';
import 'package:flutter_application_1/ui/home%20screen/cubit%20manage/home_states_manage.dart';
import 'package:flutter_application_1/ui/main%20screen/cubit/nav%20bar%20cubit/nav_bar_cubit.dart';
import 'package:flutter_application_1/ui/reports%20screen/invoices_reports_screen.dart';
import 'package:flutter_application_1/ui/reports%20screen/trash_screen.dart';
import 'package:flutter_application_1/ui/widgets/invoice_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../categories screen/BestSellingProductsScreen.dart';
import '../customer screen/customer_screen.dart';
import '../reports screen/cubit/reports_cubit.dart';
import '../reports screen/operation_screen.dart';
import 'package:intl/intl.dart' as intl;

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => HomeCubitManage()
            ..getAllInvoices()
            ..getLast20Invo(),
        ),
        BlocProvider(create: (context) => ReportsCubit()..getManagerData()),
      ],
      child: BlocBuilder<HomeCubitManage, HomeTabStates>(
        builder: (context, state) {
          if (state is HomeTabStateLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is HomeTabStateError) {
            return Center(
              child: Text(state.error),
            );
          }

          final cubit = context.read<HomeCubitManage>();
          final reportsCubit = context.read<ReportsCubit>();

          double dailySales = cubit.calculateDailySales();
          double dailyDiscounts = cubit.calculateDailyDiscounts();
          double dailyCost = cubit.calculateDailyCost();
          double dailyProfit = cubit.calculateDailyProfit();

          final invoices = cubit.invoices;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // First Part: Daily Summary
                  _buildDailySummary(context, dailyProfit, dailySales,
                      dailyCost, dailyDiscounts),
                  const SizedBox(height: 20),

                  // Add Weekly Backup Button
                  //if (_shouldShowBackupButton())
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff4e00e8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    onPressed: () async {
                      await cubit.printBackupBdf(context);
                    },
                    child: const Text(
                      'نسخ احتياطي',
                      style: TextStyle(
                        fontSize: 14, // Smaller font size
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Second Part: Sections
                  _buildSectionsGrid(context, invoices),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff4e00e8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const BestSellingProductsScreen()));
                          },
                          child: const Text(
                            'المنتجات الأكثر مبيعاً',
                            style: TextStyle(
                                fontSize: 14, // Smaller font size
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff4e00e8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AddExpenseScreen()));
                          },
                          child: const Text(
                            'إضافة مصروفات',
                            style: TextStyle(
                                fontSize: 14, // Smaller font size
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Third Part: Last 20 Invoices
                  _buildLast20Invoices(context, invoices, reportsCubit),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailySummary(BuildContext context, double dailyProfit,
      double dailySales, double dailyCost, double dailyDiscounts) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'اليوم',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryBox(
                    context, 'الربح', '${formattedNumber(dailyProfit)} د.ع'),
                _buildSummaryBox(
                    context, 'المبيعات', '${formattedNumber(dailySales)} د.ع'),
                _buildSummaryBox(
                    context, 'التكلفة', '${formattedNumber(dailyCost)} د.ع'),
                _buildSummaryBox(context, 'الخصومات',
                    '${formattedNumber(dailyDiscounts)} د.ع'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBox(BuildContext context, String title, String value) {
    return Expanded(
      child: SizedBox(
        height: 100,
        child: Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style:
                      const TextStyle(fontSize: 15, color: Colors.blueAccent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionsGrid(BuildContext context, List<Invoice> invoices) {
    final navBarCubit = context.read<NavBarCubit>(); // Access NavBarCubit
    return GridView.count(
      crossAxisCount: 3, // Set to 3 for three squares per row
      shrinkWrap: true,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildCard(
          context,
          title: 'الفواتير',
          icon: Icons.receipt,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const InvoicesReportsScreen(),
              ),
            );
          },
        ),
        _buildCard(
          context,
          title: 'المنتجات',
          icon: Icons.shopping_bag,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProductsScreen(),
                settings: const RouteSettings(arguments: 'all'),
              ),
            );
          },
        ),
        BlocBuilder<NavBarCubit, int>(builder: (context, state) {
          return _buildCard(
            context,
            title: 'التقارير',
            icon: Icons.bar_chart,
            onTap: () {
              log('message');
              navBarCubit.updateIndex(3); // Switch to ReportsTab
            },
          );
        }),
        _buildCard(
          context,
          title: 'العمليات',
          icon: Icons.history,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OperationsScreen()),
            );
          },
        ),
        _buildCard(
          context,
          title: 'العملاء',
          icon: Icons.people,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomersScreen()),
            );
          },
        ),
        _buildCard(
          context,
          title: 'سلة المهملات',
          icon: Icons.delete,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TrashScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLast20Invoices(
      BuildContext context, List<Invoice> invoices, ReportsCubit reportsCubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'آخر 20 فاتورة',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: invoices.length,
          itemBuilder: (context, index) {
            Invoice invoice = invoices[index];
            final formattedDate =
                intl.DateFormat('yyyy/MM/dd').format(invoice.date);
            final formattedTime =
                intl.DateFormat('hh:mm a').format(invoice.date);

            bool hasRefundedProduct =
                invoice.products.any((product) => product.isRefunded);
            bool hasExchangedProduct =
                invoice.products.any((product) => product.isReplaced);
            bool hasReplacedDoneProduct =
                invoice.products.any((product) => product.isReplacedDone);

            return showInvoiceCard(
                invoice,
                formattedDate,
                formattedTime,
                hasRefundedProduct,
                hasExchangedProduct,
                hasReplacedDoneProduct,
                context,
                reportsCubit);
          },
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context,
      {required String title,
      required IconData icon,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4E00E9), Color(0xFF4E00E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 30, // Smaller icon size
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14, // Smaller font size
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
