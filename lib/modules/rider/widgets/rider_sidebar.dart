import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/modules/rider/controllers/rider_controller.dart';
import 'package:easy_ride/modules/rider/views/ride_history_view.dart';
import 'package:easy_ride/modules/profile/views/profile_view.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../views/saved_places.dart';

class RiderSidebar extends StatelessWidget {
  final RiderController controller = Get.find<RiderController>();

  RiderSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _buildMenuItems(context),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    ).animate().slideX(
      begin: -1,
      end: 0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutQuad,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
      ),
      child: Column(
        children: [
          Obx(() {
            final user = controller.userProfile.value;

            return Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryColor,
                  child: user?.profileImageUrl != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.network(
                      user!.profileImageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person, color: Colors.white, size: 30);
                      },
                    ),
                  )
                      : const Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Rider',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'rider@example.com',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              Get.back();
              Get.to(() => ProfileView());
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('View Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildMenuItem(
          icon: Icons.home,
          title: 'Home',
          onTap: () {
            Get.back();
          },
        ),
        _buildMenuItem(
          icon: Icons.history,
          title: 'Ride History',
          onTap: () {
            Get.back();
            Get.to(() => RideHistoryView());
          },
        ),
        _buildMenuItem(
          icon: Icons.location_on,
          title: 'Saved Places',
          onTap: () {
            Get.back();
            Get.to(() => SavedPlacesView());
          },
        ),
        _buildMenuItem(
          icon: Icons.payment,
          title: 'Payment Methods',
          onTap: () {
            Get.back();
            Get.snackbar(
              'Coming Soon',
              'Payment methods feature is coming soon!',
              snackPosition: SnackPosition.BOTTOM,
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.support_agent,
          title: 'Support',
          onTap: () {
            Get.back();
            Get.snackbar(
              'Coming Soon',
              'Support feature is coming soon!',
              snackPosition: SnackPosition.BOTTOM,
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.settings,
          title: 'Settings',
          onTap: () {
            Get.back();
            Get.snackbar(
              'Coming Soon',
              'Settings feature is coming soon!',
              snackPosition: SnackPosition.BOTTOM,
            );
          },
        ),
        const Divider(),
        _buildMenuItem(
          icon: Icons.info_outline,
          title: 'About',
          onTap: () {
            Get.back();
            _showAboutDialog(context);
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Get.back();
              _showLogoutConfirmation(context);
            },
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Easy Ride'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 80,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.directions_car, size: 80);
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Easy Ride v1.0.0',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'A modern ride-hailing application designed for convenience and safety.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '© 2023 Easy Ride Inc. All rights reserved.',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Implement logout functionality
              Get.snackbar(
                'Logged Out',
                'You have been successfully logged out',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
