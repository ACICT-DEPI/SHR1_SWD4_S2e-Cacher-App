// main.dart
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/ui/auth/login_screen.dart';
import 'package:flutter_application_1/ui/main%20screen/main_screen.dart';
import 'package:flutter_application_1/ui/reports%20screen/cubit/reports_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ui/bill screen/cubit/invoice_cubit.dart';
import 'ui/connectine cubit/connective_states.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void saveInstallationDate() async {
  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey('installationDate')) {
    String now = DateTime.now().toIso8601String();
    await prefs.setString('installationDate', now);
    log('Installation date saved: $now');
  } else {
    log('Installation date already set.');
  }
}

// Create a FlutterLocalNotificationsPlugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  FlutterNativeSplash.remove();

  await Firebase.initializeApp();

  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true);

  saveInstallationDate();

  // Initialize the notifications plugin
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

    return MultiBlocProvider(
      providers: [
        BlocProvider<ConnectivityCubit>(
          create: (context) => ConnectivityCubit(),
        ),
        BlocProvider<InvoiceCubit>(
          create: (context) {
            final cubit = InvoiceCubit();
            cubit.syncOfflineUpdates();
            return cubit;
          },
        ),
        BlocProvider<ReportsCubit>(create: (context) => ReportsCubit()),
      ],
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: BlocListener<ConnectivityCubit, ConnectivityState>(
          listener: (context, state) {
            if (state == ConnectivityState.connected) {
              context.read<InvoiceCubit>().syncOfflineUpdates();
            }
          },
          child: MaterialApp(
            navigatorKey: navigatorKey,
            theme: ThemeData(
              scaffoldBackgroundColor: Colors.white,
              dialogBackgroundColor: Colors.white,
            ),
            debugShowCheckedModeBanner: false,
            title: 'Sales Management App',
            home: StreamBuilder(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.hasData) {
                    return const MainScreen();
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('${snapshot.error}'),
                    );
                  }
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return const LoginScreen();
              },
            ),
          ),
        ),
      ),
    );
  }
}
