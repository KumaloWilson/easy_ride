import 'package:get/get.dart';
import 'package:easy_ride/core/services/auth_service.dart';
import 'package:easy_ride/core/services/location_service.dart';
import 'package:easy_ride/core/services/storage_service.dart';
import 'package:easy_ride/core/services/notification_service.dart';
import 'package:easy_ride/core/services/firebase_service.dart';

Future<void> initServices() async {
  print('Initializing services...');
  
  // Initialize Firebase service
  await Get.putAsync(() => FirebaseService().init());
  
  // Initialize Auth service
  await Get.putAsync(() => AuthService().init());
  
  // Initialize Storage service
  await Get.putAsync(() => StorageService().init());
  
  // Initialize Location service
  await Get.putAsync(() => LocationService().init());
  
  // Initialize Notification service
  await Get.putAsync(() => NotificationService().init());
  
  print('All services initialized');
}
