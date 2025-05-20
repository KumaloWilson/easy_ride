import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:easy_ride/modules/driver/controllers/driver_controller.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/routes/app_pages.dart';
import 'package:easy_ride/models/ride_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animated_button/animated_button.dart';

class DriverRideDetailsView extends GetView<DriverController> {
  const DriverRideDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final String rideId = Get.arguments as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Details'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildRideContent(context, rideId),
          ),
          // Payment received listener
          Obx(() {
            if (controller.paymentReceived.value) {
              // Use post-frame callback to avoid build errors
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showPaymentCompletedDialog(context);
                // Reset the flag after showing dialog
                controller.paymentReceived.value = false;
              });
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildRideContent(BuildContext context, String rideId) {
    return StreamBuilder<RideModel>(
      stream: controller.firebaseService.documentStream<RideModel>(
        path: 'rides/$rideId',
        builder: (data, documentId) => data != null
            ? RideModel.fromMap(data, documentId)
            : RideModel(
          id: documentId,
          riderId: '',
          status: 'unknown',
          rideType: '',
          pickup: null,
          dropoff: null,
          distance: 0,
          duration: 0,
          fare: 0,
          paymentMethod: '',
          createdAt: DateTime.now(),
        ),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('Ride not found'));
        }

        final ride = snapshot.data!;

        return Column(
          children: [
            // Map
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(37.42796133580664, -122.085749655962),
                  zoom: 14.4746,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                compassEnabled: true,
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
                markers: _buildRideMarkers(ride),
                polylines: _buildRidePolylines(ride),
                onMapCreated: (GoogleMapController mapController) {
                  controller.mapController.value = mapController;
                  _adjustCameraToRoute(mapController, ride);
                },
              ),
            ),

            // Ride details
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status card
                    _buildStatusCard(ride),
                    const SizedBox(height: 24),

                    // Rider info
                    _buildRiderInfo(ride),

                    // Ride info
                    const Text(
                      'Ride Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRideInfoCard(ride),
                    const SizedBox(height: 24),

                    // Action buttons
                    _buildActionButton(ride.status),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _adjustCameraToRoute(GoogleMapController mapController, RideModel ride) {
    if (ride.pickup != null && ride.dropoff != null) {
      final LatLng pickupLatLng = LatLng(
        ride.pickup!.latitude,
        ride.pickup!.longitude,
      );

      final LatLng dropoffLatLng = LatLng(
        ride.dropoff!.latitude,
        ride.dropoff!.longitude,
      );

      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          min(pickupLatLng.latitude, dropoffLatLng.latitude) - 0.01,
          min(pickupLatLng.longitude, dropoffLatLng.longitude) - 0.01,
        ),
        northeast: LatLng(
          max(pickupLatLng.latitude, dropoffLatLng.latitude) + 0.01,
          max(pickupLatLng.longitude, dropoffLatLng.longitude) + 0.01,
        ),
      );

      mapController.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    }
  }

  Widget _buildStatusCard(RideModel ride) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor(ride.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(ride.status),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(ride.status),
            color: _getStatusColor(ride.status),
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusText(ride.status),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _getStatusColor(ride.status),
                  ),
                ),
                _buildStatusSubtext(ride.status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSubtext(String status) {
    switch (status) {
      case 'accepted':
        return const Text(
          'Head to the pickup location',
          style: TextStyle(color: Colors.grey),
        );
      case 'arrived':
        return const Text(
          'Waiting for rider to get in',
          style: TextStyle(color: Colors.grey),
        );
      case 'started':
        return const Text(
          'Driving to destination',
          style: TextStyle(color: Colors.grey),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRiderInfo(RideModel ride) {
    return FutureBuilder<DocumentSnapshot>(
      future: controller.firebaseService.document('users/${ride.riderId}').get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final riderData = snapshot.data!.data() as Map<String, dynamic>?;

        if (riderData == null) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rider',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: riderData['profileImageUrl'] != null
                        ? NetworkImage(riderData['profileImageUrl'])
                        : null,
                    child: riderData['profileImageUrl'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          riderData['fullName'] ?? 'Rider',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        if (riderData['phoneNumber'] != null)
                          Text(
                            riderData['phoneNumber'],
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.phone),
                        color: AppTheme.primaryColor,
                        onPressed: () {
                          // TODO: Implement call functionality
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat),
                        color: AppTheme.primaryColor,
                        onPressed: () {
                          Get.toNamed(
                            Routes.chat,
                            arguments: {
                              'rideId': ride.id,
                              'receiverId': ride.riderId,
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildRideInfoCard(RideModel ride) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Pickup
          _buildLocationItem(
            icon: Icons.location_on,
            iconColor: Colors.red,
            iconBgColor: Colors.red.withOpacity(0.1),
            title: 'Pickup',
            name: ride.pickup?.name ?? 'Pickup Location',
            address: ride.pickup?.address ?? '',
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: SizedBox(
              height: 20,
              child: VerticalDivider(
                color: Colors.grey,
                thickness: 1,
                width: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Dropoff
          _buildLocationItem(
            icon: Icons.location_on,
            iconColor: Colors.blue,
            iconBgColor: Colors.blue.withOpacity(0.1),
            title: 'Dropoff',
            name: ride.dropoff?.name ?? 'Dropoff Location',
            address: ride.dropoff?.address ?? '',
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          // Ride details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRideInfoItem(
                icon: Icons.directions_car,
                title: 'Ride Type',
                value: ride.rideType,
              ),
              _buildRideInfoItem(
                icon: Icons.route,
                title: 'Distance',
                value: '${ride.distance.toStringAsFixed(1)} km',
              ),
              _buildRideInfoItem(
                icon: Icons.access_time,
                title: 'Duration',
                value: '${ride.duration.toStringAsFixed(0)} min',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          // Payment
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Method',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              Text(
                ride.paymentMethod.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fare',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
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
    );
  }

  Widget _buildLocationItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String name,
    required String address,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                address,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Set<Marker> _buildRideMarkers(RideModel ride) {
    Set<Marker> markers = {};

    if (ride.pickup != null) {
      final LatLng pickupLatLng = LatLng(
        ride.pickup!.latitude,
        ride.pickup!.longitude,
      );

      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickupLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'Pickup', snippet: ride.pickup!.name),
        ),
      );
    }

    if (ride.dropoff != null) {
      final LatLng dropoffLatLng = LatLng(
        ride.dropoff!.latitude,
        ride.dropoff!.longitude,
      );

      markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoffLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: 'Dropoff', snippet: ride.dropoff!.name),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildRidePolylines(RideModel ride) {
    Set<Polyline> polylines = {};

    if (ride.pickup != null && ride.dropoff != null) {
      final LatLng pickupLatLng = LatLng(
        ride.pickup!.latitude,
        ride.pickup!.longitude,
      );

      final LatLng dropoffLatLng = LatLng(
        ride.dropoff!.latitude,
        ride.dropoff!.longitude,
      );

      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [pickupLatLng, dropoffLatLng],
          color: Colors.blue,
          width: 5,
        ),
      );
    }

    return polylines;
  }

  Widget _buildRideInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.blue;
      case 'arrived':
        return Colors.green;
      case 'started':
        return AppTheme.primaryColor;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.directions_car;
      case 'arrived':
        return Icons.location_on;
      case 'started':
        return Icons.navigation;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'accepted':
        return 'Heading to Pickup';
      case 'arrived':
        return 'Arrived at Pickup';
      case 'started':
        return 'Ride in Progress';
      case 'completed':
        return 'Ride Completed';
      default:
        return 'Unknown Status';
    }
  }

  Widget _buildActionButton(String status) {
    switch (status) {
      case 'accepted':
        return AnimatedButton(
          onPressed: controller.arrivedAtPickup,
          color: Colors.orange,
          child: const Text('Arrived at Pickup'),
        );
      case 'arrived':
        return AnimatedButton(
          onPressed: controller.startRide,
          color: Colors.green,
          child: const Text('Start Ride'),
        );
      case 'started':
        return Obx(() => controller.isCompletingRide.value
            ? Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
              const SizedBox(width: 10),
              const Text('Waiting for payment...', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        )
            : AnimatedButton(
          onPressed: controller.completeRide,
          child: const Text('Complete Ride'),
        )
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

  void _showPaymentCompletedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('Payment Received'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('The rider has completed the payment for this trip.'),
              const SizedBox(height: 10),
              Text(
                '\$${controller.currentRide.value?.fare.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.acknowledgePayment();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Return to Home'),
            ),
          ],
        );
      },
    );
  }
}
