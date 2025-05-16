import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_ride/core/services/auth_service.dart';
import 'package:easy_ride/core/services/storage_service.dart';
import 'package:easy_ride/models/user_model.dart';

import '../../../routes/app_pages.dart';

class ProfileController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final StorageService _storageService = Get.find<StorageService>();
  final ImagePicker _imagePicker = ImagePicker();
  
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString fullName = ''.obs;
  final RxString phoneNumber = ''.obs;
  final Rx<File?> profileImage = Rx<File?>(null);
  
  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }
  
  void loadUserData() {
    if (_authService.currentUser.value != null) {
      UserModel user = _authService.currentUser.value!;
      fullName.value = user.fullName ?? '';
      phoneNumber.value = user.phoneNumber ?? '';
    }
  }
  
  Future<void> pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (image != null) {
      profileImage.value = File(image.path);
    }
  }
  
  Future<void> takePhoto() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    
    if (image != null) {
      profileImage.value = File(image.path);
    }
  }
  
  Future<void> updateProfile() async {
    if (fullName.value.isEmpty) {
      error.value = 'Full name is required';
      return;
    }
    
    isLoading.value = true;
    error.value = '';
    
    try {
      String? profileImageUrl;
      
      // Upload profile image if selected
      if (profileImage.value != null) {
        profileImageUrl = await _storageService.uploadProfileImage(
          profileImage.value!,
          _authService.firebaseUser.value!.uid,
        );
      }
      
      // Update user data in Firestore
      Map<String, dynamic> userData = {
        'fullName': fullName.value,
      };
      
      if (phoneNumber.value.isNotEmpty) {
        userData['phoneNumber'] = phoneNumber.value;
      }
      
      if (profileImageUrl != null) {
        userData['profileImageUrl'] = profileImageUrl;
      }
      
      await _authService.updateUserData(userData);
      
      Get.back();
      Get.snackbar(
        'Success',
        'Profile updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      error.value = 'Failed to update profile: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> saveProfileSetup() async {
    if (fullName.value.isEmpty) {
      error.value = 'Full name is required';
      return;
    }
    
    isLoading.value = true;
    error.value = '';
    
    try {
      String? profileImageUrl;
      
      // Upload profile image if selected
      if (profileImage.value != null) {
        profileImageUrl = await _storageService.uploadProfileImage(
          profileImage.value!,
          _authService.firebaseUser.value!.uid,
        );
      }
      
      // Update user data in Firestore
      Map<String, dynamic> userData = {
        'fullName': fullName.value,
        'isVerified': true,
        'updatedAt': DateTime.now(),
      };
      
      if (phoneNumber.value.isNotEmpty) {
        userData['phoneNumber'] = phoneNumber.value;
      }
      
      if (profileImageUrl != null) {
        userData['profileImageUrl'] = profileImageUrl;
      }
      
      await _authService.updateUserData(userData);
      
      // Navigate to appropriate home screen
      if (_authService.isDriver) {
        Get.offAllNamed(Routes.driverHome);
      } else {
        Get.offAllNamed(Routes.riderHome);
      }
    } catch (e) {
      error.value = 'Failed to save profile: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      Get.offAllNamed(Routes.login);
    } catch (e) {
      error.value = 'Failed to sign out: ${e.toString()}';
    }
  }
}
