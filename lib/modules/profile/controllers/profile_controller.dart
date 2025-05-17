import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_ride/core/services/auth_service.dart';
import 'package:easy_ride/core/services/storage_service.dart';
import 'package:easy_ride/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_ride/core/utils/logs.dart';

import '../../../routes/app_pages.dart';

class ProfileController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final StorageService _storageService = Get.find<StorageService>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

      // Check if user is a driver and create driver profile if it doesn't exist
      if (_authService.isDriver) {
        await _ensureDriverProfileExists();
      }

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

  Future<void> _ensureDriverProfileExists() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Check if driver profile exists
      final driverDoc = await _firestore.collection('drivers').doc(user.uid).get();

      if (!driverDoc.exists) {
        DevLogs.info('Creating missing driver profile for user ${user.uid}');

        // Get user data
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) return;

        final userData = userDoc.data()!;
        final userModel = UserModel.fromMap(userData, user.uid);

        // Create driver profile
        await _firestore.collection('drivers').doc(user.uid).set({
          'id': user.uid,
          'user': userModel.toMap(),
          'licenseNumber': '',
          'licenseExpiry': '',
          'documents': {},
          'isVerified': false,
          'verificationStatus': 'pending',
          'rating': 0.0,
          'totalRides': 0,
          'vehicle': {
            'id': 'default',
            'make': '',
            'model': '',
            'year': DateTime.now().year,
            'color': '',
            'licensePlate': '',
            'registrationExpiry': '',
            'isVerified': false,
            'type': 'sedan',
            'capacity': 4,
          },
          'currentLocation': {
            'latitude': 0.0,
            'longitude': 0.0,
            'address': '',
            'name': '',
          },
          'status': 'offline',
          'isOnline': false,
          'lastStatusUpdate': FieldValue.serverTimestamp(),
          'totalEarnings': 0.0,
          'fcmToken': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Create driver location document
        await _firestore.collection('driverLocations').doc(user.uid).set({
          'driverId': user.uid,
          'location': GeoPoint(0, 0),
          'status': 'offline',
          'isOnline': false,
          'isBusy': false,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        DevLogs.info('Driver profile created successfully');
      }
    } catch (e) {
      DevLogs.error('Error ensuring driver profile exists', exception: e);
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
