import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../modules/driver/controllers/driver_controller.dart';
import '../widgets/animated_button.dart';

class Helpers {

  static String getRideStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'On the way';
      case 'arrived':
        return 'At pickup';
      case 'started':
        return 'In progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  static Color getRideStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.blue;
      case 'accepted':
        return Colors.orange;
      case 'arrived':
        return Colors.purple;
      case 'started':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static Widget buildActionButton(DriverController controller, String status) {
    switch (status) {
      case 'accepted':
        return AnimatedButton(
          onPressed: controller.arrivedAtPickup,
          backgroundColor: Colors.orange,
          child: const Text('Arrived at Pickup'),
        );
      case 'arrived':
        return AnimatedButton(
          onPressed: controller.startRide,
          backgroundColor: Colors.green,
          child: const Text('Start Ride'),
        );
      case 'started':
        return AnimatedButton(
          onPressed: controller.completeRide,
          child: const Text('Complete Ride'),
        );
      default:
        return AnimatedButton(
          onPressed: () {
            Get.showSnackbar(
              GetSnackBar(
                message: "Loading...",
                duration: const Duration(seconds: 2),
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.grey.shade800,
                borderRadius: 10,
                margin: const EdgeInsets.all(10),
                isDismissible: true,
                icon: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                ),
              ),
            );
          },
          child: const Text('Loading...'),
        );
    }
  }

}