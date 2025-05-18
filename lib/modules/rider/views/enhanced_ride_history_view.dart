import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_ride/models/ride_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/core/widgets/shimmer_loading.dart';
import 'package:easy_ride/models/ride_status.dart';
import 'package:easy_ride/modules/rider/controllers/rider_controller.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class EnhancedRideHistoryView extends StatefulWidget {
  const EnhancedRideHistoryView({super.key});

  @override
  State<EnhancedRideHistoryView> createState() => _EnhancedRideHistoryViewState();
}

class _EnhancedRideHistoryViewState extends State<EnhancedRideHistoryView> with SingleTickerProviderStateMixin {
  final RiderController controller = Get.find<RiderController>();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMoreRides = true;
  final int _pageSize = 10;
  int _currentPage = 1;
  late TabController _tabController;
  final List<String> _tabs = ['All', 'Completed', 'Cancelled'];
  final RxString _selectedFilter = 'All'.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadRides();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      _selectedFilter.value = _tabs[_tabController.index];
      _loadRides();
    }
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
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshRides,
        child: Obx(() {
          final rides = _filterRides(controller.rideHistory);
          
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showFilterOptions(context);
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.filter_list),
      ),
    );
  }

  List<RideModel> _filterRides(List<RideModel> rides) {
    switch (_selectedFilter.value) {
      case 'Completed':
        return rides.where((ride) => ride.status == 'completed').toList();
      case 'Cancelled':
        return rides.where((ride) => ride.status == 'cancelled').toList();
      default:
        return rides;
    }
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Rides',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Date Range',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Show date picker
                      },
                      child: const Text('Start Date'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Show date picker
                      },
                      child: const Text('End Date'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Ride Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Standard'),
                    selected: true,
                    onSelected: (selected) {},
                  ),
                  FilterChip(
                    label: const Text('Premium'),
                    selected: false,
                    onSelected: (selected) {},
                  ),
                  FilterChip(
                    label: const Text('XL'),
                    selected: false,
                    onSelected: (selected) {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        );
      },
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
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (context) {
                _showRideDetails(context, ride);
              },
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.info_outline,
              label: 'Details',
            ),
            SlidableAction(
              onPressed: (context) {
                // Implement repeat ride functionality
                _repeatRide(ride);
              },
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              icon: Icons.repeat,
              label: 'Repeat',
            ),
          ],
        ),
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
                    ride.dropoff?.name ?? 'Unknown destination',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.directions_car,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ride.rideType ?? 'Standard',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            ride.isPaid ? Icons.check_circle : Icons.pending,
                            size: 16,
                            color: ride.isPaid ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
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
                ],
              ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ride Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    _buildStatusBadge(context, ride.status ?? 'completed'),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(context, 'Date & Time', 
                        DateFormat('MMM dd, yyyy • hh:mm a').format(
                          ride.createdAt != null
                              ? (ride.createdAt as Timestamp).toDate()
                              : DateTime.now()
                        )),
                      const SizedBox(height: 12),
                      _buildDetailRow(context, 'Ride Type', 
                        ride.rideType ?? 'Standard'),
                      const SizedBox(height: 12),
                      _buildDetailRow(context, 'Payment Method', 
                        ride.paymentMethod.capitalize ?? 'Unknown'),
                      const SizedBox(height: 12),
                      _buildDetailRow(context, 'Payment Status', 
                        ride.isPaid ? 'Paid' : 'Pending'),
                      const SizedBox(height: 12),
                      _buildDetailRow(context, 'Distance', 
                        '${ride.distance.toStringAsFixed(1)} km'),
                      const SizedBox(height: 12),
                      _buildDetailRow(context, 'Duration', 
                        '${ride.duration.toStringAsFixed(0)} min'),
                      const SizedBox(height: 12),
                      _buildDetailRow(context, 'Fare', 
                        '\$${(ride.fare ?? 0.0).toStringAsFixed(2)}'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Route',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              const Icon(
                                Icons.my_location,
                                color: Colors.green,
                                size: 20,
                              ),
                              Container(
                                width: 2,
                                height: 30,
                                color: Colors.grey[300],
                              ),
                              Icon(
                                Icons.location_on,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pickup',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  ride.pickup?.name ?? 'Unknown pickup',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Dropoff',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  ride.dropoff?.name ?? 'Unknown destination',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (ride.status == 'completed')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Driver Rating',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < (ride.driverRating ?? 0)
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 24,
                                );
                              }),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${ride.driverRating ?? 0}/5',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (ride.driverFeedback != null && ride.driverFeedback!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Your Feedback',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(ride.driverFeedback!),
                      ],
                    ],
                  ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _repeatRide(ride);
                        },
                        icon: const Icon(Icons.repeat),
                        label: const Text('Repeat Ride'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showReceiptDialog(context, ride);
                        },
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('View Receipt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
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
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _repeatRide(RideModel ride) {
    // Set pickup and dropoff locations
    controller.setPickupLocation(ride.pickup!);
    controller.setDropoffLocation(ride.dropoff!);
    
    // Set ride type and payment method
    controller.selectedRideType.value = ride.rideType ?? 'Standard';
    controller.selectedPaymentMethod.value = ride.paymentMethod;
    
    // Navigate back to home screen
    Get.back();
    Get.snackbar(
      'Ride Repeated',
      'Your previous ride has been set up. You can now request it again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void _showReceiptDialog(BuildContext context, RideModel ride) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Receipt',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildReceiptRow(
                        'Base Fare',
                        '\$${((ride.fare ?? 0) * 0.8).toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 8),
                      _buildReceiptRow(
                        'Distance (${ride.distance.toStringAsFixed(1)} km)',
                        '\$${((ride.fare ?? 0) * 0.15).toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 8),
                      _buildReceiptRow(
                        'Time (${ride.duration.toStringAsFixed(0)} min)',
                        '\$${((ride.fare ?? 0) * 0.05).toStringAsFixed(2)}',
                      ),
                      const Divider(height: 24),
                      _buildReceiptRow(
                        'Total',
                        '\$${(ride.fare ?? 0).toStringAsFixed(2)}',
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Implement download receipt functionality
                      Get.snackbar(
                        'Receipt Downloaded',
                        'Your receipt has been saved to your device',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download Receipt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? AppTheme.primaryColor : null,
          ),
        ),
      ],
    );
  }
}
