import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_ride/modules/rider/controllers/rider_controller.dart';
import 'package:easy_ride/core/widgets/animated_button.dart';
import 'package:lottie/lottie.dart';

class RideStartConfirmationView extends GetView<RiderController> {
  const RideStartConfirmationView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Ride Start'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Obx(() => _buildBody()),
    );
  }

  Widget _buildBody() {
    if (controller.currentRide.value == null) {
      return const Center(
        child: Text('No active ride found'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Driver info
          if (controller.driverInfo.value != null) ...[
            CircleAvatar(
              radius: 50,
              backgroundImage: controller.driverInfo.value!.user.profileImageUrl != null
                  ? NetworkImage(controller.driverInfo.value!.user.profileImageUrl!)
                  : null,
              child: controller.driverInfo.value!.user.profileImageUrl == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              controller.driverInfo.value!.user.fullName ?? 'Your Driver',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${controller.driverInfo.value!.vehicle.model} ${controller.driverInfo.value!.vehicle}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'License Plate: ${controller.driverInfo.value!.licenseNumber}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Animation
          Lottie.asset(
            'assets/animations/car_waiting.json',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 24),

          // Status message
          Text(
            'Driver has arrived at your pickup location',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Please confirm that you are ready to start the ride',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Confirmation status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusItem(
                'Driver',
                controller.hasDriverConfirmedStart.value,
              ),
              const SizedBox(width: 32),
              _buildStatusItem(
                'You',
                controller.hasRiderConfirmedStart.value,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Confirm button
          AnimatedButton(
            onPressed: ()=>controller.hasRiderConfirmedStart.value
                ? null
                : () {
              controller.confirmRideStart();
            },
            child: Text(
              controller.hasRiderConfirmedStart.value
                  ? 'Waiting for driver...'
                  : 'Confirm Start',
            ),
          ),

          const SizedBox(height: 16),

          // Cancel button
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text('Not ready yet'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String title, bool isConfirmed) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isConfirmed ? Colors.green : Colors.grey[300],
          ),
          child: Icon(
            isConfirmed ? Icons.check : Icons.hourglass_empty,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isConfirmed ? 'Confirmed' : 'Waiting',
          style: TextStyle(
            color: isConfirmed ? Colors.green : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
