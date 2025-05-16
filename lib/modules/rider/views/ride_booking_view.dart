import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../controllers/rider_controller.dart';
import '../widgets/location_search_bar.dart';
import '../widgets/ride_options_card.dart';
import '../widgets/fare_breakdown_card.dart';

class RideBookingView extends StatelessWidget {
  final RiderController controller = Get.find<RiderController>();

  RideBookingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _buildMap(),
            _buildTopBar(context),
            _buildBottomSheet(context),
            _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return Obx(() {
      final markers = controller.markers;
      final polylines = controller.polylines;

      return GoogleMap(
        initialCameraPosition: CameraPosition(
          target: controller.currentLocation.value,
          zoom: 15,
        ),
        markers: markers,
        polylines: polylines,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: true,
        onMapCreated: (GoogleMapController mapController) {
          controller.mapController.value = mapController;
        },
      );
    });
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Get.back(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Book a Ride',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // Balance for back button
            ],
          ),
          const SizedBox(height: 16),
          Obx(() => TextField(
            decoration: InputDecoration(
              hintText: controller.pickupLocation.value?['name'] ?? 'Set pickup location',
              prefixIcon: const Icon(Icons.my_location, color: Colors.green),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            readOnly: true,
            onTap: () {
              // Show location search for pickup
              _showLocationSearch(context, true);
            },
          )),
          const SizedBox(height: 8),
          Obx(() => TextField(
            decoration: InputDecoration(
              hintText: controller.dropoffLocation.value?['name'] ?? 'Where to?',
              prefixIcon: const Icon(Icons.location_on, color: Colors.red),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            readOnly: true,
            onTap: () {
              // Show location search for dropoff
              _showLocationSearch(context, false);
            },
          )),
        ],
      ),
    );
  }

  void _showLocationSearch(BuildContext context, bool isPickup) {
    // In a real app, you would show a search UI here
    // For this example, we'll simulate selecting a location
    final location = {
      'name': isPickup ? 'Current Location' : 'Central Park',
      'address': isPickup ? 'Your current location' : 'Central Park, New York',
      'latitude': isPickup ? controller.currentLocation.value.latitude : 40.7812,
      'longitude': isPickup ? controller.currentLocation.value.longitude : -73.9665,
    };

    if (isPickup) {
      controller.setPickupLocation(location);
    } else {
      controller.setDropoffLocation(location);
    }
  }

  Widget _buildBottomSheet(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select Ride Type',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(() => Column(
                    children: [
                      _buildRideTypeOption('Standard', 'Affordable rides for everyday', 1.0,
                          controller.selectedRideType.value == 'Standard'),
                      _buildRideTypeOption('Premium', 'High-end cars with top-rated drivers', 1.5,
                          controller.selectedRideType.value == 'Premium'),
                      _buildRideTypeOption('XL', 'Spacious vehicles for groups up to 6', 2.0,
                          controller.selectedRideType.value == 'XL'),
                    ],
                  )),
                  const SizedBox(height: 24),
                  Obx(() {
                    if (controller.isCalculatingFare.value) {
                      return ShimmerLoading(
                        child: Container(
                          height: 100,
                          width: double.infinity,
                        ),
                        isLoading: true,
                      );
                    } else if (controller.fareEstimate.value != null) {
                      return _buildFareCard(context);
                    } else {
                      return const SizedBox.shrink();
                    }
                  }),
                  const SizedBox(height: 24),
                  Obx(() {
                    final bool canRequestRide = controller.pickupLocation.value != null &&
                        controller.dropoffLocation.value != null;
                    return ElevatedButton(
                      onPressed: canRequestRide
                          ? () => controller.requestRide()
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: controller.isRequestingRide.value
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        'Request Ride',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Obx(() {
                    if (controller.fareEstimate.value != null) {
                      return Center(
                        child: Text(
                          'Estimated arrival: ${_formatDuration(controller.durationToDestination.value)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRideTypeOption(String title, String description, double multiplier, bool isSelected) {
    return GestureDetector(
      onTap: () {
        controller.selectedRideType.value = title;
        controller.calculateFare();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              title == 'Standard' ? Icons.directions_car
                  : title == 'Premium' ? Icons.airport_shuttle
                  : Icons.directions_bus,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.primaryColor : Colors.black,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Obx(() {
              if (controller.fareEstimate.value != null) {
                final baseFare = controller.fareEstimate.value!.baseFare;
                final fare = baseFare * multiplier;
                return Text(
                  '\$${fare.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppTheme.primaryColor : Colors.black,
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFareCard(BuildContext context) {
    final fare = controller.fareEstimate.value!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fare Estimate',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${fare.totalFare.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Distance',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              Text('${fare.distance.toStringAsFixed(1)} km'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Duration',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              Text('${_formatDuration(fare.duration)}'),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              controller.showFareBreakdown.value = true;
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View fare breakdown',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(double minutes) {
    if (minutes < 1) {
      return 'Less than a minute';
    } else if (minutes < 60) {
      return '${minutes.round()} min';
    } else {
      final hours = (minutes / 60).floor();
      final mins = (minutes % 60).round();
      return '${hours}h ${mins}m';
    }
  }

  Widget _buildLoadingOverlay() {
    return Obx(() {
      if (controller.isRequestingRide.value) {
        return Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/animations/car_loading.json',
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Finding your driver...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        return const SizedBox.shrink();
      }
    });
  }
}
