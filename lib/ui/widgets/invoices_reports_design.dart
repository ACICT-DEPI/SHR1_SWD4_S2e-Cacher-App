import 'package:flutter/services.dart';
import 'package:flutter_application_1/data/model/product_model.dart';
import 'package:flutter_application_1/domain/utils.dart';
import 'package:flutter_application_1/ui/reports%20screen/cubit/reports_cubit.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart' as intl;

import '../../data/model/invoice_model.dart';

Future<void> generateInvoiceReport(
    List<Invoice> invoices, ReportsCubit reportsCubit, DateTime? startDate, DateTime? endDate, Set<String> selectedOptions) async {
  
  final pdf = pw.Document();
  final arabicFont1 = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
  final arabicFont2 = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
  final amiriRegular = pw.Font.ttf(arabicFont1);
  final amiriBold = pw.Font.ttf(arabicFont2);

  final formattedDate = intl.DateFormat('dd-MM-yyyy').format(DateTime.now());
  String period = 'من ${intl.DateFormat('dd-MM-yyyy').format(startDate!)} إلى ${intl.DateFormat('dd-MM-yyyy').format(endDate!)}';

  final totalSalesWithoutDiscounts = reportsCubit.calculateTotalSalesForInvoices(invoices);
  final totalCost = reportsCubit.totalCostOfProductsFromInvoices(invoices);
  final totalDiscounts = reportsCubit.calculateTotalDiscountsForInvoices(invoices);
  final totalSalesAfterDiscounts = totalSalesWithoutDiscounts - totalDiscounts;
  final totalProfitWithoutDiscounts = totalSalesWithoutDiscounts - totalCost;
  final achievedProfit = totalSalesAfterDiscounts - totalCost;
  final isLoss = achievedProfit < 0;

  pdf.addPage(
    pw.MultiPage(
      textDirection: pw.TextDirection.rtl,
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Header(
          level: 0,
          child: pw.Text('تقرير الفواتير',
              style: pw.TextStyle(fontSize: 13, font: amiriBold), textAlign: pw.TextAlign.right),
        ),
        pw.Paragraph(
          text: 'أنشئ في $formattedDate\nالفترة: $period',
          style: pw.TextStyle(font: amiriRegular, fontSize: 10),
        ),
        pw.SizedBox(height: 20),
        if (selectedOptions.contains('إجمالي الأرباح'))
          pw.Text('إجمالي الأرباح: ${formattedNumber(achievedProfit)} (د.ع)',
              style: pw.TextStyle(fontSize: 13, font: amiriBold), textAlign: pw.TextAlign.right),
        if (selectedOptions.contains('التكلفة'))
          pw.Text('إجمالي التكلفة: ${formattedNumber(totalCost)} (د.ع)',
              style: pw.TextStyle(fontSize: 13, font: amiriBold), textAlign: pw.TextAlign.right),
        if (selectedOptions.contains('المبيعات'))
          pw.Text('إجمالي المبيعات بدون خصومات: ${formattedNumber(totalSalesWithoutDiscounts)} (د.ع)',
              style: pw.TextStyle(fontSize: 13, font: amiriBold), textAlign: pw.TextAlign.right),
        if (selectedOptions.contains('ملخص التقرير')) 
          _buildSummary(
            totalSalesWithoutDiscounts, 
            totalSalesAfterDiscounts,
            totalCost, 
            totalDiscounts, 
            totalProfitWithoutDiscounts, 
            achievedProfit, 
            isLoss, 
            amiriRegular, 
            amiriBold
          ),
        if (selectedOptions.contains('معلومات العملاء'))
          for(Invoice invoice in invoices) _buildCustomerInfoSection(invoice, amiriBold, amiriRegular),
        if (selectedOptions.contains('تفاصيل الفواتير'))
          for(Invoice invoice in invoices) _buildInvoiceTable(invoice, amiriBold, amiriRegular),
      ],
      footer: (pw.Context context) => pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Divider(),
          pw.Text(
            'نظام مُرونة المحاسبي',
            style: pw.TextStyle(font: amiriBold, fontSize: 8),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    ),
  );

 if (selectedOptions.contains('المبيعات') ||
      selectedOptions.contains('إجمالي الخصومات') ||
      selectedOptions.contains('إجمالي الأرباح')) {
      
    // Group invoices by date
    Map<String, List<Invoice>> groupedInvoices = {};
    for (var invoice in invoices) {
      String invoiceDate = intl.DateFormat('dd-MM-yyyy').format(invoice.date);
      if (!groupedInvoices.containsKey(invoiceDate)) {
        groupedInvoices[invoiceDate] = [];
      }
      groupedInvoices[invoiceDate]!.add(invoice);
    }

    // Prepare the table headers based on selected options
    List<String> tableHeaders = ['التاريخ'];
    if (selectedOptions.contains('المبيعات')) {
      tableHeaders.add('إجمالي المبيعات');
    }
    if (selectedOptions.contains('إجمالي الخصومات')) {
      tableHeaders.add('إجمالي الخصومات');
    }
    if (selectedOptions.contains('إجمالي الأرباح')) {
      tableHeaders.add('إجمالي الأرباح');
    }

    // Prepare the sales data rows
    List<List<String>> salesData = [tableHeaders];
    for (var entry in groupedInvoices.entries) {
      String date = entry.key;
      List<Invoice> dailyInvoices = entry.value;

      double dailyTotalSalesWithoutDiscounts = reportsCubit.calculateTotalSalesForInvoices(dailyInvoices);
      double dailyTotalDiscounts = reportsCubit.calculateTotalDiscountsForInvoices(dailyInvoices);
      double dailyTotalCost = reportsCubit.totalCostOfProductsFromInvoices(dailyInvoices);
      double dailyTotalSalesAfterDiscounts = dailyTotalSalesWithoutDiscounts - dailyTotalDiscounts;
      double dailyAchievedProfit = dailyTotalSalesAfterDiscounts - dailyTotalCost;

      List<String> row = [date];
      if (selectedOptions.contains('المبيعات')) {
        row.add(formattedNumber(dailyTotalSalesAfterDiscounts));
      }
      if (selectedOptions.contains('إجمالي الخصومات')) {
        row.add(formattedNumber(dailyTotalDiscounts));
      }
      if (selectedOptions.contains('إجمالي الأرباح')) {
        row.add(formattedNumber(dailyAchievedProfit));
      }
      salesData.add(row);
    }

    // Add the table to the PDF
    pdf.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 1,
            child: pw.Text('ملخص المبيعات اليومية',
                style: pw.TextStyle(fontSize: 13, font: amiriBold), textAlign: pw.TextAlign.right),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            context: context,
            cellStyle: pw.TextStyle(font: amiriRegular, fontSize: 12),
            headerStyle: pw.TextStyle(font: amiriBold, fontSize: 13),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            headers: salesData.first,  // Header row
            data: salesData.skip(1).toList(),  // Data rows
          ),
        ],
      ),
    );
  }


  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async {
      final pdfBytes = await pdf.save();
      return pdfBytes;
    },
  );
}


