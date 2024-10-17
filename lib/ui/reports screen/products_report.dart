
import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/model/expense_model.dart';
import 'package:flutter_application_1/domain/utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'cubit/reports_cubit.dart';
import 'cubit/reports_states.dart';
import '../../../data/model/product_model.dart';
import '../../../data/model/invoice_model.dart';

class ProductReportsScreen extends StatelessWidget {
  const ProductReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String,List>;
    List<Invoice> filteredInvoices = args['filteredInvoices'] as List<Invoice>;
    List<Expense> filteredExpenses = args['filteredExpenses'] as List<Expense>; 
    return BlocProvider(
      create: (context) => ReportsCubit(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'تقارير المنتجات',
              style: TextStyle(color: Colors.white, fontFamily: 'font1'),
            ),
            centerTitle: true,
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
          ),
          body: BlocBuilder<ReportsCubit, ReportsStates>(
            builder: (context, state) {
              if (state is ReportsLoadingState) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ReportsErrorState) {
                return Center(child: Text(state.error));
              }

              ReportsCubit reportsCubit = context.read<ReportsCubit>();
              List<Product> productSales =
                  reportsCubit.getProductsFromInvoices(filteredInvoices);

              if (productSales.isEmpty) {
                return const Center(
                  child: Text('لا توجد بيانات لعرضها'),
                );
              }

              return Column(
                children: [
                  _buildSalesChart(productSales),
                  _buildSummary(reportsCubit, filteredInvoices,filteredExpenses),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSalesChart(List<Product> productSales) {
    productSales =
        productSales.where((product) => product.category != 'منتج سريع').toList();

    if (productSales.isEmpty) {
      return const Center(
        child: Text('لا توجد بيانات لعرضها في الرسم البياني'),
      );
    }

    return Expanded(
      child: SfCartesianChart(
        primaryXAxis: const DateTimeAxis(),
        title: const ChartTitle(text: 'توجهات المبيعات'),
        legend: const Legend(isVisible: true),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CartesianSeries>[
          LineSeries<Product, DateTime>(
            dataSource: productSales,
            xValueMapper: (Product product, _) =>
                DateTime.parse(product.createdDate!.toString()),
            yValueMapper: (Product product, _) =>
                double.parse(product.salary!) *
                (product.firstQuantity! - double.parse(product.quantity!)),
            name: 'مبيعات',
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(
      ReportsCubit reportsCubit, List<Invoice> filteredInvoices,List<Expense> filteredExpenses) {
    final totalSales =
        reportsCubit.calculateTotalSalesForInvoices(filteredInvoices);
    final totalCost =
        reportsCubit.totalCostOfProductsFromInvoices(filteredInvoices);
    final totalDiscounts =
        reportsCubit.calculateTotalDiscountsForInvoices(filteredInvoices);
    final totalProfit = totalSales - totalCost;
    final achievedProfit = totalProfit - totalDiscounts;

    return FutureBuilder<double>(
      future: reportsCubit.calculateTotalExpenses(filteredExpenses), // Fetch total expenses
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final totalExpenses = snapshot.data!;
        final netProfit = achievedProfit - totalExpenses;
        final profitPercentage =
            totalSales > 0 ? (netProfit / totalSales) * 100 : 0;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ملخص التقرير',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildSummaryItem('إجمالي المبيعات بدون الخصومات', totalSales, false),
              _buildSummaryItem('إجمالي المبيعات بعد الخصومات',
                  totalSales - totalDiscounts, false),
              _buildSummaryItem('إجمالي التكلفة', totalCost, false),
              _buildSummaryItem('إجمالي الخصومات', totalDiscounts, false),
              _buildSummaryItem('إجمالي الربح بدون خصومات', totalProfit, false),
              achievedProfit > 0
                  ? _buildSummaryItem(
                      'إجمالي الربح بعد الخصومات', achievedProfit, false)
                  : _buildSummaryItem('اجمالي الخسارة', (achievedProfit), true),
              _buildSummaryItem('إجمالي المصروفات', totalExpenses, false),
              netProfit > 0
                  ? _buildSummaryItem('إجمالي الربح الصافي', netProfit, false)
                  : _buildSummaryItem('اجمالي صافي الخسارة', netProfit, true),
              _buildSummaryItem('نسبة الربح الصافي', profitPercentage.toDouble(), false, isPercentage: true),

            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String title, double value, bool minus, {bool isPercentage = false}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: minus == true ? Colors.red : Colors.black,
        ),
      ),
      Text(
        isPercentage
          ? '${value.toStringAsFixed(2)}%'  // Display percentage
          : '${formattedNumber(value)} د.ع', // Display currency
        style: TextStyle(
          fontSize: 16,
          color: minus == true ? Colors.red : Colors.black,
        ),
      ),
    ],
  );
}
}
