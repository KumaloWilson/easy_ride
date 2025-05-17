import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/core/services/auth_service.dart';
import 'package:easy_ride/modules/rider/views/rider_home_view.dart';
import 'package:easy_ride/modules/rider/views/ride_history_view.dart';
import 'package:easy_ride/modules/profile/views/profile_view.dart';
import 'package:easy_ride/modules/chat/views/chat_view.dart';
import 'package:easy_ride/modules/common/widgets/emergency_button.dart';
import 'package:easy_ride/modules/common/widgets/feedback_form.dart';

import '../views/saved_places.dart';

class RiderSidebar extends StatelessWidget {
  final AuthService _authService = Get.find<AuthService>();

  RiderSidebar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              Expanded(
                child: _buildMenuItems(context),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Obx(() {
      final user = _authService.currentUser.value;

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              backgroundImage: user?.profileImageUrl != null
                  ? NetworkImage(user!.profileImageUrl!)
                  : null,
              child: user?.profileImageUrl == null
                  ? const Icon(Icons.person, size: 40, color: AppTheme.primaryColor)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              user?.fullName ?? 'Rider',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Rider',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMenuItems(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 20),
          _buildMenuItem(
            icon: Icons.home_outlined,
            title: 'Home',
            onTap: () {
              Get.back();
              Get.to(() => RiderHomeView());
            },
          ),
          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'My Profile',
            onTap: () {
              Get.back();
              Get.to(() => const ProfileView());
            },
          ),
          _buildMenuItem(
            icon: Icons.history,
            title: 'Ride History',
            onTap: () {
              Get.back();
              Get.to(() => const RideHistoryView());
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
            icon: Icons.payment_outlined,
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
            icon: Icons.message_outlined,
            title: 'Messages',
            onTap: () {
              Get.back();
              Get.to(() => const ChatView());
            },
          ),
          _buildMenuItem(
            icon: Icons.star_outline,
            title: 'Rate & Review',
            onTap: () {
              Get.back();
              _showFeedbackDialog(context);
            },
          ),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              Get.back();
              Get.snackbar(
                'Support',
                'Contact our support team at support@easyride.com',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.settings_outlined,
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
            icon: Icons.emergency_outlined,
            title: 'Emergency',
            color: Colors.red,
            onTap: () {
              Get.back();
              _showEmergencyOptions(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? AppTheme.primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      dense: true,
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      color: Colors.white,
      child: Column(
        children: [
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.logout,
              color: Colors.red,
            ),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Get.back();
              _showLogoutConfirmation();
            },
          ),
          const SizedBox(height: 10),
          Text(
            'App Version 1.0.0',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _authService.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
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
                onTap: () {
                  Navigator.pop(context);
                  // Implement police contact
                },
              ),
              ListTile(
                leading: const Icon(Icons.medical_services, color: Colors.red),
                title: const Text('Medical Emergency'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement medical emergency
                },
              ),
              ListTile(
                leading: const Icon(Icons.support_agent, color: Colors.green),
                title: const Text('Contact Support'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement support contact
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rate Your Experience'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'How would you rate your experience with Easy Ride?',
              ),
              const SizedBox(height: 16),
              // Implement rating widget
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Share your feedback (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
                Navigator.of(context).pop();
                Get.snackbar(
                  'Thank You',
                  'Your feedback has been submitted',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}
