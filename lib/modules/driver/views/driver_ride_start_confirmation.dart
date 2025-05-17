import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/modules/driver/controllers/driver_controller.dart';
import 'package:easy_ride/core/widgets/animated_button.dart';
import 'package:lottie/lottie.dart';

class DriverRideStartConfirmation extends GetView<DriverController> {
  const DriverRideStartConfirmation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Ride'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Animation
            Lottie.asset(
              'assets/animations/waiting_rider.json',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 24),

            // Status message
            const Text(
              'You have arrived at the pickup location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait for the rider to confirm the start of the ride',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Rider info
            if (controller.riderInfo.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: controller.riderInfo['profileImageUrl'] != null
                          ? NetworkImage(controller.riderInfo['profileImageUrl'])
                          : null,
                      child: controller.riderInfo['profileImageUrl'] == null
                          ? const Icon(Icons.person, size: 30)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.riderInfo['fullName'] ?? 'Rider',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                controller.riderInfo['rating']?.toString() ?? 'New',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone),
                      onPressed: controller.callRider,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Confirmation status
            Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatusItem(
                  'You',
                  true, // Driver is always confirmed when at this screen
                ),
                const SizedBox(width: 32),
                _buildStatusItem(
                  'Rider',
                  controller.currentRide.isNotEmpty &&
                      controller.currentRide['riderConfirmedStart'] == true,
                ),
              ],
            )),
            const SizedBox(height: 32),

            // Start ride button
            Obx(() => AnimatedButton(
              onPressed: ()=> (controller.currentRide.isNotEmpty &&
                  controller.currentRide['riderConfirmedStart'] == true)
                  ? () {
                controller.startRide();
              }
                  : null,
              child: const Text('Start Ride'),
            )),
            const SizedBox(height: 16),

            // Cancel button
            TextButton(
              onPressed: () {
                Get.dialog(
                  AlertDialog(
                    title: const Text('Cancel Ride?'),
                    content: const Text(
                      'Are you sure you want to cancel this ride? This may affect your rating.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () {
                          Get.back();
                          controller.cancelRide();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Yes, Cancel'),
                      ),
                    ],
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Cancel Ride'),
            ),
          ],
        ),
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
