import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/data/model/invoice_model.dart';
import 'package:flutter_application_1/ui/reports%20screen/cubit/reports_cubit.dart';
import 'package:flutter_application_1/ui/reports%20screen/cubit/reports_states.dart';

import '../../domain/utils.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  void showRestoreDialog(
      BuildContext context, Invoice invoice, ReportsCubit reportsCubit) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('استعادة الفاتورة'),
            content: const Text('هل ترغب في استعادة هذه الفاتورة؟'),
            actions: [
              TextButton(
                onPressed: () async {
                  await reportsCubit.restoreInvoice(invoice.invoiceId);
                  Navigator.of(context).pop();
                },
                child: const Text('نعم'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('لا'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سلة المهملات',
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
          backgroundColor: const Color(0xff4e00e8),
        ),
        body: BlocProvider(
          create: (context) => ReportsCubit()..getTrashInvoices(),
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
              } else if (state is ReportsTrashState) {
                List<Invoice> trashInvoices = state.invoices;
                List<Invoice> oldInvoices =
                    state.oldInvoices; // Invoices older than 30 days

                if (trashInvoices.isEmpty) {
                  return const Center(
                    child: Text('لا توجد فواتير في سلة المهملات'),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: trashInvoices.length,
                        itemBuilder: (context, index) {
                          final invoice = trashInvoices[index];
                          final trashDate = invoice.trashDate!;
                          final remainingDays =
                              DateTime.now().difference(trashDate).inDays;

                          return Card(
                            margin: const EdgeInsets.all(10),
                            child: ListTile(
                              title: Text(
                                  'المبلغ الكلي: ${formattedNumber(invoice.totalCoast)} د.ع'),
                              subtitle: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'اسم العميل: ${invoice.clientModel!.clientName}'),
                                  Text('محذوف منذ: $remainingDays يوم'),
                                ],
                              ),
                              trailing: SelectableText(
                                'كود الفاتورة\n${invoice.invoiceId.substring(0, 12)}',
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.grey),
                              ),
                              onTap: () {
                                showRestoreDialog(context, invoice,
                                    context.read<ReportsCubit>());
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    if (oldInvoices
                        .isNotEmpty) // Conditionally show button if there are old invoices
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff4e00e8),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              // Call the method to delete invoices older than 30 days
                              context
                                  .read<ReportsCubit>()
                                  .deleteOldTrashInvoices()
                                  .then((_) {
                                Navigator.pop(context);
                              });

                              // Show a confirmation message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'تم حذف الفواتير التي تجاوزت 30 يوماً بنجاح')),
                              );
                            },
                            child: const Text(
                              'حذف الفواتير التي تجاوزت 30 يوماً',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              } else {
                return const Center(child: Text('Unknown state'));
              }
            },
          ),
        ),
      ),
    );
  }
}
