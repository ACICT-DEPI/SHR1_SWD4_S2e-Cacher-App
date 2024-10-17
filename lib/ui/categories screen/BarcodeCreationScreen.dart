import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/domain/utils.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/model/product_model.dart';

class BarcodeCreationScreen extends StatelessWidget {
  final Product product;

  const BarcodeCreationScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final TextEditingController nameController = TextEditingController(text: product.name);
    final TextEditingController barcodeController = TextEditingController(text: product.parcode);
    final TextEditingController priceController = TextEditingController(text: product.salary);
    final TextEditingController quantityController = TextEditingController(text: product.quantity);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'إنشاء باركود',
            style: TextStyle(
                  color: Colors.white, fontSize: 28, fontFamily: 'font1'),
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تفاصيل المنتج',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildTextField(nameController, 'اسم المنتج', enabled: true),
              const SizedBox(height: 16),
              _buildTextField(barcodeController, 'الباركود', enabled: false),
              const SizedBox(height: 16),
              _buildTextField(priceController, 'السعر', enabled: false),
              const SizedBox(height: 16),
              _buildTextField(quantityController, 'العدد للطباعة', keyboardType: TextInputType.number),
              const SizedBox(height: 30),
              Center(
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
                      _showInfoSelectionDialog(context, (selectedOptions) {
                        int quantity = int.tryParse(quantityController.text) ?? 1;
                        generateBarcodePDF(
                          nameController.text,
                          barcodeController.text,
                          priceController.text,
                          quantity,
                          selectedOptions,
                        );
                      });
                    },
                    child: const Text(
                      'إنشاء PDF',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText, {bool enabled = true, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(fontSize: 16, color: Colors.blueGrey),
        contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.blueGrey, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.grey, width: 1.5),
        ),
      ),
      style: TextStyle(fontSize: 16, color: enabled ? Colors.black : Colors.grey.shade600),
    );
  }
}

void generateBarcodePDF(String name, String barcode, String price, int quantity, Set<String> selectedOptions) async{
  final pdf = pw.Document();
  final arabicFont1 = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
    final arabicFont2 = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
    final amiriRegular = pw.Font.ttf(arabicFont1);
    final amiriBold = pw.Font.ttf(arabicFont2);
  for (int i = 0; i < quantity; i++) {
    pdf.addPage(
      pw.Page(
        textDirection: pw.TextDirection.rtl,
        pageFormat: const PdfPageFormat(100 * PdfPageFormat.mm, 50 * PdfPageFormat.mm),
        build: (pw.Context context) => pw.Center(
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (selectedOptions.contains('name'))
                pw.Text(name, style: pw.TextStyle(fontSize: 12,font: amiriBold)),
              if (selectedOptions.contains('price'))
                pw.Text('السعر: ${formattedNumber(double.parse(price))} د.ع', style: pw.TextStyle(fontSize: 10,font: amiriRegular)),
              if (selectedOptions.contains('barcode'))
                pw.BarcodeWidget(
                textPadding: 5,
                  data: barcode,
                  padding: const pw.EdgeInsets.only(top: 8),
                  barcode: pw.Barcode.code128(),
                  width: 80,
                  height: 40,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
}




Future<void> _showInfoSelectionDialog(
    BuildContext context,
    Function(Set<String>) onSelectionDone,
  ) async {
  final Set<String> selectedOptions = {};

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('اختر المعلومات التي تريد عرضها',style: TextStyle(fontSize: 20),),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: const Text('اسم المنتج'),
                    value: selectedOptions.contains('name'),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedOptions.add('name');
                        } else {
                          selectedOptions.remove('name');
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('الباركود'),
                    value: selectedOptions.contains('barcode'),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedOptions.add('barcode');
                        } else {
                          selectedOptions.remove('barcode');
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('السعر'),
                    value: selectedOptions.contains('price'),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedOptions.add('price');
                        } else {
                          selectedOptions.remove('price');
                        }
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    onSelectionDone(selectedOptions);
                    Navigator.of(context).pop();
                  },
                  child: const Text('تأكيد'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
