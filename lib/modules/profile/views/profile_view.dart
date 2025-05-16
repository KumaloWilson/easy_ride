import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_ride/modules/profile/controllers/profile_controller.dart';
import 'package:easy_ride/core/services/auth_service.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/routes/app_pages.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Get.find<AuthService>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile header
              Container(
                padding: const EdgeInsets.all(24),
                color: AppTheme.primaryColor,
                child: Column(
                  children: [
                    // Profile image
                    Obx(() => Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        image: authService.currentUser.value?.profileImageUrl != null
                            ? DecorationImage(
                                image: NetworkImage(authService.currentUser.value!.profileImageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: authService.currentUser.value?.profileImageUrl == null
                          ? Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey[600],
                            )
                          : null,
                    )),
                    const SizedBox(height: 16),
                    
                    // User name
                    Obx(() => Text(
                      authService.currentUser.value?.fullName ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                    const SizedBox(height: 4),
                    
                    // User type
                    Obx(() => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        authService.isDriver ? 'Driver' : 'Rider',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    )),
                  ],
                ),
              ),
              
              // Profile details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Personal Information section
                    _buildSectionHeader('Personal Information'),
                    _buildProfileItem(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      value: authService.currentUser.value?.email ?? '',
                    ),
                    _buildProfileItem(
                      icon: Icons.phone_outlined,
                      title: 'Phone',
                      value: authService.currentUser.value?.phoneNumber ?? 'Not provided',
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Account section
                    _buildSectionHeader('Account'),
                    _buildActionItem(
                      icon: Icons.edit_outlined,
                      title: 'Edit Profile',
                      onTap: () {
                        // Navigate to edit profile
                        controller.loadUserData();
                        Get.toNamed(Routes.profileSetup);
                      },
                    ),
                    if (authService.isDriver)
                      _buildActionItem(
                        icon: Icons.description_outlined,
                        title: 'Driver Documents',
                        onTap: () {
                          // Navigate to driver documents
                          Get.toNamed(Routes.driverDocumentUpload);
                        },
                      ),
                    _buildActionItem(
                      icon: Icons.history,
                      title: 'Ride History',
                      onTap: () {
                        // Navigate to ride history
                        Get.toNamed(Routes.rideHistory);
                      },
                    ),
                    if (authService.isDriver)
                      _buildActionItem(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Earnings',
                        onTap: () {
                          // Navigate to earnings
                          Get.toNamed(Routes.driverEarnings);
                        },
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Support section
                    _buildSectionHeader('Support'),
                    _buildActionItem(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      onTap: () {
                        // TODO: Navigate to help & support
                      },
                    ),
                    _buildActionItem(
                      icon: Icons.info_outline,
                      title: 'About',
                      onTap: () {
                        // TODO: Navigate to about
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Logout button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: controller.signOut,
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const Divider(),
        const SizedBox(height: 8),
      ],
    );
  }
  
  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