pw.Widget _buildInvoiceTable(Invoice invoice, pw.Font amiriRegular, pw.Font amiriBold) {
  final DateTime parsedDate = invoice.date;
  final formattedDate = intl.DateFormat('dd-MM-yyyy').format(parsedDate);
  final formattedTime = intl.DateFormat('hh:mm a').format(parsedDate);

  // Handle large invoices separately by chunking their product details
  final productChunks = _chunkList(invoice.products, 10);

  return pw.Container(
    margin: const pw.EdgeInsets.symmetric(vertical: 10),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('كود الفاتورة: ${invoice.invoiceId.substring(0, 12)}',
            style: pw.TextStyle(font: amiriRegular, fontSize: 10)),
        pw.Text('التاريخ: $formattedDate - $formattedTime',
            style: pw.TextStyle(font: amiriRegular, fontSize: 10)),
        pw.SizedBox(height: 10),
        _buildCustomerInfoSection(invoice, amiriRegular, amiriBold), // Add customer info here
        for (final productChunk in productChunks)
          pw.TableHelper.fromTextArray(
            context: null,
            cellStyle: pw.TextStyle(font: amiriRegular, fontSize: 10),
            headerStyle: pw.TextStyle(font: amiriBold, fontSize: 10),
            data: <List<String>>[
              <String>['المنتج', 'الفئة', 'السعر', 'الحالة', 'الباركود'],
              ...productChunk.map((product) => [
                    product.name!,
                    product.category!,
                    product.salary!,
                    state(product),
                    product.parcode!
                  ]),
            ],
          ),
        pw.SizedBox(height: 10),
        pw.Text('المبلغ الكلي: ${formattedNumber(invoice.totalCoast)} (د.ع)',
            style: pw.TextStyle(font: amiriRegular, fontSize: 10)),
        pw.SizedBox(height: 10),
        pw.Text('الخصم: ${formattedNumber(double.parse(invoice.discount))} (د.ع)',
            style: pw.TextStyle(font: amiriRegular, fontSize: 10)),
        pw.Divider(),
      ],
    ),
  );
}


