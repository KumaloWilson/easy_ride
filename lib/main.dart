import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:easy_ride/routes/app_pages.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/core/services/auth_service.dart';
import 'package:easy_ride/core/services/location_service.dart';
import 'package:easy_ride/core/services/storage_service.dart';
import 'package:easy_ride/core/services/notification_service.dart';
import 'package:easy_ride/core/services/firebase_service.dart';
import 'package:easy_ride/core/services/safety_service.dart';
import 'package:easy_ride/core/services/preferences_service.dart';
import 'package:easy_ride/core/values/constants.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/services/api_service.dart';
import 'firebase_options.dart';
import 'modules/driver/services/voice_navigation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
  print('Initializing services...');

  // Initialize all services
  await Get.putAsync(() => PreferencesService().init());
  await Get.putAsync(() => AuthService().init());
  await Get.putAsync(() => ApiService().init());
  await Get.putAsync(() => StorageService().init());
  await Get.putAsync(() => LocationService().init());
  await Get.putAsync(() => NotificationService().init());
  await Get.putAsync(() => VoiceNavigationService().init());
  await Get.putAsync(() => FirebaseService().init());
  await Get.putAsync(() => SafetyService().init());

  print('All services initialized');
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Easy Ride',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      defaultTransition: Transition.fade,
      debugShowCheckedModeBanner: false,
    );
  }
}
