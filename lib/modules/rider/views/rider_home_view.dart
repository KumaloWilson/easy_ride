import 'package:easy_ride/models/ride_model.dart';
import 'package:easy_ride/modules/rider/views/ride_details_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/location_model.dart';
import '../controllers/rider_controller.dart';
import '../models/saved_location_model.dart';
import '../views/ride_booking_view.dart';
import '../views/ride_history_view.dart';
import '../../profile/views/profile_view.dart';
import '../widgets/rider_sidebar.dart';

class RiderHomeView extends StatelessWidget {
  final RiderController controller = Get.find<RiderController>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  RiderHomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: RiderSidebar(),
      body: SafeArea(
        child: Stack(
          children: [
            _buildMap(),
            _buildTopBar(context),
            _buildBottomSheet(context),
            _buildCurrentLocationButton(),
            _buildActiveRideCard(context),
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
      child: Row(
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
              icon: const Icon(Icons.menu),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Get.to(() => RideBookingView());
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                child: Row(
                  children: [
                    const Icon(Icons.search),
                    const SizedBox(width: 8),
                    Text(
                      'Where to?',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
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
              icon: const Icon(Icons.history),
              onPressed: () {
                Get.to(() => RideHistoryView());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.1,
      maxChildSize: 0.7,
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
                  ElevatedButton(
                    onPressed: () {
                      Get.to(() => RideBookingView());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      'Book a Ride',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSavedLocations(context),
                  const SizedBox(height: 24),
                  _buildRecentRides(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedLocations(BuildContext context) {
    return Obx(() {
      final savedLocations = controller.savedLocations;

      if (savedLocations.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saved Locations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add_location_alt),
              ),
              title: const Text('Add Home'),
              onTap: () {
                _showAddLocationDialog(context, 'home');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.work),
              ),
              title: const Text('Add Work'),
              onTap: () {
                _showAddLocationDialog(context, 'work');
              },
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saved Locations',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  _showAddLocationDialog(context, 'favorite');
                },
                child: const Text('Add New'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: savedLocations.length > 3 ? 3 : savedLocations.length,
            itemBuilder: (context, index) {
              final location = savedLocations[index];
              return _buildSavedLocationItem(context, location);
            },
          ),
        ],
      );
    });
  }

  Widget _buildSavedLocationItem(BuildContext context, SavedLocationModel location) {
    IconData iconData;

    switch (location.type) {
      case 'home':
        iconData = Icons.home;
        break;
      case 'work':
        iconData = Icons.work;
        break;
      default:
        iconData = Icons.star;
    }

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(iconData),
      ),
      title: Text(location.name),
      subtitle: Text(
        location.address,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        controller.setDropoffLocation(

          LocationModel(
            name: location.name,
            address: location.address,
            latitude: location.latitude,
            longitude: location.longitude,
          ),
        );
        Get.to(() => RideBookingView());
      },
    );
  }

  Widget _buildRecentRides(BuildContext context) {
    return Obx(() {
      final recentRides = controller.rideHistory;

      if (recentRides.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Rides',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Get.to(() => RideHistoryView());
                },
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentRides.length > 3 ? 3 : recentRides.length,
            itemBuilder: (context, index) {
              final ride = recentRides[index];
              return _buildRecentRideItem(context, ride);
            },
          ),
        ],
      );
    });
  }

  Widget _buildRecentRideItem(BuildContext context, RideModel ride) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      leading: CircleAvatar(
        backgroundColor: Colors.grey[200],
        child: const Icon(
          Icons.history,
          color: Colors.black87,
        ),
      ),
      title: Text(
        ride.dropoff?.name ?? 'Unknown destination',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'From: ${ride.pickup?.name ?? 'Unknown pickup'}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '\$${(ride.fare ?? 0.0).toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      onTap: () {
        controller.setPickupLocation(ride.pickup!);
        controller.setDropoffLocation(ride.dropoff!);
        Get.to(() => RideBookingView());
      },
    );
  }

  Widget _buildCurrentLocationButton() {
    return Positioned(
      right: 16,
      bottom: 350,
      child: FloatingActionButton(
        heroTag: 'currentLocationBtn',
        backgroundColor: Colors.white,
        child: const Icon(
          Icons.my_location,
          color: Colors.black87,
        ),
        onPressed: () {
          controller.toggleFollowUser();
        },
      ),
    );
  }

  Widget _buildActiveRideCard(BuildContext context) {
    return Obx(() {
      final activeRide = controller.currentRide.value;

      if (activeRide == null) {
        return const SizedBox.shrink();
      }

      return Positioned(
        bottom: 250,
        left: 16,
        right: 16,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active Ride',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildRideStatusBadge(context, activeRide.status ?? 'pending'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        activeRide.dropoff?.name ?? 'Unknown destination',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Get.to(() => RideDetailsView());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: const Text('View Ride Details'),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildRideStatusBadge(BuildContext context, String status) {
    Color color;
    String text;

    switch (status) {
      case 'pending':
      case 'requested':
        color = Colors.orange;
        text = 'Finding Driver';
        break;
      case 'accepted':
        color = Colors.blue;
        text = 'Driver Coming';
        break;
      case 'arrived':
        color = Colors.green;
        text = 'Driver Arrived';
        break;
      case 'started':
        color = Colors.purple;
        text = 'In Progress';
        break;
      case 'completed':
        color = Colors.green;
        text = 'Completed';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showAddLocationDialog(BuildContext context, String locationType) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController addressController = TextEditingController();

    if (locationType == 'home') {
      nameController.text = 'Home';
    } else if (locationType == 'work') {
      nameController.text = 'Work';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${locationType.capitalize} Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter location name',
              ),
              readOnly: locationType == 'home' || locationType == 'work',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: 'Enter address',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Get current location
              if (controller.currentLocation.value.latitude != 0) {
                final location = {
                  'name': nameController.text,
                  'address': addressController.text,
                  'latitude': controller.currentLocation.value.latitude,
                  'longitude': controller.currentLocation.value.longitude,
                  'type': locationType,
                };

                controller.saveLocation(location);
                Get.back();
              } else {
                Get.snackbar(
                  'Error',
                  'Unable to get current location',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
