import 'package:easy_ride/modules/driver/views/tabs/driver_earnings.dart';
import 'package:easy_ride/modules/driver/views/tabs/history_tab.dart';
import 'package:easy_ride/modules/driver/views/tabs/maps_tab.dart';
import 'package:easy_ride/modules/driver/views/tabs/profile_tab.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_ride/modules/driver/controllers/driver_controller.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/modules/driver/widgets/ride_request_modal.dart';
import '../widgets/driver_sidebar.dart';

class DriverHomeView extends GetView<DriverController> {
  const DriverHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Home'),
        elevation: 0,

      ),
      drawer: DriverDrawer(controller: controller),
      body: Obx(() => _buildBody()),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBody() {
    // Show ride request modal if there's an incoming request
    if (controller.hasIncomingRequest.value && !controller.isRideAccepted.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showRideRequestModal();
      });
    }

    switch (controller.selectedNavIndex.value) {
      case 0:
        return DriverHomeMapTab();
      case 1:
        return DriverHistoryTab();
      case 2:
        return DriverEarningsTab();
      case 3:
        return DriverProfileTab();
      default:
        return DriverHomeMapTab();
    }
  }

  // Add this method to show the ride request modal
  void _showRideRequestModal() {
    if (controller.incomingRideRequest.value != null) return;

    // Check if modal is already showing
    if (Get.isBottomSheetOpen ?? false) return;

    Get.bottomSheet(
      RideRequestModal(
        controller: controller,
        rideRequest: controller.incomingRideRequest.value!,
      ),
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
    );
  }





  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: controller.selectedNavIndex.value,
      onTap: controller.setNavIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: 'Map',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet),
          label: 'Earnings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
