import 'package:get/get.dart';
import 'package:easy_ride/modules/rider/controllers/rider_controller.dart';
import 'package:easy_ride/core/services/location_service.dart';
import 'package:easy_ride/core/services/auth_service.dart';
import 'package:easy_ride/core/services/storage_service.dart';
import 'package:easy_ride/core/services/notification_service.dart';
import 'package:easy_ride/core/services/safety_service.dart';

class RiderBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure required services are available
    Get.lazyPut<LocationService>(() => LocationService(), fenix: true);
    Get.lazyPut<AuthService>(() => AuthService(), fenix: true);
    Get.lazyPut<StorageService>(() => StorageService(), fenix: true);
    Get.lazyPut<NotificationService>(() => NotificationService(), fenix: true);
    Get.lazyPut<SafetyService>(() => SafetyService(), fenix: true);

    // Register the RiderController
    Get.lazyPut<RiderController>(() => RiderController());
  }
}
