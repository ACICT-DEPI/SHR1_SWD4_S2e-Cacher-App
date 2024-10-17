
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/data/model/invoice_model.dart';
import 'package:intl/intl.dart' as intl;

import '../reports screen/cubit/reports_cubit.dart';
import '../widgets/custom_dialogs.dart';
import '../widgets/invoice_card.dart';
import 'cubit/invoice_details_cubit.dart';
import 'cubit/invoice_details_state.dart'; // Import the states

class InvoiceDetailScreen extends StatelessWidget {
  final String clientId;

  const InvoiceDetailScreen({required this.clientId, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
      create: (_) => InvoiceDetailCubit()..fetchInvoices(clientId),),
      BlocProvider(create: (_) => ReportsCubit()..getManagerData()),
      ],
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('الفواتير الخاصة بالعميل',
                style: TextStyle(color: Colors.white, fontFamily: 'font1')),
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
            centerTitle: true,
          ),
          body: BlocConsumer<InvoiceDetailCubit, InvoiceDetailState>(
            listener: (context, state) {
              if (state is InvoiceDetailError) {
                showErrorDialog(context, state.error);
              } else if (state is ProductReturnSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إرجاع المنتج بنجاح')),
                );
              }
            },
            builder: (context, state) {
              if (state is InvoiceDetailLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is InvoiceDetailError) {
                return Center(child: Text('Error: ${state.error}'));
              } else if (state is InvoiceDetailLoaded) {
                List<Invoice> invoices = state.invoices;

                if (invoices.isEmpty) {
                  return const Center(child: Text('No invoices found'));
                }

                return ListView(
                  children: [
                    ...invoices.map((invoice) => showInvoiceCard(
                          invoice,
                          intl.DateFormat('yyyy/MM/dd').format(invoice.date),
                          intl.DateFormat('hh:mm a').format(invoice.date),
                          invoice.products.any((product) => product.isRefunded),
                          invoice.products.any((product) => product.isReplaced),
                          invoice.products
                              .any((product) => product.isReplacedDone),
                          context,
                          context.read<ReportsCubit>(),
                        )),
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