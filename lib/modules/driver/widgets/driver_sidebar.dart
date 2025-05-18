import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/modules/driver/controllers/driver_controller.dart';
import 'package:easy_ride/routes/app_pages.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/driver.dart';

class DriverDrawer extends StatelessWidget {
  final DriverController controller;

  const DriverDrawer({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      elevation: 10,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildDriverStatus(),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildNavigationItems(),
                    const Divider(height: 32),
                    _buildSupportItems(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [

          GestureDetector(
            onTap: () {
              Navigator.pop(Get.context!); // Close drawer
              controller.setNavIndex(3); // Navigate to profile
            },
            child: CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
              backgroundImage: user?.photoURL != null
                  ? CachedNetworkImageProvider(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? const Icon(
                Icons.person,
                size: 30,
                color: AppTheme.primaryColor,
              )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                  controller.currentUser.value?.fullName ?? 'Driver',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                )),
                const SizedBox(height: 4),
                Obx(() => Text(
                  controller.currentUser.value?.email ?? '',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )),
                const SizedBox(height: 4),
                Obx(() => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: controller.isVerified.value
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    controller.isVerified.value
                        ? 'Verified Driver'
                        : 'Verification Pending',
                    style: TextStyle(
                      color: controller.isVerified.value
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Get.back,
          ),
        ],
      ),
    );
  }

  Widget _buildDriverStatus() {
    return Obx(() => Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: controller.driverStatus.value == DriverStatus.online
            ? Colors.green.withOpacity(0.1)
            : controller.driverStatus.value == DriverStatus.busy
            ? Colors.orange.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: controller.driverStatus.value == DriverStatus.online
              ? Colors.green.withOpacity(0.3)
              : controller.driverStatus.value == DriverStatus.busy
              ? Colors.orange.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            color: controller.driverStatus.value == DriverStatus.online
                ? Colors.green
                : controller.driverStatus.value == DriverStatus.busy
                ? Colors.orange
                : Colors.red,
            size: 12,
          ),
          const SizedBox(width: 8),
          Text(
            controller.driverStatus.value == DriverStatus.online
                ? 'You are Online'
                : controller.driverStatus.value == DriverStatus.busy
                ? 'You are Busy'
                : 'You are Offline',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: controller.driverStatus.value == DriverStatus.online
                  ? Colors.green
                  : controller.driverStatus.value == DriverStatus.busy
                  ? Colors.orange
                  : Colors.red,
            ),
          ),
          const Spacer(),
          Switch(
            value: controller.driverStatus.value != DriverStatus.offline,
            onChanged: (controller.driverStatus.value == DriverStatus.busy ||
                !controller.isVerified.value)
                ? null // Disable toggle when busy or not verified
                : (value) {
              controller.toggleOnlineStatus();
            },
            activeColor: controller.driverStatus.value == DriverStatus.busy
                ? Colors.orange
                : Colors.green,
          ),
        ],
      ),
    ));
  }

  Widget _buildNavigationItems() {
    return Column(
      children: [
        _buildNavItem(
          icon: Icons.map,
          title: 'Home',
          isSelected: controller.selectedNavIndex.value == 0,
          onTap: () {
            Navigator.pop(Get.context!); // Close drawer
            controller.setNavIndex(0);
          },
        ),
        _buildNavItem(
          icon: Icons.history,
          title: 'Ride History',
          isSelected: controller.selectedNavIndex.value == 1,
          onTap: () {
            Navigator.pop(Get.context!); // Close drawer
            controller.setNavIndex(1);
          },
        ),
        _buildNavItem(
          icon: Icons.account_balance_wallet,
          title: 'Earnings',
          isSelected: controller.selectedNavIndex.value == 2,
          onTap: () {
            Navigator.pop(Get.context!); // Close drawer
            controller.setNavIndex(2);
          },
        ),
        _buildNavItem(
          icon: Icons.description,
          title: 'Documents',
          onTap: () {
            Navigator.pop(Get.context!); // Close drawer
            Get.toNamed(Routes.driverDocumentUpload);
          },
        ),
        _buildNavItem(
          icon: Icons.verified_user,
          title: 'Driver Verification',
          onTap: () {
            Navigator.pop(Get.context!); // Close drawer
            Get.toNamed(Routes.driverVerification);
          },
        ),
        _buildNavItem(
          icon: Icons.person,
          title: 'Profile',
          isSelected: controller.selectedNavIndex.value == 3,
          onTap: () {
            Navigator.pop(Get.context!); // Close drawer
            controller.setNavIndex(3);
          },
        ),
      ],
    );
  }

  Widget _buildSupportItems() {
    return Column(
      children: [
        _buildNavItem(
          icon: Icons.help_outline,
          title: 'Help & Support',
          onTap: () {
            Navigator.pop(Get.context!); // Close drawer
            _showHelpSupportDialog();
          },
        ),
        _buildNavItem(
          icon: Icons.info_outline,
          title: 'About',
          onTap: () {
            Navigator.pop(Get.context!); // Close drawer
            _showAboutDialog();
          },
        ),
        _buildNavItem(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          onTap: () {
            Navigator.pop(Get.context!); // Close drawer
            _showPrivacyPolicyDialog();
          },
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[700],
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primaryColor : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(Get.context!); // Close drawer
          _confirmLogout();
        },
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showHelpSupportDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email Support'),
              subtitle: const Text('support@easyride.com'),
              onTap: () {
                Get.back();
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Call Support'),
              subtitle: const Text('+1 (555) 123-4567'),
              onTap: () {
                Get.back();
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Live Chat'),
              subtitle: const Text('Available 24/7'),
              onTap: () {
                Get.back();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('About Easy Ride'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Easy Ride is a ride-sharing platform that connects drivers with riders for a seamless transportation experience.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              'Version: 1.0.0',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              '© 2023 Easy Ride Inc. All rights reserved.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'This Privacy Policy describes how Easy Ride collects, uses, and discloses your personal information when you use our application.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'Information We Collect:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Personal information such as name, email, phone number\n'
                    '• Location data for ride coordination\n'
                    '• Payment information\n'
                    '• Device information',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'How We Use Your Information:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• To provide and improve our services\n'
                    '• To process payments\n'
                    '• To communicate with you\n'
                    '• For safety and security purposes',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.logout();
            },
            child: const Text('Logout'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
