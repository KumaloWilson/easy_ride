import 'package:flutter/material.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/models/user_model.dart';
import 'package:easy_ride/models/driver_model.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DriverProfileCard extends StatelessWidget {
  final UserModel user;
  final DriverModel driver;
  final VoidCallback? onCallDriver;
  final VoidCallback? onMessageDriver;
  final VoidCallback? onClose;
  final bool isDetailed;
  final bool isAnimated;

  const DriverProfileCard({
    Key? key,
    required this.user,
    required this.driver,
    this.onCallDriver,
    this.onMessageDriver,
    this.onClose,
    this.isDetailed = false,
    this.isAnimated = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Widget card = Card(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Driver',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Driver info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile image
                Hero(
                  tag: 'driver_profile_${user.id}',
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: user.profileImageUrl != null
                        ? CachedNetworkImageProvider(user.profileImageUrl!)
                        : null,
                    child: user.profileImageUrl == null
                        ? const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.grey,
                    )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),

                // Driver details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName ?? 'Driver',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Rating
                      Row(
                        children: [
                          RatingBar.builder(
                            initialRating: driver.rating ?? 0,
                            minRating: 0,
                            direction: Axis.horizontal,
                            allowHalfRating: true,
                            itemCount: 5,
                            itemSize: 16,
                            ignoreGestures: true,
                            itemBuilder: (context, _) => const Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            onRatingUpdate: (_) {},
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${driver.rating?.toStringAsFixed(1) ?? 'N/A'} (${driver.completedRides} rides)',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Contact buttons
                      Row(
                        children: [
                          if (onCallDriver != null)
                            _buildContactButton(
                              icon: Icons.phone,
                              label: 'Call',
                              onTap: onCallDriver!,
                            ),
                          const SizedBox(width: 8),
                          if (onMessageDriver != null)
                            _buildContactButton(
                              icon: Icons.message,
                              label: 'Message',
                              onTap: onMessageDriver!,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Vehicle details
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vehicle Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Vehicle info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getVehicleIcon(driver.vehicleType),
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${driver.vehicleColor} ${driver.vehicleModel}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'License Plate: ${driver.licensePlate}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Additional details for detailed view
            if (isDetailed) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Safety tips
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Safety Tips',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSafetyTip(
                    icon: Icons.verified_user,
                    tip: 'Verify the license plate before getting in',
                  ),
                  const SizedBox(height: 8),
                  _buildSafetyTip(
                    icon: Icons.share_location,
                    tip: 'Share your trip details with a friend',
                  ),
                  const SizedBox(height: 8),
                  _buildSafetyTip(
                    icon: Icons.phone_in_talk,
                    tip: 'Keep your phone charged and accessible',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    if (!isAnimated) {
      return card;
    }

    return card.animate().custom(
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

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyTip({
    required IconData icon,
    required String tip,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.infoColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppTheme.infoColor,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            tip,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'suv':
        return Icons.directions_car;
      case 'sedan':
        return Icons.directions_car;
      case 'hatchback':
        return Icons.directions_car;
      case 'van':
        return Icons.airport_shuttle;
      case 'bike':
        return Icons.motorcycle;
      default:
        return Icons.directions_car;
    }
  }
}
