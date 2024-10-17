import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/model/invoice_model.dart';
import 'package:flutter_application_1/ui/bill%20screen/cubit/invoice_cubit.dart';
import 'package:flutter_application_1/ui/reports%20screen/InvoiceDetailsScreen.dart';
import 'package:flutter_application_1/ui/reports%20screen/cubit/reports_cubit.dart';
import 'package:flutter_application_1/ui/reports%20screen/cubit/reports_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;

import '../../data/model/operation_model.dart';

class OperationsScreen extends StatelessWidget {
  const OperationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ReportsCubit()..fetchOperations(),
        ),
        BlocProvider(create: (_) => InvoiceCubit())
      ],
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
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
            title: const Text('العمليات',
                style: TextStyle(color: Colors.white, fontFamily: 'font1')),
          ),
          body: BlocBuilder<ReportsCubit, ReportsStates>(
            builder: (context, state) {
              if (state is ReportsLoadingState) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ReportsSuccessState) {
                ReportsCubit reportsCubit = context.read<ReportsCubit>();
                List<Operation> filteredOperations =
                    reportsCubit.getFilteredOperations();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DropdownButtonFormField<String>(
                        value: reportsCubit.filterOption,
                        hint: const Text('اختر الفترة الزمنية'),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
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
                    filteredOperations.isEmpty
                        ? Expanded(
                            child: Center(
                              child:
                                  Image.asset('assets/images/no_products.gif'),
                            ),
                          )
                        : Expanded(
                            child: ListView.builder(
                              itemCount: filteredOperations.length,
                              itemBuilder: (context, index) {
                                final operation = filteredOperations[index];
                                final formattedDate =
                                    intl.DateFormat('yyyy/MM/dd')
                                        .format(operation.date);
                                final formattedTime = intl.DateFormat('hh:mm a')
                                    .format(operation.date);

                                return InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Directionality(
                                          textDirection: TextDirection.rtl,
                                          child: AlertDialog(
                                            title: const Text('معلومات إضافية'),
                                            content: SingleChildScrollView(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                      'نوع العملية: ${operation.type}',
                                                      style: const TextStyle(
                                                          fontSize: 18)),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                      'تفاصيل العملية:\n${operation.description}',
                                                      style: const TextStyle(
                                                          fontSize: 18)),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                      'التاريخ: $formattedDate',
                                                      style: const TextStyle(
                                                          fontSize: 18)),
                                                  const SizedBox(height: 8),
                                                  Text('الوقت: $formattedTime',
                                                      style: const TextStyle(
                                                          fontSize: 18)),
                                                  const SizedBox(height: 16),
                                                  if (operation.type
                                                      .contains('استبدال')) ...[
                                                    ElevatedButton(
                                                      onPressed: () async {
                                                        Invoice? invoice =
                                                            await reportsCubit
                                                                .getInvoiceById(
                                                                    operation
                                                                        .oldInvoice!);
                                                            Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (_) =>
                                                                  InvoiceDetailsScreen(
                                                                invoice:
                                                                    invoice!,
                                                                reportsCubit:
                                                                    reportsCubit,
                                                              ),
                                                            ),
                                                          );
                                                      },
                                                      child: const Text(
                                                          'الذهاب للفاتورة التي تحتوي علي المنتج المستبدل'),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                child: const Text('تم'),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.all(8.0),
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border:
                                          Border.all(color: Colors.blueAccent),
                                      borderRadius: BorderRadius.circular(8.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.5),
                                          spreadRadius: 1,
                                          blurRadius: 3,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      title: Text(operation.type,
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold)),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text('التاريخ: $formattedDate',
                                              style: const TextStyle(
                                                  fontSize: 16)),
                                          Text('الوقت: $formattedTime',
                                              style: const TextStyle(
                                                  fontSize: 16)),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ],
                );
              } else if (state is ReportsErrorState) {
                return Center(child: Text('Error: ${state.error}'));
              } else {
                return const Center(child: Text('No operations found.'));
              }
            },
          ),
        ),
      ),
    );
  }
}
