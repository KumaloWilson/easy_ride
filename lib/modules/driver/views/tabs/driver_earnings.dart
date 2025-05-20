import '../../controllers/driver_controller.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_ride/core/animations/animations.dart';
import 'package:easy_ride/core/values/constants.dart';

import '../../widgets/earning_card.dart';

class DriverEarningsTab extends GetView<DriverController> {
  const DriverEarningsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: Get.mediaQuery.padding.top),
      child: Column(
        children: [
          AppBar(
            title: const Text('Earnings'),
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary cards
                  Row(
                    children: [
                      Expanded(
                        child: DriverEarningCard(
                          title: 'Today',
                          value: '\$${controller.todayEarnings.value.toStringAsFixed(2)}',
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DriverEarningCard(
                          title: 'This Week',
                          value: '\$${controller.weeklyEarnings.value.toStringAsFixed(2)}',
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DriverEarningCard(
                          title:'Total Earnings',
                          value: '\$${controller.totalEarnings.value.toStringAsFixed(2)}',
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DriverEarningCard(
                          title: 'Completed Rides',
                          value: '${controller.completedRides.value}',
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recent earnings
                  const Text(
                    'Recent Earnings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    if (controller.rideHistory.isEmpty) {
                      return const Center(
                        child: Text('No earnings yet'),
                      );
                    }

                    final completedRides = controller.rideHistory
                        .where((ride) => ride.status == Constants.completed)
                        .take(5)
                        .toList();

                    if (completedRides.isEmpty) {
                      return const Center(
                        child: Text('No completed rides yet'),
                      );
                    }

                    return ListView.builder(
                      itemCount: completedRides.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final ride = completedRides[index];
                        return AnimatedCard(
                          delay: Duration(milliseconds: 100 * index),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(
                                ride.dropoff!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                ride.completedAt?.toString().substring(0, 16) ?? '',
                              ),
                              trailing: Text(
                                '\$${ride.fare.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
