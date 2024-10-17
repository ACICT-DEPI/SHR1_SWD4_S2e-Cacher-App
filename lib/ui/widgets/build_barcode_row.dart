import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:simple_barcode_scanner/enum.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:barcode/barcode.dart';
import '../categories screen/cubit/product_cubit.dart';

Widget buildBarcodeRow(BuildContext context, ProductCubit productCubit) {
  return Padding(
    padding: const EdgeInsets.all(10.0),
    child: Container(
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            style: ButtonStyle(
              fixedSize: WidgetStateProperty.all(const Size(80, 40)),
              backgroundColor: WidgetStateProperty.all<Color>(
                const Color.fromARGB(255, 25, 28, 235),
              ),
            ),
            onPressed: () {
              final random = Random();
              final barcode = Barcode.ean13();
              final digits =
                  List.generate(barcode.minLength - 1, (_) => random.nextInt(10));
              final checksumDigit = calculateChecksumDigit(digits);
              final randomBarcode = digits.join() + checksumDigit.toString();
              productCubit.parcode.text = randomBarcode;
            },
            child: const Text(
              'توليد',
              style: TextStyle(color: Colors.white, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 5),
          ElevatedButton(
            style: ButtonStyle(
              fixedSize: WidgetStateProperty.all(const Size(80, 40)),
              backgroundColor: WidgetStateProperty.all<Color>(
                const Color.fromARGB(255, 25, 28, 235),
              ),
            ),
            onPressed: () async {
              var result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SimpleBarcodeScannerPage(
                    scanType: ScanType.barcode,
                    isShowFlashIcon: true,
                  ),
                ),
              );
              if (result != null && result is String) {
                productCubit.parcode.text = result;
              }
            },
            child: const Text(
              'scan',
              style: TextStyle(color: Colors.white, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: FormBuilderTextField(
              controller: productCubit.parcode,
              name: 'barcode',
              decoration: const InputDecoration(
                labelText: 'الباركود',
              ),
              keyboardType: TextInputType.number,
              validator: FormBuilderValidators.required(),
            ),
          ),
        ],
      ),
    ),
  );
}

String calculateChecksumDigit(List<int> digits) {
  final sum = digits.asMap().entries.fold(0, (prev, entry) {
    final index = entry.key;
    final digit = entry.value;
    final multiplier = (index % 2 == 0) ? 1 : 3;
    return prev + digit * multiplier;
  });

  final checksumDigit = (10 - (sum % 10)) % 10;
  return checksumDigit.toString();
}