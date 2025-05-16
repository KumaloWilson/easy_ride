import 'package:flutter/material.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

class ETACard extends StatelessWidget {
  final double distanceToPickup; // in km
  final double durationToPickup; // in minutes
  final double? distanceToDestination; // in km
  final double? durationToDestination; // in minutes
  final String status; // 'searching', 'accepted', 'arrived', 'started', 'completed'
  final VoidCallback? onCancel;
  final String? title;
  final String? subtitle;
  final bool isArrived;

  const ETACard({
    Key? key,
    required this.distanceToPickup,
    required this.durationToPickup,
    this.distanceToDestination,
    this.durationToDestination,
    required this.status,
    this.onCancel,
    this.title,
    this.subtitle,
    this.isArrived = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title ?? _getStatusText(status),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(status),
                        ),
                      ),
                      Text(
                        subtitle ?? _getStatusDescription(status),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (status == 'searching' || status == 'accepted')
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // ETA information
            if (status == 'searching')
              Center(
                child: Column(
                  children: [
                    SizedBox(
                      height: 80,
                      width: 80,
                      child: Lottie.asset(
                        'assets/lottie/searching.json',
                        repeat: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Looking for nearby drivers...',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else if (status == 'accepted' || status == 'arrived')
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildETAItem(
                        icon: Icons.location_on,
                        title: 'Distance',
                        value: '${distanceToPickup.toStringAsFixed(1)} km',
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.grey[300],
                      ),
                      _buildETAItem(
                        icon: Icons.access_time,
                        title: 'ETA',
                        value: '${durationToPickup.toStringAsFixed(0)} min',
                        isHighlighted: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    status == 'accepted'
                        ? 'Driver is on the way to pick you up'
                        : 'Driver has arrived at your location',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              )
            else if (status == 'started')
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildETAItem(
                          icon: Icons.location_on,
                          title: 'Distance',
                          value: '${distanceToDestination?.toStringAsFixed(1) ?? "0.0"} km',
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey[300],
                        ),
                        _buildETAItem(
                          icon: Icons.access_time,
                          title: 'ETA',
                          value: '${durationToDestination?.toStringAsFixed(0) ?? "0"} min',
                          isHighlighted: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'You are on your way to the destination',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              else if (status == 'completed')
                  Center(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 80,
                          width: 80,
                          child: Lottie.asset(
                            'assets/lottie/completed.json',
                            repeat: false,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ride completed successfully!',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    ).animate().custom(
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) => Transform.scale(
        scale: 0.9 + (0.1 * value),
        child: Opacity(
          opacity: value,
          child: child,
        ),
      ),
    );
  }

  Widget _buildETAItem({
    required IconData icon,
    required String title,
    required String value,
    bool isHighlighted = false,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: isHighlighted ? AppTheme.primaryColor : Colors.grey[600],
          size: 24,
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isHighlighted ? AppTheme.primaryColor : null,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'searching':
        return Colors.orange;
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
      case 'searching':
        return Icons.search;
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
      case 'searching':
        return 'Finding a driver';
      case 'accepted':
        return 'Driver on the way';
      case 'arrived':
        return 'Driver arrived';
      case 'started':
        return 'Ride in progress';
      case 'completed':
        return 'Ride completed';
      default:
        return 'Unknown status';
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'searching':
        return 'Please wait while we find a driver for you';
      case 'accepted':
        return 'Your driver is heading to your location';
      case 'arrived':
        return 'Your driver is waiting for you';
      case 'started':
        return 'You are on your way to the destination';
      case 'completed':
        return 'Thank you for riding with us';
      default:
        return '';
    }
  }
}
