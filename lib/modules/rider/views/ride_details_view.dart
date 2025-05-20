import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/ride_model.dart';
import '../../../models/ride_status.dart';
import '../../../routes/app_pages.dart';
import '../controllers/rider_controller.dart';

class RideDetailsView extends StatelessWidget {
  final RiderController controller = Get.find<RiderController>();

  RideDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _buildMap(),
            _buildTopBar(context),
            _buildBottomSheet(context),
            _buildEmergencyButton(),
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
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Get.back(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Obx(() {
              final rideStatus = controller.rideStatus.value;
              return Text(
                _getRideStatusText(rideStatus),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              );
            }),
          ),
          const SizedBox(width: 48), // Balance for back button
        ],
      ),
    );
  }

  String _getRideStatusText(String status) {
    switch (status) {
      case 'requested':
      case 'pending':
        return 'Finding Driver';
      case 'accepted':
        return 'Driver Coming';
      case 'arrived':
        return 'Driver Arrived';
      case 'started':
        return 'Ride in Progress';
      case 'completed':
        return 'Ride Completed';
      case 'cancelled':
        return 'Ride Cancelled';
      default:
        return 'Ride Details';
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
              child: Obx(() {
                final ride = controller.currentRide.value;
                if (ride == null) {
                  return const Center(
                    child: Text('No active ride found'),
                  );
                }

                return Column(
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
                    _buildRideInfo(context, ride),
                    const SizedBox(height: 16),
                    _buildDriverInfo(context),
                    const SizedBox(height: 24),
                    _buildActionButtons(context),
                    const SizedBox(height: 16),
                    _buildETACard(context),
                    const SizedBox(height: 24),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRideInfo(BuildContext context, RideModel ride) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ride Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildLocationRow(
            context,
            Icons.my_location,
            'Pickup',
            ride.pickup?.name ?? 'Unknown location',
          ),
          const SizedBox(height: 8),
          _buildLocationRow(
            context,
            Icons.location_on,
            'Dropoff',
            ride.dropoff?.name ?? 'Unknown location',
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(
                context,
                'Ride Type',
                ride.rideType ?? 'Standard',
              ),
              _buildInfoItem(
                context,
                'Fare',
                '\$${(ride.fare ?? 0.0).toStringAsFixed(2)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(
    BuildContext context,
    IconData icon,
    String label,
    String address,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: label == 'Pickup' ? Colors.green : AppTheme.primaryColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              Text(
                address,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildDriverInfo(BuildContext context) {
    final driverInfo = controller.driverInfo.value;
    
    if (controller.rideStatus.value == 'pending' || 
        controller.rideStatus.value == 'requested') {
      return Center(
        child: Column(
          children: [
            Lottie.asset(
              'assets/animations/searching_driver.json',
              width: 150,
              height: 150,
            ),
            const Text('Searching for a driver...'),
          ],
        ),
      );
    }

    if (driverInfo == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Driver Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: driverInfo.user.profileImageUrl != null
                    ? NetworkImage(driverInfo.user.profileImageUrl!)
                    : null,
                child: driverInfo.user.profileImageUrl == null
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverInfo.user.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      driverInfo.vehicle.model ?? 'Vehicle',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${driverInfo.rating ?? 4.5}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.phone, color: Colors.green),
                    onPressed: () {
                      _callDriver(driverInfo.user.phoneNumber);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.message, color: AppTheme.primaryColor),
                    onPressed: () {
                      _messageDriver();
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _callDriver(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      Get.snackbar(
        'Error',
        'Driver phone number not available',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      Get.snackbar(
        'Error',
        'Could not launch phone app',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _messageDriver() {
    final ride = controller.currentRide.value;
    if (ride == null) return;
    
    Get.toNamed('/chat/${ride.id}');
  }

  Widget _buildActionButtons(BuildContext context) {
    final status = controller.rideStatus.value;
    
    if (status == 'completed') {
      return Column(
        children: [
          ElevatedButton(
            onPressed: () {
              _showRateDriverDialog(context);
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
              'Rate Driver',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text('Back to Home'),
          ),
        ],
      );
    }

    if (status == 'cancelled') {
      return ElevatedButton(
        onPressed: () {
          Get.back();
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
          'Back to Home',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: () {
        _showCancelRideDialog(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: const Text(
        'Cancel Ride',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showCancelRideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Ride'),
          content: const Text(
            'Are you sure you want to cancel this ride? Cancellation fees may apply.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.cancelRide();
                Get.back();
              },
              child: const Text(
                'Yes, Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRateDriverDialog(BuildContext context) {
    // First show payment confirmation
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _buildPaymentConfirmationSheet(context);
      },
    );
  }

  Widget _buildPaymentConfirmationSheet(BuildContext context) {
    final ride = controller.currentRide.value;
    if (ride == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.payment, color: AppTheme.primaryColor, size: 28),
              const SizedBox(width: 12),
              Text(
                'Trip Payment',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Base Fare',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '\$${((ride.fare ?? 0) * 0.8).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Distance (${ride.distance.toStringAsFixed(1)} km)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '\$${((ride.fare ?? 0) * 0.15).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Time (${ride.duration.toStringAsFixed(0)} min)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '\$${((ride.fare ?? 0) * 0.05).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '\$${(ride.fare ?? 0).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Payment Method',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    ride.paymentMethod == 'cash' ? Icons.money : Icons.credit_card,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.paymentMethod == 'cash' ? 'Cash' : 'Credit Card',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (ride.paymentMethod != 'cash')
                        Text(
                          'Ending in 1234',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Radio(
                  value: true,
                  groupValue: true,
                  onChanged: (_) {},
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Obx(() => SizedBox(
            width: double.infinity,
            child: controller.isProcessingPayment.value
              ? Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
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
                        const Text('Processing payment...', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                )
              : ElevatedButton(
                  onPressed: () {
                    controller.isProcessingPayment.value = true;
                    
                    // Simulate payment processing
                    Future.delayed(const Duration(seconds: 2), () {
                      // Update ride as paid
                      controller.markRideAsPaid(ride.id);
                      
                      // Dismiss payment sheet
                      Navigator.pop(context);
                      
                      // Show success animation
                      _showPaymentSuccessAnimation(context);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Confirm Payment - \$${(ride.fare ?? 0).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
          )),
        ],
      ),
    );
  }

  void _showPaymentSuccessAnimation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 20),
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your payment has been processed successfully.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showDriverRatingDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Rate Your Driver'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDriverRatingDialog(BuildContext context) {
    double rating = 5.0;
    String feedback = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 28),
              SizedBox(width: 10),
              Text('Rate Your Driver'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How was your ride experience?'),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = index + 1;
                          });
                        },
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Additional feedback (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) {
                  feedback = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showThankYouDialog(context);
              },
              child: const Text('Skip'),
            ),
            Obx(() => controller.isSubmittingRating.value
              ? Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ),
                )
              : ElevatedButton(
                  onPressed: () {
                    controller.isSubmittingRating.value = true;
                    
                    // Submit rating with animation
                    Future.delayed(Duration(milliseconds: 800), () {
                      controller.rateDriver(controller.currentRide.value!.id, rating, feedback);
                      controller.isSubmittingRating.value = false;
                      Navigator.of(context).pop();
                      
                      // Show thank you dialog
                      _showThankYouDialog(context);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Submit'),
                ),
            ),
          ],
        );
      },
    );
  }

  void _showThankYouDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('Thank You!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/animations/thank_you.json',
                width: 150,
                height: 150,
                repeat: false,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your payment has been processed and your feedback has been submitted.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Return to home screen with animation
                Get.offAllNamed(Routes.riderHome,);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                minimumSize: Size(double.infinity, 45),
              ),
              child: const Text('Return to Home'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildETACard(BuildContext context) {
    final status = controller.rideStatus.value;
    
    if (status == 'completed' || status == 'cancelled') {
      return const SizedBox.shrink();
    }
    
    String title;
    String subtitle;
    double distance;
    double duration;
    
    if (status == 'accepted' || status == 'arrived') {
      title = 'Driver is on the way';
      subtitle = 'Arriving in ${_formatDuration(controller.durationToPickup.value)}';
      distance = controller.distanceToPickup.value;
      duration = controller.durationToPickup.value;
    } else if (status == 'started') {
      title = 'On the way to destination';
      subtitle = 'Arriving in ${_formatDuration(controller.durationToDestination.value)}';
      distance = controller.distanceToDestination.value;
      duration = controller.durationToDestination.value;
    } else {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.directions_car,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${distance.toStringAsFixed(1)} km',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
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

  Widget _buildEmergencyButton() {
    return Positioned(
      bottom: 350,
      right: 16,
      child: FloatingActionButton(
        backgroundColor: Colors.red,
        child: const Icon(Icons.emergency),
        onPressed: () {
          _showEmergencyOptions(Get.context!);
        },
      ),
    );
  }

  void _showEmergencyOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Emergency Options',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.local_police, color: Colors.blue),
                title: const Text('Contact Police'),
                onTap: () async {
                  Navigator.pop(context);
                  final Uri url = Uri.parse('tel:911');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.medical_services, color: Colors.red),
                title: const Text('Medical Emergency'),
                onTap: () async {
                  Navigator.pop(context);
                  final Uri url = Uri.parse('tel:911');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.support_agent, color: Colors.green),
                title: const Text('Contact Support'),
                onTap: () async {
                  Navigator.pop(context);
                  final Uri url = Uri.parse('tel:+18005551234');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.report_problem, color: Colors.orange),
                title: const Text('Report Driver'),
                onTap: () {
                  Navigator.pop(context);
                  _showReportDriverDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReportDriverDialog(BuildContext context) {
    String issue = '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Report Driver'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please describe the issue you\'re experiencing:',
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Describe the issue',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                onChanged: (value) {
                  issue = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (issue.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  controller.reportDriver(controller.currentRide.value!.id, issue, 'User reported issue during ride');
                  Get.snackbar(
                    'Report Submitted',
                    'Thank you for your report. We will investigate this issue.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
              child: const Text(
                'Submit Report',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
