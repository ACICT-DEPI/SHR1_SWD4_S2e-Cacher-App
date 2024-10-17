import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/ui/bill%20screen/bill_tab.dart';
import 'package:flutter_application_1/ui/categories%20screen/categories_tab.dart';
import 'package:flutter_application_1/ui/home%20screen/home_tab.dart';
import 'package:flutter_application_1/ui/profile%20screen/profile_tab.dart';
import 'package:flutter_application_1/ui/reports%20screen/reports_tab.dart';
import 'package:flutter_application_1/ui/settings%20screen/settings_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../main.dart';
import '../bill screen/cubit/invoice_cubit.dart';
import '../categories screen/add_product_screen.dart';
import '../reports screen/cubit/reports_cubit.dart';
import '../widgets/bacup_pdf.dart';
import 'cubit/nav bar cubit/nav_bar_cubit.dart';

void scheduleDailyBackup(BuildContext context) {
  Future.delayed(Duration.zero, () {
    log('in scheduleDailyBackup future.delay');
    Timer.periodic(const Duration(hours: 24), (Timer timer) async {
      log('in periodic');
      try {
        final invoiceCubit = context.read<InvoiceCubit>();
        final reportsCubit = context.read<ReportsCubit>();

        final invoices = await invoiceCubit.getInvoicesSinceInstallation();
        final operations = await reportsCubit.getOperationsSinceInstallation();
        final products = await invoiceCubit.getAllProductsSinceInstallation();

        if (invoices.isNotEmpty ||
            operations.isNotEmpty ||
            products.isNotEmpty) {
          final backupPath = await generateComprehensiveBackupPDF(
              invoices, operations, products);

          if (backupPath != null) {
            // Notify the user using a system notification
            _showBackupCompletedNotification(backupPath);
          }
        }
      } catch (e) {
        log('Error during backup: $e');
      }
    });
  });
}

void _showBackupCompletedNotification(String backupPath) {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails('channel_id', 'Backup Notifications',
          channelDescription: 'Channel for backup completion notifications',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker');

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  flutterLocalNotificationsPlugin.show(0, 'تم عمل نسخ احتياطي يومي',
      'Backup completed successfully at $backupPath', platformChannelSpecifics,
      payload: backupPath);
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      log('Scheduling daily backup');
      scheduleDailyBackup(context);
    });
    return BlocProvider(
      create: (_) => NavBarCubit(),
      child: BlocBuilder<NavBarCubit, int>(
        builder: (context, state) {
          final cubit = context.read<NavBarCubit>();

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                actions: [
                  IconButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_)=> SettingsScreen()));
                      },
                      icon: const Icon(
                        Icons.settings,
                        color: Colors.white,
                      )),
                ],
                backgroundColor: const Color(0xff4e00e8),
                centerTitle: true,
                title: state == 0
                    ? const Text(
                        'الصفحة الرئيسية',
                        style:
                            TextStyle(color: Colors.white, fontFamily: 'font1'),
                      )
                    : state == 1
                        ? const Text("إدارة المنتجات",
                            style: TextStyle(
                                color: Colors.white, fontFamily: 'font1'))
                        : state == 2
                            ? const Text("إدارة الفواتير",
                                style: TextStyle(
                                    color: Colors.white, fontFamily: 'font1'))
                            : state == 3
                                ? const Text(
                                    "التقارير",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'font1'),
                                  )
                                : const Text(
                                    "حسابي",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'font1'),
                                  ),
              ),
              body: _getBody(state),
              bottomNavigationBar: CurvedNavigationBar(
                backgroundColor: Colors.white,
                color: const Color(0xff4e00e8),
                index: state,
                items: const <Widget>[
                  Icon(
                    Icons.home,
                    size: 30,
                    color: Colors.white,
                  ),
                  Icon(
                    Icons.category,
                    size: 30,
                    color: Colors.white,
                  ),
                  Icon(
                    Icons.receipt,
                    size: 30,
                    color: Colors.white,
                  ),
                  Icon(
                    Icons.bar_chart,
                    size: 30,
                    color: Colors.white,
                  ),
                  Icon(
                    Icons.person,
                    size: 30,
                    color: Colors.white,
                  ),
                ],
                onTap: (index) {
                  cubit.updateIndex(index);
                },
              ),
              floatingActionButton: state == 1
                  ? FloatingActionButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProductFormScreen(),
                          ),
                        );
                      },
                      backgroundColor: const Color(0xff4e00e8),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _getBody(int index) {
    switch (index) {
      case 0:
        return const HomeTab();
      case 1:
        return const CategoriesTab();
      case 2:
        return const InvoiceScreen();
      case 3:
        return const ReportsTab();
      case 4:
        return const ProfileTab();
      default:
        return const HomeTab();
    }
  }
}
