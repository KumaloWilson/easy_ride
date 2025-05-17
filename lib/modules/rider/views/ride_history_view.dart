import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_ride/models/ride_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../models/ride_status.dart';
import '../controllers/rider_controller.dart';

class RideHistoryView extends StatefulWidget {
  const RideHistoryView({super.key});

  @override
  State<RideHistoryView> createState() => _RideHistoryViewState();
}

class _RideHistoryViewState extends State<RideHistoryView> {
  final RiderController controller = Get.find<RiderController>();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMoreRides = true;
  final int _pageSize = 10;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadRides();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!_isLoading && _hasMoreRides) {
        _loadMoreRides();
      }
    }
  }

  Future<void> _loadRides() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await controller.fetchRideHistory();
      setState(() {
        _hasMoreRides = controller.rideHistory.length >= _pageSize;
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load ride history: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreRides() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _currentPage++;
    });

    try {
      // In a real app, you would pass the page number to fetch more rides
      // For this example, we'll just simulate it
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _hasMoreRides = false; // No more rides for this example
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load more rides: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      setState(() {
        _currentPage--; // Revert page increment on failure
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshRides() async {
    setState(() {
      _currentPage = 1;
      _hasMoreRides = true;
    });
    await _loadRides();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride History'),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshRides,
        child: Obx(() {
          final rides = controller.rideHistory;
          
          if (rides.isEmpty && !_isLoading) {
            return _buildEmptyState();
          }
          
          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: rides.length + (_isLoading && _hasMoreRides ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == rides.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              return _buildRideHistoryCard(context, rides[index], index);
            },
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/empty_list.json',
            width: 200,
            height: 200,
          ),
          const Text(
            'No ride history yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your completed rides will appear here',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Book a Ride'),
          ),
        ],
      ),
    );
  }

  Widget _buildRideHistoryCard(BuildContext context, RideModel ride, int index) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final formattedDate = dateFormat.format(
      ride.createdAt != null
          ? (ride.createdAt as Timestamp).toDate()
          : DateTime.now()
    );
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: InkWell(
          onTap: () => _showRideDetails(context, ride),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedDate,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    _buildStatusBadge(context, ride.status ?? 'completed'),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLocationRow(
                  context,
                  Icons.my_location,
                  ride.pickup?.name ?? 'Unknown pickup',
                ),
                const SizedBox(height: 8),
                _buildDivider(),
                const SizedBox(height: 8),
                _buildLocationRow(
                  context,
                  Icons.location_on,
                  ride.pickup?.name ?? 'Unknown destination',
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ride.rideType ?? 'Standard',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '\$${(ride.fare ?? 0.0).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'completed':
        color = Colors.green;
        text = 'Completed';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Cancelled';
        break;
      case 'started':
        color = Colors.blue;
        text = 'In Progress';
        break;
      default:
        color = Colors.orange;
        text = status.capitalize ?? 'Unknown';
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

  Widget _buildLocationRow(
    BuildContext context,
    IconData icon,
    String address,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: icon == Icons.my_location ? Colors.green : AppTheme.primaryColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            address,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const SizedBox(width: 10),
        Container(
          width: 2,
          height: 30,
          color: Colors.grey[300],
        ),
      ],
    );
  }

  void _showRideDetails(BuildContext context, RideModel ride) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                Text(
                  'Ride Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(context, 'Date & Time', 
                  DateFormat('MMM dd, yyyy • hh:mm a').format(
                    ride.createdAt != null
                        ? (ride.createdAt as Timestamp).toDate()
                        : DateTime.now()
                  )),
                const SizedBox(height: 8),
                _buildDetailRow(context, 'Status', 
                  (ride.status ?? 'Unknown').toString().capitalize ?? 'Unknown'),
                const SizedBox(height: 8),
                _buildDetailRow(context, 'Ride Type', 
                  ride.rideType ?? 'Standard'),
                const SizedBox(height: 8),
                _buildDetailRow(context, 'Fare', 
                  '\$${(ride.fare ?? 0.0).toStringAsFixed(2)}'),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Pickup Location',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(ride.pickup?.name ?? 'Unknown pickup'),
                const SizedBox(height: 16),
                Text(
                  'Dropoff Location',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(ride.dropoff?.name ?? 'Unknown destination'),
                const SizedBox(height: 24),
                if (ride.status == 'completed')
                  _buildReceiptButton(context, ride),
                const SizedBox(height: 16),
                if (ride.driverId != null && ride.status == 'completed')
                  _buildDriverInfo(ride.driverId!),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Widget _buildReceiptButton(BuildContext context, RideModel ride) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Show receipt
          Get.snackbar(
            'Receipt',
            'Viewing receipt for ride ${ride.id}',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
        icon: const Icon(Icons.receipt_long),
        label: const Text('View Receipt'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDriverInfo(String driverId) {
    // In a real app, you would fetch driver details
    // For this example, we'll use placeholder data
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Driver Information',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const CircleAvatar(
              radius: 30,
              child: Icon(Icons.person, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'John Driver',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
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
                        '4.8',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
