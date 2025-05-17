import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_ride/modules/auth/controllers/auth_controller.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/routes/app_pages.dart';

class UserTypeSelectionView extends GetView<AuthController> {
  const UserTypeSelectionView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Account Type'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              
              // Header
              Text(
                'How will you use Easy Ride?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Choose your account type',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),
              
              // User type options
              Obx(() => Column(
                children: [
                  // Rider option
                  GestureDetector(
                    onTap: () => controller.setUserType('rider'),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: controller.selectedUserType.value == 'rider'
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: controller.selectedUserType.value == 'rider'
                              ? AppTheme.primaryColor
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: controller.selectedUserType.value == 'rider'
                                  ? AppTheme.primaryColor
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Icon(
                              Icons.person,
                              size: 32,
                              color: controller.selectedUserType.value == 'rider'
                                  ? Colors.white
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rider',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: controller.selectedUserType.value == 'rider'
                                        ? AppTheme.primaryColor
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Request rides and get to your destination',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.check_circle,
                            color: controller.selectedUserType.value == 'rider'
                                ? AppTheme.primaryColor
                                : Colors.transparent,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Driver option
                  GestureDetector(
                    onTap: () => controller.setUserType('driver'),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: controller.selectedUserType.value == 'driver'
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: controller.selectedUserType.value == 'driver'
                              ? AppTheme.primaryColor
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: controller.selectedUserType.value == 'driver'
                                  ? AppTheme.primaryColor
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Icon(
                              Icons.drive_eta,
                              size: 32,
                              color: controller.selectedUserType.value == 'driver'
                                  ? Colors.white
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Driver',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: controller.selectedUserType.value == 'driver'
                                        ? AppTheme.primaryColor
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Drive and earn money on your own schedule',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.check_circle,
                            color: controller.selectedUserType.value == 'driver'
                                ? AppTheme.primaryColor
                                : Colors.transparent,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )),
              
              const Spacer(),
              
              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Update user type in Firestore
                    controller.authService.updateUserData({
                      'userType': controller.selectedUserType.value,
                    });
                    
                    // Navigate to appropriate screen
                    if (controller.selectedUserType.value == 'driver') {
                      Get.offAllNamed(Routes.driverDocumentUpload);
                    } else {
                      Get.offAllNamed(Routes.profileSetup);
                    }
                  },
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
