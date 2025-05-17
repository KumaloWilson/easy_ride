import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_ride/modules/driver/controllers/driver_controller.dart';
import 'package:easy_ride/core/widgets/shimmer_loading.dart';
import 'package:easy_ride/models/ride_model.dart';
import 'package:easy_ride/core/values/constants.dart';
import 'package:intl/intl.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/core/animations/animations.dart';

class DriverRideHistoryView extends StatefulWidget {
  const DriverRideHistoryView({Key? key}) : super(key: key);

  @override
  State<DriverRideHistoryView> createState() => _DriverRideHistoryViewState();
}

class _DriverRideHistoryViewState extends State<DriverRideHistoryView> with SingleTickerProviderStateMixin {
  final DriverController controller = Get.find<DriverController>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    controller.fetchRideHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRideList(Constants.completed),
              _buildRideList(Constants.cancelled),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRideList(String status) {
    return Obx(() {
      if (controller.isLoadingRideHistory.value) {
        return _buildLoadingList();
      }

      final rides = controller.rideHistory.where((ride) => ride.status == status).toList();

      if (rides.isEmpty) {
        return _buildEmptyState(status);
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rides.length,
        itemBuilder: (context, index) {
          return AnimatedCard(
            delay: Duration(milliseconds: 100 * index),
            child: _buildRideCard(rides[index]),
          );
        },
      );
    });
  }

  Widget _buildRideCard(RideModel ride) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy · h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => Get.toNamed('/driver/ride-details/${ride.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ride.status == Constants.completed ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ride.status == Constants.completed ? 'Completed' : 'Cancelled',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$${ride.fare.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                dateFormat.format(ride.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Column(
                    children: [
                      const Icon(
                        Icons.circle,
                        color: Colors.green,
                        size: 12,
                      ),
                      Container(
                        width: 1,
                        height: 20,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 12,
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.pickup!.name,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          ride.dropoff!.name,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.directions_car,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${ride.distance.toStringAsFixed(1)} km',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${ride.duration.toStringAsFixed(0)} min',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShimmerLoading(
                      width: 80,
                      height: 24,
                      borderRadius: 12,
                      isLoading: true,
                    ),
                    const Spacer(),
                    ShimmerLoading(
                      width: 60,
                      height: 24,
                      borderRadius: 4,
                      isLoading: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ShimmerLoading(
                  width: 150,
                  height: 16,
                  borderRadius: 4,
                  isLoading: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Column(
                      children: [
                        const ShimmerLoading(
                          width: 12,
                          height: 12,
                          borderRadius: 6,
                          isLoading: true,
                        ),
                        Container(
                          width: 1,
                          height: 20,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        const ShimmerLoading(
                          width: 12,
                          height: 12,
                          borderRadius: 6,
                          isLoading: true,
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          ShimmerLoading(
                            width: double.infinity,
                            height: 16,
                            borderRadius: 4,
                            isLoading: true,
                          ),
                          SizedBox(height: 12),
                          ShimmerLoading(
                            width: double.infinity,
                            height: 16,
                            borderRadius: 4,
                            isLoading: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    ShimmerLoading(
                      width: 80,
                      height: 16,
                      borderRadius: 4,
                      isLoading: true,
                    ),
                    SizedBox(width: 16),
                    ShimmerLoading(
                      width: 80,
                      height: 16,
                      borderRadius: 4,
                      isLoading: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String status) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            status == Constants.completed ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            status == Constants.completed
                ? 'No completed rides yet'
                : 'No cancelled rides',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            status == Constants.completed
                ? 'Your completed rides will appear here'
                : 'Cancelled rides will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
