import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/model/invoice_model.dart';
import '../../data/model/operation_model.dart';
import '../../data/model/product_model.dart';
import '../../domain/utils.dart';

Future<String> generateComprehensiveBackupPDF(List<Invoice> invoices, List<Operation> operations, List<Product> products) async {
  final pdf = pw.Document();

  // Load the Amiri fonts for Arabic support
  final arabicFont1 = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
  final arabicFont2 = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
  final amiriRegular = pw.Font.ttf(arabicFont1);
  final amiriBold = pw.Font.ttf(arabicFont2);

  // Retrieve the installation date
  final prefs = await SharedPreferences.getInstance();
  String? installationDateStr = prefs.getString('installationDate');
  DateTime installationDate = installationDateStr != null
      ? DateTime.parse(installationDateStr)
      : DateTime.now();

  // Get the current date
  final now = DateTime.now();

  // Format the dates
  final formattedInstallationDate = DateFormat('yyyy-MM-dd').format(installationDate);
  final formattedCurrentDate = DateFormat('yyyy-MM-dd').format(now);

  // Create the file name with the date range
  final String fileName = 'نسخ_احتياطي_من_${formattedInstallationDate}_الي_$formattedCurrentDate.pdf';

  // Generate invoices section
  final invoiceChunks = _chunkList(invoices, 2);
  for (final invoiceChunk in invoiceChunks) {
    pdf.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Center(child:pw.Text('تقارير شاملة للفواتير من $formattedInstallationDate الي $formattedCurrentDate', style: pw.TextStyle(font: amiriBold, fontSize: 20)))),
          pw.SizedBox(height: 20),
          _buildInvoiceSummarySection(invoiceChunk, amiriRegular, amiriBold),
          ...invoiceChunk.map((invoice) => _buildInvoiceTable(invoice, amiriRegular, amiriBold)),
          pw.Spacer(),
                pw.Divider(),
            pw.Center(
              child: pw.Text(
                'نظام مُرونة المحاسبي',
                style: pw.TextStyle(font: amiriBold, fontSize: 8),
              ),
            ),
        ],
      ),
    );
  }

  // Generate operations section
  final operationChunks = _chunkList(operations, 1);
  for (final operationChunk in operationChunks) {
    pdf.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Center(child: pw.Text('تقارير شاملة للعمليات  من $formattedInstallationDate الي $formattedCurrentDate', style: pw.TextStyle(font: amiriBold, fontSize: 20)))),
          _buildOperationsSections(operationChunk, amiriRegular, amiriBold),
          pw.Spacer(),
                pw.Divider(),
            pw.Center(
              child: pw.Text(
                'نظام مُرونة المحاسبي',
                style: pw.TextStyle(font: amiriBold, fontSize: 8),
              ),
            ),
        ],
      ),
    );
  }

  // Generate products section
  final productChunks = _chunkList(products, 10);
  for (final productChunk in productChunks) {
    pdf.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Center(child: pw.Text('تقارير شاملة للمنتجات من $formattedInstallationDate الي $formattedCurrentDate', style: pw.TextStyle(font: amiriBold, fontSize: 20)))),
          _buildProductsSection(productChunk, amiriRegular, amiriBold),
          pw.Spacer(),
                pw.Divider(),
            pw.Center(
              child: pw.Text(
                'نظام مُرونة المحاسبي',
                style: pw.TextStyle(font: amiriBold, fontSize: 8),
              ),
            ),
        ],
      ),
    );
  }

  // Request storage permission and save the PDF
  PermissionStatus status = await Permission.storage.request();
  if (status.isGranted) {
    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory != null) {
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      return file.path;
    } else {
      throw Exception('Could not access the Downloads directory');
    }
  } else {
    throw Exception('Storage permission denied');
  }
}


pw.Widget _buildInvoiceSummarySection(List<Invoice> invoices, pw.Font amiriRegular, pw.Font amiriBold) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('ملخص تقارير الفواتير', style: pw.TextStyle(font: amiriBold, fontSize: 18)),
      pw.Divider(),
    ],
  );
}

pw.Widget _buildInvoiceTable(Invoice invoice, pw.Font amiriRegular, pw.Font amiriBold) {
  final DateTime parsedDate = invoice.date;
  final formattedDate = DateFormat('yyyy/MM/dd').format(parsedDate);
  final formattedTime = DateFormat('hh:mm a').format(parsedDate);

  final productChunks = _chunkList(invoice.products, 2);

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
        for (final productChunk in productChunks) ...[
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
        ],
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

pw.Widget _buildProductsSection(List<Product> products, pw.Font amiriRegular, pw.Font amiriBold) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('ملخص تقارير المنتجات', style: pw.TextStyle(font: amiriBold, fontSize: 18)),
      pw.SizedBox(height: 10),
      pw.Text('إجمالي المنتجات: ${products.length}', style: pw.TextStyle(font: amiriRegular, fontSize: 12)),
      pw.SizedBox(height: 10),
      pw.TableHelper.fromTextArray(
        context: null,
        cellStyle: pw.TextStyle(font: amiriRegular, fontSize: 10),
        headerStyle: pw.TextStyle(font: amiriBold, fontSize: 10),
        headers: <String>['المنتج', 'الفئة', 'الباركود', 'السعر', 'الكمية'],
        data: products.map((product) => [
          product.name ?? '-',
          product.category ?? '-',
          product.parcode ?? '-',
          product.salary ?? '-',
          product.quantity ?? '-',
        ]).toList(),
      ),
    ],
  );
}


pw.Widget _buildOperationsSections(List<Operation> operations, pw.Font amiriRegular, pw.Font amiriBold) {
  List<pw.Widget> widgets = [];

  for (var operation in operations) {
    widgets.add(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('النوع: ${operation.type}', style: pw.TextStyle(font: amiriRegular, fontSize: 8)),
          pw.Text('الوصف: ${operation.description}', style: pw.TextStyle(font: amiriRegular, fontSize: 3)),
          pw.Text('التاريخ: ${DateFormat('yyyy/MM/dd').format(operation.date)}', style: pw.TextStyle(font: amiriRegular, fontSize: 8)),
          pw.Divider(),
        ],
      ),
    );

    if (operation.description.length > 2000) {
      widgets.add(pw.NewPage());
    }
  }

  return pw.Column(children: widgets);
}

List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
  List<List<T>> chunks = [];
  for (var i = 0; i < list.length; i += chunkSize) {
    chunks.add(list.sublist(i, i + chunkSize > list.length ? list.length : i + chunkSize));
  }
  return chunks;
}

String state(Product product) {
  if (product.isRefunded) {
    return 'مسترجع';
  } else if (product.isReplaced) {
    return 'مستبدل';
  } else if (product.isReplacedDone) {
    return 'بديل';
  }
  return '-';
}