List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
  List<List<T>> chunks = [];
  for (var i = 0; i < list.length; i += chunkSize) {
    chunks.add(list.sublist(i, i + chunkSize > list.length ? list.length : i + chunkSize));
  }
  return chunks;
}


pw.Widget _buildSummary(
    double totalSalesWithoutDiscounts,
    double totalSalesAfterDiscounts,
    double totalCost,
    double totalDiscounts,
    double totalProfitWithoutDiscounts,
    double achievedProfit,
    bool isLoss,
    pw.Font amiriRegular,
    pw.Font amiriBold) {

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('ملخص التقرير', style: pw.TextStyle(font: amiriBold, fontSize: 12)),
      pw.SizedBox(height: 10),
      _buildSummaryItem('إجمالي المبيعات بدون الخصومات', totalSalesWithoutDiscounts, amiriRegular, false),
      _buildSummaryItem('إجمالي المبيعات بعد الخصومات', totalSalesAfterDiscounts, amiriRegular, false),
      _buildSummaryItem('إجمالي التكلفة', totalCost, amiriRegular, false),
      _buildSummaryItem('إجمالي الخصومات', totalDiscounts, amiriRegular, false),
      _buildSummaryItem('إجمالي الربح بدون خصومات', totalProfitWithoutDiscounts, amiriRegular, false),
      isLoss 
          ? _buildSummaryItem('إجمالي الخسارة', achievedProfit.abs(), amiriRegular, true)
          : _buildSummaryItem('إجمالي الربح بعد الخصومات', achievedProfit, amiriRegular, false),
      pw.Divider(),
    ],
  );
}

pw.Widget _buildSummaryItem(String title, double value, pw.Font font, bool isNegative) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(title, style: pw.TextStyle(font: font, fontSize: 10, color: isNegative ? PdfColors.red : PdfColors.black)),
      pw.Text('${formattedNumber(value)} د.ع', 
              style: pw.TextStyle(font: font, fontSize: 10, color: isNegative ? PdfColors.red : PdfColors.black)),
    ],
  );
}

pw.Widget _buildCustomerInfoSection(Invoice invoice, pw.Font amiriRegular, pw.Font amiriBold) {
  return pw.Container(
    margin: const pw.EdgeInsets.symmetric(vertical: 10),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('معلومات العميل الخاصة بالفاتورة: ${invoice.invoiceId.substring(0,12)}', style: pw.TextStyle(font: amiriBold, fontSize: 12)),
        pw.SizedBox(height: 10),
        _buildCustomerInfoItem('اسم العميل', invoice.clientModel!.clientName, amiriRegular),
        _buildCustomerInfoItem('رقم الهاتف', invoice.clientModel!.clientPhone, amiriRegular),
        _buildCustomerInfoItem('عنوان العميل', invoice.clientModel!.cleintAddress, amiriRegular),
        pw.Divider(),
      ],
    ),
  );
}

pw.Widget _buildCustomerInfoItem(String title, String value, pw.Font font) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(title, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.black)),
      pw.Text(value, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.black)),
    ],
  );
}



String state(Product product) {
  if (product.isRefunded) {
    return 'مسترجع';
  } else if (product.isReplaced) {
    return 'مستبدل';
  } else if (product.isReplacedDone) {
    return 'بديل';
  }
  return 'بيع';
}
