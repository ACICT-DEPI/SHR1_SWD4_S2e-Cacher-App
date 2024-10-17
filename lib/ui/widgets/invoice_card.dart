import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/model/invoice_model.dart';
import 'package:flutter_application_1/ui/reports%20screen/cubit/reports_cubit.dart';

import '../../domain/utils.dart';
import '../reports screen/InvoiceDetailsScreen.dart';

Card showInvoiceCard(
    Invoice invoice,
    String formattedDate,
    String formattedTime,
    bool hasRefundedProduct,
    bool hasExchangedProduct,
    bool hasReplacedDoneProduct,
    BuildContext context,
    ReportsCubit reportsCubit) {
  return Card(
    margin: const EdgeInsets.all(10),
    color: cardBackgroundColor, // Consistent card background color
    child: Column(
      children: [
        ListTile(
          title: Text(
            'المبلغ الكلي: ${formattedNumber(invoice.totalCoast)} د.ع',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textColor, // Consistent text color
            ),
          ),
          subtitle: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'التاريخ: $formattedDate',
                style: const TextStyle(
                  fontSize: 13,
                  color: textColor, // Consistent text color
                ),
              ),
              Text(
                'الوقت: $formattedTime',
                style: const TextStyle(
                  fontSize: 13,
                  color: textColor, // Consistent text color
                ),
              ),
              if (hasRefundedProduct && !hasExchangedProduct)
                const Text(
                  'تحتوي علي منتج مسترجع',
                  style: TextStyle(fontSize: 13, color: refundedProductColor), // Refunded product color
                ),
              if (hasExchangedProduct && !hasRefundedProduct)
                const Text(
                  'تحتوي علي منتج مستبدل',
                  style: TextStyle(fontSize: 13, color: exchangedProductColor), // Exchanged product color
                ),
              if (hasRefundedProduct && hasExchangedProduct)
                const Text(
                  'تحتوي علي منتج مستبدل ومسترجع',
                  style: TextStyle(fontSize: 13, color: refundedProductColor), // Refunded product color
                ),
              if (hasReplacedDoneProduct)
                const Text(
                  'تحتوي علي منتج بديل',
                  style: TextStyle(fontSize: 13, color: refundedProductColor), // Replaced product color
                ),
            ],
          ),
          leading: const Icon(
            Icons.receipt,
            color: receiptIconColor, // Consistent icon color
          ),
          trailing: SelectableText(
            'كود الفاتورة\n${invoice.invoiceId.substring(0, 12)}',
            style: const TextStyle(fontSize: 13, color: invoiceIdColor), // Invoice ID text color
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InvoiceDetailsScreen(
                  invoice: invoice,
                  reportsCubit: reportsCubit,
                ),
              ),
            );
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                reportsCubit.generateAndSaveBDF(
                    context,
                    invoice,
                    invoice.products,
                    reportsCubit.manager!,
                    invoice.paymentMethod,
                    false,
                    false);
              },
              child: const Text(
                'حفظ',
                style: TextStyle(color: buttonTextColor), // Consistent button text color
              ),
            ),
            TextButton(
              onPressed: () {
                log('$invoice');
                log('${invoice.products}');
                reportsCubit.generateAndprintBDF(invoice, invoice.products,
                    reportsCubit.manager!, invoice.paymentMethod, false, false);
              },
              child: const Text(
                'طباعة',
                style: TextStyle(color: buttonTextColor), // Consistent button text color
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
