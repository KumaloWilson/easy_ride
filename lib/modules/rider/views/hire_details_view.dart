import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/models/hire_vehicle_model.dart';
import 'package:easy_ride/models/vehicle_hire_model.dart';
import 'package:easy_ride/modules/rider/controllers/vehicle_hire_controller.dart';

class HireDetailsView extends StatefulWidget {
  final String hireId;

  const HireDetailsView({Key? key, required this.hireId}) : super(key: key);

  @override
  State<HireDetailsView> createState() => _HireDetailsViewState();
}

class _HireDetailsViewState extends State<HireDetailsView> {
  final VehicleHireController controller = Get.find<VehicleHireController>();
  VehicleHireModel? hire;
  HireVehicleModel? vehicle;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHireDetails();
  }

  Future<void> _loadHireDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      final hireDetails = await controller.getHireDetails(widget.hireId);
      if (hireDetails != null) {
        hire = hireDetails;
        
        // Load vehicle details
        final vehicleDetails = await controller.getVehicleDetails(hireDetails.vehicleId);
        if (vehicleDetails != null) {
          vehicle = vehicleDetails;
        }
      }
    } catch (e) {
      print('Error loading hire details: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hire Details'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hire == null
              ? const Center(child: Text('Hire not found'))
              : _buildHireDetails(context),
    );
  }

  Widget _buildHireDetails(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map showing pickup location and stops
          SizedBox(
            height: 200,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: hire!.pickupLocation.latLng,
                zoom: 14,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('pickup'),
                  position: hire!.pickupLocation.latLng,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                  infoWindow: const InfoWindow(title: 'Pickup Location'),
                ),
                ...hire!.stops.asMap().entries.map((entry) {
                  final index = entry.key;
                  final stop = entry.value;
                  return Marker(
                    markerId: MarkerId('stop_$index'),
                    position: stop.latLng,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    infoWindow: InfoWindow(title: 'Stop ${index + 1}'),
                  );
                }),
              },
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
            ),
          ),
          
          // Status and actions
          Container(
            padding: const EdgeInsets.all(16),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildStatusBadge(hire!.status),
                  ],
                ),
                if (hire!.status == HireStatus.pending || hire!.status == HireStatus.approved)
                  ElevatedButton(
                    onPressed: () => _showCancelConfirmation(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Cancel Hire'),
                  ),
                if (hire!.status == HireStatus.completed && hire!.rating == null)
                  ElevatedButton(
                    onPressed: () => _showRatingDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Rate Experience'),
                  ),
              ],
            ),
          ),
          
          // Vehicle details
          if (vehicle != null) _buildVehicleDetails(),
          
          // Hire details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hire Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Purpose', hire!.formattedPurpose),
                if (hire!.purposeDescription.isNotEmpty)
                  _buildDetailRow('Description', hire!.purposeDescription),
                _buildDetailRow(
                  'Start Time',
                  DateFormat('MMM dd, yyyy - hh:mm a').format(hire!.startTime),
                ),
                _buildDetailRow(
                  'End Time',
                  DateFormat('MMM dd, yyyy - hh:mm a').format(hire!.endTime),
                ),
                _buildDetailRow('Duration', hire!.formattedDuration),
                _buildDetailRow('Self Drive', hire!.selfDrive ? 'Yes' : 'No'),
                _buildDetailRow('Return to Origin', hire!.returnToOrigin ? 'Yes' : 'No'),
                if (hire!.isRecurring)
                  _buildDetailRow('Recurring', 'Yes'),
                if (hire!.recurringPattern != null)
                  _buildDetailRow('Recurring Pattern', _formatRecurringPattern(hire!.recurringPattern!)),
                
                const Divider(height: 32),
                
                // Payment details
                const Text(
                  'Payment Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Total Cost', '\$${hire!.totalCost.toStringAsFixed(2)}'),
                _buildDetailRow('Payment Method', hire!.paymentMethod.capitalize!),
                _buildDetailRow('Paid', hire!.isPaid ? 'Yes' : 'No'),
                
                if (hire!.rating != null) ...[
                  const Divider(height: 32),
                  
                  // Rating
                  const Text(
                    'Your Rating',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < (hire!.rating ?? 0) ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 24,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        '${hire!.rating?.toStringAsFixed(1) ?? 0}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  if (hire!.feedback != null && hire!.feedback!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      hire!.feedback!,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDetails() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vehicle',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  vehicle!.photos[0],
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.directions_car,
                        size: 40,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle!.make} ${vehicle!.model}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${vehicle!.year} • ${vehicle!.color}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
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
                          '${vehicle!.rating?.toStringAsFixed(1)} (${vehicle!.ratingCount} ratings)',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFeatureChip(Icons.people, '${vehicle!.passengerCapacity} seats'),
              if (vehicle!.airConditioned != null)
                _buildFeatureChip(Icons.ac_unit, 'A/C'),
              _buildFeatureChip(Icons.luggage, '${vehicle!.luggageCapacity} bags'),
              _buildFeatureChip(Icons.settings, vehicle!.transmissionType.toString().split('.').last),
            ],
          ),
        ],
      ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[700],
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRecurringPattern(String pattern) {
    if (pattern == 'DAILY') {
      return 'Every day';
    } else if (pattern.startsWith('WEEKLY:')) {
      final day = int.tryParse(pattern.split(':')[1]);
      switch (day) {
        case 1: return 'Every Monday';
        case 2: return 'Every Tuesday';
        case 3: return 'Every Wednesday';
        case 4: return 'Every Thursday';
        case 5: return 'Every Friday';
        case 6: return 'Every Saturday';
        case 7: return 'Every Sunday';
        default: return 'Weekly';
      }
    }
    return pattern;
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
              Get.back();
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

  void _showRatingDialog(BuildContext context) {
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
              controller.rateHire(hire!.id, rating, feedbackController.text);
              setState(() {
                hire = hire!.copyWith(
                  rating: rating,
                  feedback: feedbackController.text,
                );
              });
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
