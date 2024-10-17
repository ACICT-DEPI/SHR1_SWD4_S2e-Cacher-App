import 'dart:developer';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:barcode/barcode.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/model/invoice_model.dart';
import '../../data/model/manager_model.dart';
import '../../data/model/product_model.dart';
import '../../domain/utils.dart';

Future<void> generatePdf(
  Invoice? invoice,
  List<Product> productsAdded,
  ManagerModel? manager,
  String payMethod,
  bool offline,
) async {
  print('Entering generatePdf function');

  final pdf = pw.Document();
  const double textSize = 12.0;

  try {
    final arabicFont1 = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
    final arabicFont2 = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
    final amiriRegular = pw.Font.ttf(arabicFont1);
    final amiriBold = pw.Font.ttf(arabicFont2);

    print('Fonts loaded successfully');

    // Fetch custom thank you message from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String thankYouMessage = prefs.getString('thankYouMessage') ??
        'شكراً لزيارتكم ونتمني تكرار الزيارة مرة أخري';

    // Determine the logo to use: Firebase image if online, fallback to asset image if offline
    Uint8List? logoData;

    if (!offline) {
      try {
        final http.Response response =
            await http.get(Uri.parse(manager!.logoPath!));
        if (response.statusCode == 200) {
          logoData = response.bodyBytes;
        } else {
          throw Exception('Failed to load image from the internet');
        }
      } catch (e) {
        print('Error fetching Firebase logo, using fallback: $e');
      }
    }

    if (logoData == null) {
      final imageData = await rootBundle.load('assets/images/logo.png');
      logoData = imageData.buffer.asUint8List();
    }

    final image = pw.MemoryImage(logoData);

    final DateTime parsedDate = invoice!.date;
    final String formattedDate =
        intl.DateFormat('yyyy/MM/dd').format(parsedDate);
    final String formattedTime = intl.DateFormat('hh:mm a').format(parsedDate);
    print('Date fetched successfully');

    // Convert invoice ID to a decimal format
    final String invoiceBarcode = invoice.invoiceId;
    final double decimalBarcode =
        double.parse(invoiceBarcode.hashCode.toString());

    // Generate the barcode
    final barcode = Barcode.code128();
    final svgBarcode = barcode.toSvg('$decimalBarcode', width: 300, height: 80);

    // Chunk the products list to ensure pagination
    final productChunks =
        _chunkList(productsAdded, 15); // Adjust chunk size as needed

    String formatSalary(double salary) {
      return '${formattedNumber(salary)} د.ع';
    }

    // Create pages for each chunk
    for (int i = 0; i < productChunks.length; i++) {
      pdf.addPage(
        pw.Page(
          textDirection: pw.TextDirection.rtl,
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (i == 0) // Only include the header on the first page
                pw.Column(
  children: [
    // Centered Shop name and logo
    pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center, // Center both horizontally
      crossAxisAlignment: pw.CrossAxisAlignment.center, // Align children in the center
      children: [
        if (offline == false)
          pw.ClipRRect(
            horizontalRadius: 10,
            verticalRadius: 10,
            child: pw.Image(
              image,
              fit: pw.BoxFit.cover,
              width: 80,
              height: 80,
            ),
          ),
        pw.SizedBox(height: 10), // Add some space between image and text
        pw.Text(
          manager?.name ?? 'اسم المحل غير متوفر',
          style: pw.TextStyle(font: amiriBold, fontSize: 18),
        ),
      ],
    ),
    pw.Divider(),
    pw.SizedBox(height: 10),
    // Barcode section
    pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'الاسم : ${invoice.clientModel!.clientName.isEmpty ? 'بلا اسم' : invoice.clientModel?.clientName ?? 'بلا اسم'}',
          style: pw.TextStyle(font: amiriRegular, fontSize: textSize),
        ),
        pw.Text(
          'الهاتف : ${invoice.clientModel!.clientPhone.isEmpty ? 'بلا هاتف' : invoice.clientModel?.clientPhone ?? 'بلا هاتف'}',
          style: pw.TextStyle(font: amiriRegular, fontSize: textSize),
        ),
        pw.Text(
          'العنوان : ${invoice.clientModel!.cleintAddress.isEmpty ? 'بلا عنوان' : invoice.clientModel?.cleintAddress ?? 'بلا عنوان'}',
          style: pw.TextStyle(font: amiriRegular, fontSize: textSize),
        ),
      ],
    ),
  ],
),
              pw.SizedBox(height: 16),
              // Invoice product table for the current chunk
              pw.TableHelper.fromTextArray(
                context: context,
                cellStyle: pw.TextStyle(font: amiriRegular, fontSize: textSize),
                headerStyle: pw.TextStyle(font: amiriBold, fontSize: textSize),
                cellAlignment: pw.Alignment.center,
                headerAlignment: pw.Alignment.center,
                headers: ['الباركود', 'السعر', 'المنتج', 'الحالة'],
                data: productChunks[i]
                    .map((entry) => [
                          entry.parcode ?? 'no barcode',
                          formatSalary(double.parse(entry.salary!)),
                          entry.name ?? 'no name',
                          state(entry)
                        ])
                    .toList(),
              ),
              pw.SizedBox(height: 16),
              if (i ==
                  productChunks.length -
                      1) // Only include totals on the last page
                pw.Column(
                  children: [
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'الاجمالي : ${formattedNumber(totalCost(productsAdded.where((product) {
                            return product.isRefunded == false && product.isReplaced == false;
                          }).toList()))} د.ع',
                          style:
                              pw.TextStyle(font: amiriBold, fontSize: textSize),
                        ),
                        pw.Text(
                          'الخصم : ${formattedNumber(double.parse(invoice.discount))} د.ع',
                          style:
                              pw.TextStyle(font: amiriBold, fontSize: textSize),
                        ),
                        pw.Text(
                          'الصافي : ${formattedNumber(invoice.totalCoast)} د.ع',
                          style:
                              pw.TextStyle(font: amiriBold, fontSize: textSize),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 16),
                  ],
                ),
              pw.Spacer(),
              pw.Center(
                child: pw.SvgImage(svg: svgBarcode),
              ),
              pw.SizedBox(height: 16),
              // Custom thank you message
              pw.Center(
                child: pw.Text(
                  thankYouMessage,
                  style: pw.TextStyle(font: amiriBold, fontSize: textSize),
                ),
              ),
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  'نظام مُرونة المحاسبي',
                  style: pw.TextStyle(font: amiriBold, fontSize: 8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    print('PDF content added successfully');

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        print('PDF layout started');
        final pdfBytes = await pdf.save();
        print('PDF layout completed');
        return pdfBytes;
      },
    );

    print('PDF printing completed');
  } catch (e) {
    print('Error in generatePdf: $e');
  }
}

List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
  List<List<T>> chunks = [];
  for (var i = 0; i < list.length; i += chunkSize) {
    chunks.add(list.sublist(
        i, i + chunkSize > list.length ? list.length : i + chunkSize));
  }
  return chunks;
}

double totalCost(List<Product> productsAdded) {
  double total = 0;
  for (var product in productsAdded) {
    total += double.parse(product.salary!);
  }
  return total;
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
