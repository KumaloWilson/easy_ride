import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import '../../../../core/animations/animations.dart';
import '../../../../core/helpers/helpers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/animated_button.dart';
import '../../../../routes/app_pages.dart';
import '../../controllers/driver_controller.dart';
import '../../models/driver.dart';

class DriverHomeMapTab extends GetView<DriverController> {
  const DriverHomeMapTab({super.key});


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


  @override
  Widget build(BuildContext context) {
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
        Obx(() => controller.currentRide.value != null
            ? Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: GestureDetector(
            onTap: () {
              Get.toNamed(
                Routes.driverRideDetails,
                arguments: controller.currentRide.value?.id,
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
                                      color: Helpers.getRideStatusColor(controller.currentRide.value!.status),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    Helpers.getRideStatusText(controller.currentRide.value!.status),
                                    style: TextStyle(
                                      color: Helpers.getRideStatusColor(controller.currentRide.value!.status),
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
                                      controller.currentRide.value?.pickup?.name ?? 'Pickup Location',
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
                                      controller.currentRide.value?.dropoff?.name ?? 'Dropoff Location',
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
                              '\$${(controller.currentRide.value?.fare ?? 0.0).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              controller.currentRide.value?.rideType ?? 'Standard',
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
                              if (controller.riderInfo.value != null) {
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
                              : Helpers.buildActionButton(controller, controller.currentRide.value!.status),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
            : controller.isOnline.value && controller.incomingRideRequest.value != null && !controller.isRideAccepted.value
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
                        '\$${(controller.incomingRideRequest.value?.estimatedFare ?? 0.0).toStringAsFixed(2)}',
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
                                    controller.incomingRideRequest.value?.pickupLocation.name ?? 'Pickup Location',
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
                                    controller.incomingRideRequest.value?.dropoffLocation.name ?? 'Dropoff Location',
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
                                '${(controller.incomingRideRequest.value?.distance ?? 0.0).toStringAsFixed(1)} km',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            controller.incomingRideRequest.value?.rideType ?? 'Standard',
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
          bottom: controller.currentRide.value == null ? 100 : 90,
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
}
