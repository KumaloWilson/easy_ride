import 'package:get/get.dart';
import 'package:easy_ride/modules/driver/controllers/driver_controller.dart';

class DriverBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DriverController>(() => DriverController());
  }
}
