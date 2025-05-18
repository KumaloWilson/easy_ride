import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:easy_ride/modules/driver/controllers/driver_controller.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/routes/app_pages.dart';
import 'package:easy_ride/core/utils/logs.dart';
import 'package:easy_ride/core/widgets/animated_button.dart';
import 'package:easy_ride/core/animations/animations.dart';
import 'package:easy_ride/core/values/constants.dart';
import 'package:easy_ride/modules/driver/widgets/ride_request_modal.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/driver.dart';
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
        return _buildMapView();
      case 1:
        return _buildHistoryView();
      case 2:
        return _buildEarningsView();
      case 3:
        return _buildProfileView();
      default:
        return _buildMapView();
    }
  }

  // Add this method to show the ride request modal
  void _showRideRequestModal() {
    if (controller.incomingRideRequest.isEmpty) return;

    // Check if modal is already showing
    if (Get.isBottomSheetOpen ?? false) return;

    Get.bottomSheet(
      RideRequestModal(
        controller: controller,
        rideRequest: controller.incomingRideRequest,
      ),
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
    );
  }

  // Update the _buildMapView method to handle location updates better
  Widget _buildMapView() {
    return Stack(
      children: [
        // Google Map
        Obx(() {
          final initialPos = controller.initialCameraPosition.value;
          final currentLocation = controller.currentLocation.value;

          return GoogleMap(
            initialCameraPosition: initialPos,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            markers: controller.markers,
            polylines: controller.polylines,
            mapType: controller.mapType.value == 'normal' ? MapType.normal : MapType.satellite,
            trafficEnabled: controller.showTraffic.value,
            circles: controller.circles,
            onMapCreated: (GoogleMapController mapController) {
              controller.setMapController(mapController);

              // Ensure we center on driver location after map is created
              if (currentLocation != null &&
                  currentLocation.latitude != 0 &&
                  currentLocation.longitude != 0) {
                Future.delayed(Duration(milliseconds: 500), () {
                  mapController.animateCamera(
                    CameraUpdate.newLatLngZoom(
                        LatLng(currentLocation.latitude, currentLocation.longitude),
                        15
                    ),
                  );
                });
              }
            },
            onCameraMove: (position) {
              controller.mapZoom.value = position.zoom;
            },
            onCameraIdle: () {
              if (controller.isFollowingUser.value) {
                controller.isFollowingUser.value = false;
              }
            },
          );
        }),

        // Online/Offline Toggle
        Positioned(
          top: Get.mediaQuery.padding.top + 10,
          left: 16,
          right: 16,
          child: Obx(() => AnimatedCard(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    color: controller.driverStatus.value == DriverStatus.online
                        ? Colors.green
                        : controller.driverStatus.value == DriverStatus.busy
                        ? Colors.orange
                        : Colors.red,
                    size: 12,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    controller.driverStatus.value == DriverStatus.online
                        ? 'You are Online'
                        : controller.driverStatus.value == DriverStatus.busy
                        ? 'You are Busy'
                        : 'You are Offline',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: controller.driverStatus.value == DriverStatus.online
                          ? Colors.green
                          : controller.driverStatus.value == DriverStatus.busy
                          ? Colors.orange
                          : Colors.red,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: controller.driverStatus.value != DriverStatus.offline,
                    onChanged: (controller.driverStatus.value == DriverStatus.busy || !controller.isVerified.value)
                        ? null  // Disable toggle when busy or not verified
                        : (value) {
                      controller.toggleOnlineStatus();
                    },
                    activeColor: controller.driverStatus.value == DriverStatus.busy
                        ? Colors.orange
                        : Colors.green,
                  ),
                ],
              ),
            ),
          )),
        ),

        // Verification Status Banner
        Obx(() => !controller.isVerified.value
            ? Positioned(
          top: Get.mediaQuery.padding.top + 140,
          left: 16,
          right: 16,
          child: GestureDetector(
            onTap: () {
              Get.toNamed(Routes.driverVerification);
            },
            child: AnimatedCard(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: controller.isVerificationPending.value
                      ? Colors.orange.withOpacity(0.9)
                      : Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      controller.isVerificationPending.value
                          ? Icons.pending_outlined
                          : Icons.error_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.isVerificationPending.value
                                ? 'Verification Pending'
                                : 'Verification Required',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            controller.isVerificationPending.value
                                ? 'Your documents are being reviewed'
                                : 'Complete verification to go online and accept rides',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
            : const SizedBox.shrink()
        ),

        // Current Ride Card (if any)
        Obx(() => controller.currentRide.isNotEmpty
            ? Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  Get.toNamed(
                    Routes.driverRideDetails,
                    arguments: controller.currentRide['id'],
                  );
                },
                child: AnimatedCard(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.directions_car,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Current Ride',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: _getRideStatusColor(controller.currentRide['status']),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _getRideStatusText(controller.currentRide['status']),
                                        style: TextStyle(
                                          color: _getRideStatusColor(controller.currentRide['status']),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          controller.currentRide['pickup']?['name'] ?? 'Pickup Location',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          controller.currentRide['dropoff']?['name'] ?? 'Dropoff Location',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${(controller.currentRide['fare'] ?? 0.0).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  controller.currentRide['rideType'] ?? 'Standard',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  if (controller.riderInfo.isNotEmpty) {
                                    controller.callRider();
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.phone),
                                    SizedBox(width: 8),
                                    Text('Call'),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: controller.isCompletingRide.value
                                ? Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[700]!),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('Waiting...', style: TextStyle(color: Colors.black54)),
                                      ],
                                    ),
                                  )
                                : _buildActionButton(controller.currentRide['status']),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            : controller.isOnline.value && controller.incomingRideRequest.isNotEmpty && !controller.isRideAccepted.value
            ? Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: AnimatedCard(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${controller.requestTimeRemaining.value.toInt()}s',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '\$${(controller.incomingRideRequest['fare'] ?? 0.0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'New Ride Request',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    controller.incomingRideRequest['pickup']?['name'] ?? 'Pickup Location',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    controller.incomingRideRequest['dropoff']?['name'] ?? 'Dropoff Location',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.directions_car,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${(controller.incomingRideRequest['distance'] ?? 0.0).toStringAsFixed(1)} km',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            controller.incomingRideRequest['rideType'] ?? 'Standard',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller.rejectRideRequest,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AnimatedButton(
                          onPressed: controller.acceptRideRequest,
                          child: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
            : controller.isOnline.value
            ? const SizedBox.shrink()
            : Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: AnimatedCard(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.offline_bolt,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'You\'re Offline',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Go online to start receiving ride requests',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        )
        ),

        // Map Controls
        Positioned(
          bottom: controller.currentRide.isNotEmpty ? 100 : 90,
          right: 16,
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 24,
                child: IconButton(
                  icon: const Icon(Icons.my_location),
                  color: AppTheme.primaryColor,
                  onPressed: centerOnUserLocation,
                ),
              ),
              const SizedBox(height: 8),
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 24,
                child: IconButton(
                  icon: const Icon(Icons.layers),
                  color: AppTheme.primaryColor,
                  onPressed: controller.toggleMapType,
                ),
              ),
              const SizedBox(height: 8),
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 24,
                child: IconButton(
                  icon: const Icon(Icons.traffic),
                  color: controller.showTraffic.value ? AppTheme.primaryColor : Colors.grey,
                  onPressed: () {
                    controller.showTraffic.value = !controller.showTraffic.value;
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryView() {
    return Padding(
      padding: EdgeInsets.only(top: Get.mediaQuery.padding.top),
      child: Column(
        children: [
          AppBar(
            title: const Text('Ride History'),
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black,
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingRideHistory.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (controller.rideHistory.isEmpty) {
                return const Center(
                  child: Text('No ride history yet'),
                );
              }

              return ListView.builder(
                itemCount: controller.rideHistory.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final ride = controller.rideHistory[index];
                  return AnimatedCard(
                    delay: Duration(milliseconds: 100 * index),
                    child: Card(
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  ride.createdAt.toString().substring(0, 10),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ride.status == Constants.completed
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    ride.status.capitalize!,
                                    style: TextStyle(
                                      color: ride.status == Constants.completed
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    ride.pickup!.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    ride.dropoff!.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${ride.distance.toStringAsFixed(1)} km',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '\$${ride.fare.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsView() {
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
                        child: _buildEarningCard(
                          'Today',
                          '\$${controller.todayEarnings.value.toStringAsFixed(2)}',
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildEarningCard(
                          'This Week',
                          '\$${controller.weeklyEarnings.value.toStringAsFixed(2)}',
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildEarningCard(
                          'Total Earnings',
                          '\$${controller.totalEarnings.value.toStringAsFixed(2)}',
                          AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildEarningCard(
                          'Completed Rides',
                          '${controller.completedRides.value}',
                          Colors.orange,
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

  Widget _buildEarningCard(String title, String value, Color color) {
    return AnimatedCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    return Padding(
      padding: EdgeInsets.only(top: Get.mediaQuery.padding.top),
      child: Column(
        children: [
          AppBar(
            title: const Text('Profile'),
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
                  // Profile header
                  Center(
                    child: Column(
                      children: [
                        Obx(() {
                          final user = FirebaseAuth.instance.currentUser;
                          return CircleAvatar(
                            radius: 50,
                            backgroundColor: AppTheme.primaryColor,
                            backgroundImage: user?.photoURL != null
                                ? NetworkImage(user!.photoURL!)
                                : null,
                            child: user?.photoURL == null
                                ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            )
                                : null,
                          );
                        }),
                        const SizedBox(height: 16),
                        Obx(() => Text(
                          controller.currentUser.value?.fullName ?? 'Driver',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                        const SizedBox(height: 4),
                        Obx(() => Text(
                          controller.currentUser.value?.email ?? '',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        )),
                        const SizedBox(height: 8),
                        Obx(() => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: controller.isVerified.value
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            controller.isVerified.value
                                ? 'Verified Driver'
                                : 'Verification Pending',
                            style: TextStyle(
                              color: controller.isVerified.value
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Account settings
                  const Text(
                    'Account Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingsItem(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    onTap: () {
                      Get.toNamed(Routes.profileSetup);
                    },
                  ),
                  _buildSettingsItem(
                    icon: Icons.verified_user_outlined,
                    title: 'Driver Verification',
                    onTap: () {
                      Get.toNamed(Routes.driverVerification);
                    },
                  ),
                  _buildSettingsItem(
                    icon: Icons.car_rental,
                    title: 'Vehicle Information',
                    onTap: () {
                      Get.toNamed(Routes.driverDocumentUpload);
                    },
                  ),
                  _buildSettingsItem(
                    icon: Icons.payment_outlined,
                    title: 'Payment Methods',
                    onTap: () {
                      Get.toNamed(Routes.driverEarnings);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Support
                  const Text(
                    'Support',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingsItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      _showHelpSupportDialog();
                    },
                  ),
                  _buildSettingsItem(
                    icon: Icons.info_outline,
                    title: 'About',
                    onTap: () {
                      _showAboutDialog();
                    },
                  ),
                  _buildSettingsItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {
                      _showPrivacyPolicyDialog();
                    },
                  ),
                  const SizedBox(height: 24),

                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedButton(
                      onPressed: () {
                        _confirmLogout();
                      },
                      backgroundColor: Colors.red,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.logout, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return AnimatedCard(
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildActionButton(String status) {
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

  // void _showMenuOptions() {
  //   Get.bottomSheet(
  //     Container(
  //       padding: const EdgeInsets.symmetric(vertical: 20),
  //       decoration: const BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.only(
  //           topLeft: Radius.circular(20),
  //           topRight: Radius.circular(20),
  //         ),
  //       ),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Container(
  //             width: 40,
  //             height: 5,
  //             decoration: BoxDecoration(
  //               color: Colors.grey[300],
  //               borderRadius: BorderRadius.circular(10),
  //             ),
  //           ),
  //           const SizedBox(height: 20),
  //           ListTile(
  //             leading: const Icon(Icons.home),
  //             title: const Text('Home'),
  //             onTap: () {
  //               Get.back();
  //               controller.setNavIndex(0);
  //             },
  //           ),
  //           ListTile(
  //             leading: const Icon(Icons.history),
  //             title: const Text('Ride History'),
  //             onTap: () {
  //               Get.back();
  //               controller.setNavIndex(1);
  //             },
  //           ),
  //           ListTile(
  //             leading: const Icon(Icons.account_balance_wallet),
  //             title: const Text('Earnings'),
  //             onTap: () {
  //               Get.back();
  //               controller.setNavIndex(2);
  //             },
  //           ),
  //           ListTile(
  //             leading: const Icon(Icons.description),
  //             title: const Text('Documents'),
  //             onTap: () {
  //               Get.back();
  //               Get.toNamed(Routes.driverDocumentUpload);
  //             },
  //           ),
  //           ListTile(
  //             leading: const Icon(Icons.person),
  //             title: const Text('Profile'),
  //             onTap: () {
  //               Get.back();
  //               controller.setNavIndex(3);
  //             },
  //           ),
  //           const Divider(),
  //           ListTile(
  //             leading: const Icon(Icons.help),
  //             title: const Text('Help & Support'),
  //             onTap: () {
  //               Get.back();
  //               _showHelpSupportDialog();
  //             },
  //           ),
  //           ListTile(
  //             leading: const Icon(Icons.info),
  //             title: const Text('About'),
  //             onTap: () {
  //               Get.back();
  //               _showAboutDialog();
  //             },
  //           ),
  //           ListTile(
  //             leading: const Icon(Icons.logout),
  //             title: const Text('Logout'),
  //             onTap: () {
  //               Get.back();
  //               _confirmLogout();
  //             },
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  void _showHelpSupportDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email Support'),
              subtitle: const Text('support@easyride.com'),
              onTap: () {
                // Launch email
                DevLogs.debug('Email support tapped');
                Get.back();
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Call Support'),
              subtitle: const Text('+1 (555) 123-4567'),
              onTap: () {
                // Launch phone call
                DevLogs.debug('Call support tapped');
                Get.back();
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Live Chat'),
              subtitle: const Text('Available 24/7'),
              onTap: () {
                // Open live chat
                DevLogs.debug('Live chat tapped');
                Get.back();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('About Easy Ride'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Easy Ride is a ride-sharing platform that connects drivers with riders for a seamless transportation experience.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              'Version: 1.0.0',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              '© 2023 Easy Ride Inc. All rights reserved.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'This Privacy Policy describes how Easy Ride collects, uses, and discloses your personal information when you use our application.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'Information We Collect:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Personal information such as name, email, phone number\n'
                    '• Location data for ride coordination\n'
                    '• Payment information\n'
                    '• Device information',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'How We Use Your Information:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• To provide and improve our services\n'
                    '• To process payments\n'
                    '• To communicate with you\n'
                    '• For safety and security purposes',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Color _getRideStatusColor(String status) {
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

  String _getRideStatusText(String status) {
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


  // Update the centerOnUserLocation method to be more robust
  void centerOnUserLocation() {
    if (controller.currentLocation.value != null &&
        controller.currentLocation.value!.latitude != 0 &&
        controller.currentLocation.value!.longitude != 0 &&
        controller.mapController.value != null) {

      controller.mapController.value!.animateCamera(
        CameraUpdate.newLatLngZoom(
            LatLng(
                controller.currentLocation.value!.latitude,
                controller.currentLocation.value!.longitude
            ),
            15
        ),
      );
      controller.isFollowingUser.value = true;
    } else {
      Get.snackbar(
        'Location Unavailable',
        'Your current location is not available yet. Please try again in a moment.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
