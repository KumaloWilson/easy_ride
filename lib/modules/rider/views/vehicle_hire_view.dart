import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/modules/rider/controllers/vehicle_hire_controller.dart';
import 'package:easy_ride/models/hire_vehicle_model.dart';
import 'package:easy_ride/modules/rider/widgets/vehicle_card.dart';

import '../../../models/vehicle_hire_model.dart';

class VehicleHireView extends StatelessWidget {
  final VehicleHireController controller = Get.put(VehicleHireController());

  VehicleHireView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hire a Vehicle'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.currentHire.value != null) {
          // Show active hire
          return _buildActiveHireView(context);
        } else {
          // Show vehicle selection
          return _buildVehicleSelectionView(context);
        }
      }),
    );
  }

  Widget _buildVehicleSelectionView(BuildContext context) {
    return Column(
      children: [
        _buildVehicleTypeSelector(),
        Expanded(
          child: Obx(() {
            if (controller.isLoadingVehicles.value) {
              return const Center(child: CircularProgressIndicator());
            }  {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.availableVehicles.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.car_rental, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No vehicles available',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Try changing the vehicle type or check back later',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => controller.fetchAvailableVehicles(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.availableVehicles.length,
              itemBuilder: (context, index) {
                final vehicle = controller.availableVehicles[index];
                return VehicleCard(
                  vehicle: vehicle,
                  onTap: () => controller.selectVehicle(vehicle),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildVehicleTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildVehicleTypeOption(HireVehicleType.car, 'Car', Icons.directions_car),
            _buildVehicleTypeOption(HireVehicleType.van, 'Van', Icons.airport_shuttle),
            _buildVehicleTypeOption(HireVehicleType.luxury, 'Luxury', Icons.star),
            _buildVehicleTypeOption(HireVehicleType.suv, 'SUV', Icons.directions_car),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleTypeOption(HireVehicleType type, String name, IconData icon) {
    return Obx(() {
      final isSelected = controller.selectedVehicleType.value == type;

      return GestureDetector(
        onTap: () => controller.setVehicleType(type),
        child: Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primaryColor : Colors.black87,
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppTheme.primaryColor : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildActiveHireView(BuildContext context) {
    final hire = controller.currentHire.value!;
    
    return Column(
      children: [
        // Map showing vehicle location
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: controller.vehicleLocation.value ?? 
                          controller.currentLocation.value,
                  zoom: 15,
                ),
                markers: controller.markers,
                polylines: controller.polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: true,
                onMapCreated: controller.onMapCreated,
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  heroTag: 'currentLocationBtn',
                  backgroundColor: Colors.white,
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.black87,
                  ),
                  onPressed: () {
                    if (controller.vehicleLocation.value != null && 
                        controller.mapController.value != null) {
                      controller.mapController.value!.animateCamera(
                        CameraUpdate.newLatLngZoom(controller.vehicleLocation.value!, 15),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Hire details
        Expanded(
          flex: 2,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hire Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    _buildStatusBadge(hire.status),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Purpose', hire.formattedPurpose),
                        _buildInfoRow('Duration', hire.formattedDuration),
                        _buildInfoRow('Pickup', hire.pickupLocation.name),
                        if (hire.stops.isNotEmpty)
                          _buildInfoRow('Stops', '${hire.stops.length} stops'),
                        _buildInfoRow('Total Cost', '\$${hire.totalCost.toStringAsFixed(2)}'),
                        _buildInfoRow('Payment', hire.paymentMethod.capitalize!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (hire.status == HireStatus.pending || hire.status == HireStatus.approved)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showCancelConfirmation(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel Hire'),
                    ),
                  ),
                if (hire.status == HireStatus.completed && hire.rating == null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showRatingDialog(context, hire.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Rate Your Experience'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(HireStatus status) {
    Color color;
    String text;

    switch (status) {
      case HireStatus.pending:
        color = Colors.orange;
        text = 'Pending Approval';
        break;
      case HireStatus.approved:
        color = Colors.blue;
        text = 'Approved';
        break;
      case HireStatus.active:
        color = Colors.green;
        text = 'Active';
        break;
      case HireStatus.completed:
        color = Colors.purple;
        text = 'Completed';
        break;
      case HireStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
      case HireStatus.rejected:
        color = Colors.red;
        text = 'Rejected';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Hire'),
        content: const Text('Are you sure you want to cancel this vehicle hire?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              controller.cancelHire();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context, String hireId) {
    double rating = 5.0;
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Your Experience'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How would you rate your vehicle hire experience?'),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 36,
                      ),
                      onPressed: () {
                        setState(() {
                          rating = index + 1.0;
                        });
                      },
                    );
                  }),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              decoration: const InputDecoration(
                labelText: 'Feedback (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              controller.rateHire(hireId, rating, feedbackController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
