import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/core/services/auth_service.dart';
import 'package:easy_ride/core/services/location_service.dart';
import 'package:easy_ride/core/services/storage_service.dart';
import 'package:easy_ride/core/services/notification_service.dart';
import 'package:easy_ride/core/services/firebase_service.dart';
import 'package:easy_ride/core/services/safety_service.dart';
import 'package:easy_ride/core/services/preferences_service.dart';
import 'package:easy_ride/routes/app_pages.dart';
import 'package:easy_ride/core/values/constants.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Supabase
  await Supabase.initialize(
    url: Constants.supabaseUrl,
    anonKey: Constants.supabaseKey,
  );

  // Initialize services
  await initServices();

  runApp(const MyApp());
}

Future<void> initServices() async {
  print('Starting services initialization...');

  // Initialize PreferencesService first
  await Get.putAsync(() => PreferencesService().init());
  print('PreferencesService initialized');

  // Initialize other services
  await Get.putAsync(() => FirebaseService().init());
  print('FirebaseService initialized');

  await Get.putAsync(() => AuthService().init());
  print('AuthService initialized');

  await Get.putAsync(() => LocationService().init());
  print('LocationService initialized');

  await Get.putAsync(() => StorageService().init());
  print('StorageService initialized');

  await Get.putAsync(() => NotificationService().init());
  print('NotificationService initialized');

  await Get.putAsync(() => SafetyService().init());
  print('SafetyService initialized');

  print('All services initialized successfully');
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: Constants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      defaultTransition: Transition.fade,
      debugShowCheckedModeBanner: false,
    );
  }
}
