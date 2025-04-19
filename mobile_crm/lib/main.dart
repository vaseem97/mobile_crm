import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'dart:io';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/router.dart';
import 'core/firebase/firebase_options.dart';
import 'core/services/service_locator.dart';
import 'core/services/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations to portrait only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Setup service locator (now async)
  await setupServiceLocator();

  // Configure and check connectivity
  final connectivityService = getService<ConnectivityService>();

  // Configure the internet connection checker with additional addresses
  connectivityService.configureConnectionChecker(
    addresses: [
      // Google DNS
      AddressCheckOptions(
        address: InternetAddress('8.8.8.8'),
        port: 53,
        timeout: const Duration(seconds: 2),
      ),
      // CloudFlare DNS
      AddressCheckOptions(
        address: InternetAddress('1.1.1.1'),
        port: 53,
        timeout: const Duration(seconds: 2),
      ),
      // Default address checks
      ...InternetConnectionChecker().addresses,
    ],
  );

  // Do initial connectivity check
  await connectivityService.checkConnection();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
