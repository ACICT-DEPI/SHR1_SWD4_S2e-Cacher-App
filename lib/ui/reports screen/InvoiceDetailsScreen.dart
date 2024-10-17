import 'dart:developer';
import 'package:connectivity_checker/connectivity_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/model/product_model.dart';
import 'package:flutter_application_1/domain/utils.dart';
import 'package:flutter_application_1/ui/bill%20screen/product_screen.dart';
import 'package:flutter_application_1/ui/widgets/custom_dialogs.dart';
import 'package:intl/intl.dart' as intl;
import '../../data/model/invoice_model.dart';
import 'cubit/reports_cubit.dart';

class InvoiceDetailsScreen extends StatelessWidget {
  final Invoice invoice;
  final ReportsCubit reportsCubit;

  const InvoiceDetailsScreen({
    super.key,
    required this.invoice,
    required this.reportsCubit,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل الفاتورة',
              style: TextStyle(color: Colors.white, fontFamily: 'font1')),
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
          backgroundColor: const Color(0xff4e00e8), // Primary consistent color
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              _buildInvoiceHeader(context),
              const SizedBox(height: 16),
              _buildProductList(context),
              const SizedBox(height: 16),
              _buildDeleteButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceHeader(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اسم المشتري: ${invoice.clientModel?.clientName ?? 'مجهول'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'رقم الهاتف: ${invoice.clientModel!.clientPhone.isEmpty ? 'مجهول' : invoice.clientModel?.clientPhone ?? 'مجهول'}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'عنوان المشتري: ${invoice.clientModel!.cleintAddress.isEmpty ? 'مجهول' : invoice.clientModel?.cleintAddress ?? 'مجهول'}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'السعر بدون خصومات: ${formattedNumber(double.parse(invoice.paidUp))} د.ع',
              style: const TextStyle(fontSize: 16),
            ),
            Text('طريقة الدفع: ${invoice.paymentMethod}',
                style: const TextStyle(fontSize: 16)),
            Text(
              'الخصم: ${formattedNumber(double.parse(invoice.discount))} د.ع',
              style: const TextStyle(fontSize: 16),
            ),
            Text('الصافي: ${formattedNumber(invoice.totalCoast)} د.ع',
                style: const TextStyle(fontSize: 16)),
            Text(
              'التاريخ: ${intl.DateFormat('dd-MM-yyyy').format(invoice.date)}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'الوقت: ${intl.DateFormat('hh:mm a').format(invoice.date)}',
              style: const TextStyle(fontSize: 16),
            ),
            Text('عدد المنتجات: ${invoice.products.length}',
                style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: invoice.products.length,
      itemBuilder: (context, index) {
        final product = invoice.products[index];
        log(product.name ?? 'no name');
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name ?? 'مجهول',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('الفئة: ${product.category}',
                    style: const TextStyle(fontSize: 16)),
                Text(
                    'السعر: ${formattedNumber(double.parse(product.salary!))} د.ع',
                    style: const TextStyle(fontSize: 16)),
                Text(
                    '${product.createdDate?.day}-${product.createdDate?.month}-${product.createdDate?.year}',
                    style: const TextStyle(fontSize: 16)),
                if (product.isRefunded)
                  const Text('تم الإرجاع', style: TextStyle(color: Color(0xff8b00e8))), // Dark purple for refunded
                if (product.isReplaced)
                  const Text('تم الاستبدال',
                      style: TextStyle(color: exchangedProductColor)), // Teal for replaced
                const SizedBox(height: 8),
                _buildActionButtons(context, product, index),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, Product product, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (product.isReplacedDone && invoice.replacedinvoiceId != null)
          ElevatedButton(
            onPressed: () async {
              final oldInvoice =
                  await reportsCubit.getInvoiceById(invoice.replacedinvoiceId!);
              if (oldInvoice != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InvoiceDetailsScreen(
                      invoice: oldInvoice,
                      reportsCubit: reportsCubit,
                    ),
                  ),
                );
              } else {
                showErrorDialog(context, 'لم يتم العثور على الفاتورة الأصلية.');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff8b00e8), // Dark purple consistent
              foregroundColor: Colors.white,
            ),
            child: const Text('عرض الفاتورة الأصلية'),
          ),
        if (product.isReplaced)
          ElevatedButton(
            onPressed: () async {
              final replacedInvoice = await reportsCubit
                  .fetchInvoiceByProductId(product.productId!);
              if (replacedInvoice != null) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InvoiceDetailsScreen(
                      invoice: replacedInvoice,
                      reportsCubit: reportsCubit,
                    ),
                  ),
                );
              } else {
                showErrorDialog(context,
                    'لم يتم العثور على الفاتورة الخاصة بالمنتج البديل.');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff00bfa5), // Teal consistent
              foregroundColor: Colors.white,
            ),
            child: const Text('عرض الفاتورة الخاصة بالمنتج البديل'),
          ),
        if (!product.isRefunded && !product.isReplaced)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () async {
                  showConfirmationDialog('هل أنت متأكد من الإرجاع', context,
                      () async {
                    bool isOffline =
                        (await ConnectivityWrapper.instance.isConnected);
                    if (isOffline) {
                      await reportsCubit
                          .handleReturnProduct(invoice.invoiceId,
                              product.productId!, index, context)
                          .then((_) {
                        Navigator.pop(context);
                      });
                    } else {
                      showErrorDialog(
                          context, 'تحقق من اتصالك بالإنترنت ثم اعد المحاولة');
                    }
                  }, 'returnConfirm');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff8b00e8), // Dark purple
                  foregroundColor: Colors.white,
                ),
                child: const Text('ارجاع'),
              ),
              ElevatedButton(
                onPressed: () {
                  showConfirmationDialog(
                      'هل أنت متأكد من عملية الإستبدال؟', context, () async {
                    bool isOffline =
                        (await ConnectivityWrapper.instance.isConnected);
                    if (isOffline) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InvoiceProductScreen(),
                          settings: RouteSettings(
                            arguments: {
                              'oldInvoice': invoice,
                              'isExchange': true,
                              'oldProductId': product.productId,
                              'index': index,
                            },
                          ),
                        ),
                      ).then((_) {
                        Navigator.of(context).pop();
                      });
                    } else {
                      showErrorDialog(
                          context, 'تحقق من اتصالك بالإنترنت ثم اعد المحاولة');
                    }
                  }, 'exchangeConfirm');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: exchangedProductColor, // Teal consistent
                  foregroundColor: Colors.white,
                ),
                child: const Text('استبدال'),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildDeleteButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff4e00e8), // Consistent primary button color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: AlertDialog(
                    title: const Text('حذف الفاتورة'),
                    content: const Text(
                        'هل ترغب في حذف الفاتورة مباشرة أو نقلها إلى سلة المهملات؟'),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          bool isOffline =
                              (await ConnectivityWrapper.instance.isConnected);
                          if (isOffline) {
                            await reportsCubit.moveToTrash(invoice.invoiceId);
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                            reportsCubit.getAllInvoices();
                          } else {
                            showErrorDialog(context,
                                'تحقق من اتصالك بالإنترنت ثم اعد المحاولة');
                          }
                        },
                        child: const Text('نقل إلى سلة المهملات'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('إلغاء'),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: const Text(
              'حذف الفاتورة',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
