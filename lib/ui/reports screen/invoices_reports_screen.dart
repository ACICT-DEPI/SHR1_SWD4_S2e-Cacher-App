import 'package:flutter/material.dart';
import 'package:flutter_application_1/ui/reports%20screen/cubit/reports_cubit.dart';
import 'package:flutter_application_1/ui/reports%20screen/cubit/reports_states.dart';
import 'package:flutter_application_1/ui/reports%20screen/products_report.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import '../../data/model/expense_model.dart';
import '../../data/model/invoice_model.dart';
import '../../domain/utils.dart';
import '../widgets/invoice_card.dart';

class InvoicesReportsScreen extends StatelessWidget {
  const InvoicesReportsScreen({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
            backgroundColor: backgroundColor, // Set background color
            appBar: AppBar(
              backgroundColor: primaryColor, // Use primary color for AppBar
              title: const Text(
                'تقارير الفواتير',
                style: TextStyle(color: buttonTextColor, fontFamily: 'font1'),
              ),
              centerTitle: true,
              leading: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 25,
                  color: buttonTextColor, // Button text color
                ),
              ),
            ),
            body: BlocProvider(
              create: (context) => ReportsCubit()
                ..getAllInvoices()
                ..getManagerData()
                ..getAllExpenses(),
              child: BlocBuilder<ReportsCubit, ReportsStates>(
                builder: (context, state) {
                  if (state is ReportsLoadingState) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (state is ReportsErrorState) {
                    return Center(
                      child: Text(state.error),
                    );
                  }

                  ReportsCubit reportsCubit = context.read<ReportsCubit>();
                  List<Invoice> filteredInvoices =
                      reportsCubit.getFilteredInvoices();
                  List<Expense> filteredExpenses =
                      reportsCubit.getFilteredExpensesByTime();

                  return RefreshIndicator(
                    onRefresh: () async {
                      reportsCubit.getAllInvoices();
                      reportsCubit.getManagerData();
                      reportsCubit.getAllExpenses();
                      if (filteredInvoices.isNotEmpty) {
                        reportsCubit.getFilteredInvoices();
                      }
                    },
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: reportsCubit.filterOption,
                                  hint: const Text('اختر الفترة الزمنية'),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: const BorderSide(
                                          color:
                                              borderColor), // Consistent border color
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
                                    reportsCubit.setFilterOption(value!);
                                    if (value == 'تاريخ مخصص') {
                                      DateTimeRange? dateRange =
                                          await showDateRangePicker(
                                        context: context,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2100),
                                      );
                                      if (dateRange != null) {
                                        reportsCubit.setDateRange(dateRange);
                                      }
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    labelText: 'العميل أو كود الفاتورة',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: const BorderSide(
                                          color:
                                              borderColor), // Consistent border color
                                    ),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.qr_code_scanner),
                                      onPressed: () async {
                                        // Start the barcode scanner
                                        var result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const SimpleBarcodeScannerPage(),
                                          ),
                                        );
                                        if (result != null) {
                                          reportsCubit
                                              .setSearchDecimalQuery(result);
                                        }
                                      },
                                    ),
                                  ),
                                  onChanged: (value) {
                                    reportsCubit.setSearchQuery(value);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: DropdownButtonFormField<String>(
                            value: reportsCubit.productStatusFilterOption,
                            hint: const Text('اختر حالة الفاتورة'),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(color: borderColor),
                              ),
                            ),
                            items: [
                              'تحتوي علي منتج بديل',
                              'تحتوي علي منتج مستبدل',
                              'تحتوي علي منتج مسترجع',
                              'بدون عمليات',
                            ]
                                .map((option) => DropdownMenuItem(
                                      value: option,
                                      child: Text(option),
                                    ))
                                .toList(),
                            onChanged: (value) async {
                              reportsCubit.setProductStatusFilter(value!);
                            },
                          ),
                        ),
                        const Text(
                          'اسحب للاسفل بعد كل عملية للتحديث',
                          style: TextStyle(
                              color: hintTextColor,
                              fontSize: 12), // Consistent hint text color
                        ),
                        filteredInvoices.isEmpty
                            ? Expanded(
                                child: Center(
                                  child: Image.asset(
                                    'assets/images/no_products.gif',
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              )
                            : Expanded(
                                child: ListView.builder(
                                  itemBuilder: (context, index) {
                                    final invoice = filteredInvoices[index];
                                    final formattedDate =
                                        intl.DateFormat('yyyy/MM/dd')
                                            .format(invoice.date);
                                    final formattedTime =
                                        intl.DateFormat('hh:mm a')
                                            .format(invoice.date);

                                    bool hasRefundedProduct = invoice.products
                                        .any((product) => product.isRefunded);
                                    bool hasExchangedProduct = invoice.products
                                        .any((product) => product.isReplaced);
                                    bool hasReplacedDoneProduct =
                                        invoice.products.any((product) =>
                                            product.isReplacedDone);

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
                                  itemCount: filteredInvoices.length,
                                ),
                              ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        primaryColor, // Use primary color for buttons
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15, horizontal: 30),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: reportsCubit.isGeneratingReport
                                      ? null
                                      : () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return ReportOptionsDialog(
                                                onSubmit: (selectedOptions) {
                                                  reportsCubit.invoiceReport(
                                                    filteredInvoices,
                                                    reportsCubit,
                                                    selectedOptions,
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                  child: reportsCubit.isGeneratingReport
                                      ? const CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<
                                                  Color>(
                                              buttonTextColor), // Button text color
                                        )
                                      : const Text('   تصدير الفواتير   ',
                                          style: TextStyle(
                                              color:
                                                  buttonTextColor)), // Button text color
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15, horizontal: 30),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: reportsCubit.isViewingProductReport
                                      ? null
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const ProductReportsScreen(),
                                                settings: RouteSettings(
                                                    arguments: {
                                                      'filteredInvoices':
                                                          filteredInvoices,
                                                      'filteredExpenses':
                                                          filteredExpenses
                                                    })),
                                          );
                                        },
                                  child: reportsCubit.isViewingProductReport
                                      ? const CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<
                                                  Color>(
                                              buttonTextColor), // Button text color
                                        )
                                      : const Text('عرض تقارير المنتج',
                                          style: TextStyle(
                                              color:
                                                  buttonTextColor)), // Button text color
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )));
  }
}

class ReportOptionsDialog extends StatefulWidget {
  final Function(Set<String>) onSubmit;

  const ReportOptionsDialog({required this.onSubmit, super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ReportOptionsDialogState createState() => _ReportOptionsDialogState();
}

class _ReportOptionsDialogState extends State<ReportOptionsDialog> {
  final Set<String> _selectedOptions = {};

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('تحديد تفاصيل التقرير'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              const Text(
                'سيتم اختيار الوقت المحدد تلقائيا',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              _buildCheckbox('إجمالي الأرباح'),
              _buildCheckbox('التكلفة'),
              _buildCheckbox('تفاصيل الفواتير'),
              _buildCheckbox('معلومات العملاء'),
              _buildCheckbox('المبيعات'),
              _buildCheckbox('إجمالي الخصومات'),
              _buildCheckbox('ملخص التقرير'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('إلغاء'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('تقديم'),
            onPressed: () {
              widget.onSubmit(_selectedOptions);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String title) {
    return CheckboxListTile(
      title: Text(title),
      value: _selectedOptions.contains(title),
      onChanged: (bool? value) {
        setState(() {
          if (value == true) {
            _selectedOptions.add(title);
          } else {
            _selectedOptions.remove(title);
          }
        });
      },
    );
  }
}
