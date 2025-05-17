import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/modules/rider/controllers/rider_controller.dart';
import 'package:easy_ride/modules/rider/widgets/location_search_bar.dart';
import 'package:easy_ride/models/location_model.dart';

class RideBookingView extends StatefulWidget {
  const RideBookingView({Key? key}) : super(key: key);

  @override
  State<RideBookingView> createState() => _RideBookingViewState();
}

class _RideBookingViewState extends State<RideBookingView> {
  final RiderController controller = Get.find<RiderController>();
  bool _showSearchBar = false;
  bool _isPickupMode = true;
  bool _mapTapEnabled = false;

  @override
  void initState() {
    super.initState();
    // If pickup location is not set, set it to current location
    if (controller.pickupLocation.value == null) {
      controller.getCurrentLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          _buildBackButton(),
          _buildLocationBar(),
          if (_showSearchBar)
            _buildExpandedSearchBar(),
          if (!_showSearchBar)
            _buildBottomCard(),
          if (_mapTapEnabled)
            _buildMapTapInstructions(),
        ],
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
        onTap: _mapTapEnabled ? _handleMapTap : null,
      );
    });
  }

  void _handleMapTap(LatLng position) async {
    // Show loading indicator
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(),
      ),
      barrierDismissible: false,
    );

    try {
      // Reverse geocode the tapped location
      final location = await controller.reverseGeocode(position);

      // Close loading dialog
      Get.back();

      // Set the location based on mode
      if (_isPickupMode) {
        controller.setPickupLocation(location);
      } else {
        controller.setDropoffLocation(location);
      }

      // Disable map tap mode
      setState(() {
        _mapTapEnabled = false;
      });
    } catch (e) {
      // Close loading dialog
      Get.back();

      // Show error
      Get.snackbar(
        'Error',
        'Failed to get location details. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget _buildBackButton() {
    return Positioned(
      top: 40,
      left: 16,
      child: CircleAvatar(
        backgroundColor: Colors.white,
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
    );
  }

  Widget _buildLocationBar() {
    return Positioned(
      top: 40,
      left: 70,
      right: 16,
      child: Obx(() {
        final pickupName = controller.pickupLocation.value?.name ?? 'Set pickup location';
        final dropoffName = controller.dropoffLocation.value?.name ?? 'Where to?';

        return LocationSearchBar(
          pickupLocation: pickupName,
          dropoffLocation: dropoffName,
          onTap: () {
            setState(() {
              _showSearchBar = true;
              _isPickupMode = controller.pickupLocation.value == null;
            });
          },
        );
      }),
    );
  }

  Widget _buildExpandedSearchBar() {
    return Positioned(
      top: 40,
      left: 16,
      right: 16,
      child: Obx(() {
        final pickupName = controller.pickupLocation.value?.name ?? 'Set pickup location';
        final dropoffName = controller.dropoffLocation.value?.name ?? 'Where to?';

        return LocationSearchBar(
          pickupLocation: pickupName,
          dropoffLocation: dropoffName,
          isExpanded: true,
          isPickupMode: _isPickupMode,
          onClose: () {
            setState(() {
              _showSearchBar = false;
            });
          },
          onPickupSelected: (location) {
            controller.setPickupLocation(
              LocationModel(
                name: location['name'],
                latitude: location['latitude'],
                longitude: location['longitude'],
                address: location['address'],
              )
            );
            setState(() {
              _showSearchBar = false;
            });
          },
          onDropoffSelected: (location) {
            controller.setDropoffLocation(
                LocationModel(
                  name: location['name'],
                  latitude: location['latitude'],
                  longitude: location['longitude'],
                  address: location['address'],
                )
            );
            setState(() {
              _showSearchBar = false;
            });
          },
        );
      }),
    );
  }

  Widget _buildBottomCard() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLocationSelectionCard(),
            const SizedBox(height: 16),
            _buildRideOptionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSelectionCard() {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Obx(() {
              final hasPickup = controller.pickupLocation.value != null;
              final hasDropoff = controller.dropoffLocation.value != null;

              return Column(
                children: [
                  // Pickup location
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _showSearchBar = true;
                              _isPickupMode = true;
                            });
                          },
                          child: Text(
                            hasPickup
                                ? controller.pickupLocation.value!.name
                                : 'Set pickup location',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: hasPickup ? Colors.black : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.map, size: 20),
                        onPressed: () {
                          setState(() {
                            _mapTapEnabled = true;
                            _isPickupMode = true;
                          });
                        },
                        tooltip: 'Select on map',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  // Dropoff location
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _showSearchBar = true;
                              _isPickupMode = false;
                            });
                          },
                          child: Text(
                            hasDropoff
                                ? controller.dropoffLocation.value!.name
                                : 'Where to?',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: hasDropoff ? Colors.black : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.map, size: 20),
                        onPressed: () {
                          setState(() {
                            _mapTapEnabled = true;
                            _isPickupMode = false;
                          });
                        },
                        tooltip: 'Select on map',
                      ),
                    ],
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRideOptionsCard() {
    return Obx(() {
      final hasPickup = controller.pickupLocation.value != null;
      final hasDropoff = controller.dropoffLocation.value != null;
      final isCalculatingFare = controller.isCalculatingFare.value;
      final fareEstimate = controller.fareEstimate.value;

      if (!hasPickup || !hasDropoff) {
        return ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            disabledBackgroundColor: Colors.grey,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text(
            'Set pickup and dropoff locations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }

      if (isCalculatingFare) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
        );
      }

      return Column(
        children: [
          // Ride types
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRideTypeOption('standard', 'Standard', Icons.directions_car, 'Up to 4 passengers'),
                _buildRideTypeOption('comfort', 'Comfort', Icons.airline_seat_recline_normal, 'Extra legroom'),
                _buildRideTypeOption('premium', 'Premium', Icons.star, 'Luxury vehicles'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Fare estimate
          if (fareEstimate != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Fare',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${fareEstimate.totalFare.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Estimated Time',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${controller.durationToDestination.value.toInt()} min',
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
          const SizedBox(height: 16),
          // Request ride button
          ElevatedButton(
            onPressed: hasPickup && hasDropoff ? () => controller.requestRide() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text(
              'Request Ride',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildRideTypeOption(String type, String name, IconData icon, String description) {
    return Obx(() {
      final isSelected = controller.selectedRideType.value == type;

      return GestureDetector(
        onTap: () {
          controller.selectedRideType.value = type;
          controller.calculateFare();
        },
        child: Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primaryColor : Colors.black87,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppTheme.primaryColor : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMapTapInstructions() {
    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isPickupMode ? Icons.location_on : Icons.place,
                color: _isPickupMode ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                _isPickupMode
                    ? 'Tap on the map to set pickup location'
                    : 'Tap on the map to set destination',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: () {
                  setState(() {
                    _mapTapEnabled = false;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
