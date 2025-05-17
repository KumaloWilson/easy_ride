import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_ride/core/services/auth_service.dart';
import 'package:easy_ride/core/services/preferences_service.dart';
import 'package:easy_ride/models/user_model.dart';
import 'package:easy_ride/routes/app_pages.dart';
import 'package:easy_ride/core/utils/logs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_ride/models/vehicle_model.dart';
import 'package:easy_ride/models/location_model.dart';

class AuthController extends GetxController {
  final AuthService authService = Get.find<AuthService>();
  final PreferencesService _prefsService = Get.find<PreferencesService>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString verificationId = ''.obs;
  final RxString phoneNumber = ''.obs;
  final RxString email = ''.obs;
  final RxString password = ''.obs;
  final RxString selectedUserType = ''.obs;
  final RxBool isEmailVerificationSent = false.obs;

  // Expose auth service properties
  bool get isLoggedIn => authService.isLoggedIn;
  bool get isDriver => authService.isDriver;
  bool get isEmailVerified => authService.isEmailVerified;
  Rx<UserModel?> get currentUser => authService.currentUser;

  @override
  void onInit() {
    super.onInit();
    // Initialize selectedUserType from preferences if available
    if (_prefsService.userRole.value.isNotEmpty) {
      selectedUserType.value = _prefsService.userRole.value;
    } else {
      selectedUserType.value = 'rider'; // Default value
    }

    DevLogs.info('AuthController initialized: userRole=${selectedUserType.value}');
  }

  Future<void> signInWithEmailAndPassword() async {
    if (email.value.isEmpty || password.value.isEmpty) {
      error.value = 'Email and password are required';
      return;
    }

    isLoading.value = true;
    error.value = '';

    try {
      await authService.signInWithEmailAndPassword(email.value, password.value);

      // Check if email is verified
      if (!authService.isEmailVerified) {
        Get.offAllNamed(Routes.emailVerification);
        return;
      }

      // Navigate based on user type
      if (authService.isDriver) {
        Get.offAllNamed(Routes.driverHome);
      } else {
        Get.offAllNamed(Routes.riderHome);
      }
    } on FirebaseAuthException catch (e) {
      handleAuthError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUpWithEmailAndPassword() async {
    if (email.value.isEmpty || password.value.isEmpty) {
      error.value = 'Email and password are required';
      return;
    }

    isLoading.value = true;
    error.value = '';

    try {
      UserCredential? userCredential = await authService.signUpWithEmailAndPassword(email.value, password.value);

      if (userCredential != null && userCredential.user != null) {
        final userType = _prefsService.userRole.value;

        // Create user in Firestore
        UserModel newUser = UserModel(
          id: userCredential.user!.uid,
          email: email.value,
          userType: userType, // Use the role from preferences
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          fullName: userCredential.user!.displayName ?? "",
          emailVerified: false,
        );

        await authService.createUserInFirestore(newUser);

        // If user is a driver, create a driver profile
        if (userType == 'driver') {
          await _createDriverProfile(userCredential.user!.uid, newUser);
        }

        // Navigate to email verification screen
        isEmailVerificationSent.value = true;
        Get.offAllNamed(Routes.emailVerification);
      }
    } on FirebaseAuthException catch (e) {
      handleAuthError(e);
    } catch (e) {
      error.value = 'Failed to sign up: ${e.toString()}';
      DevLogs.error('Failed to sign up', exception: e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _createDriverProfile(String userId, UserModel user) async {
    try {
      DevLogs.info('Creating driver profile for user $userId');

      // Create a default vehicle model
      final defaultVehicle = VehicleModel(
        id: 'default',
        make: '',
        model: '',
        year: DateTime.now().year.toString(),
        color: '',
        licensePlate: '',
        features: [],
        photoUrl: '',
        vehicleType: 'sedan',
        capacity: 4,
      );

      // Create a default location
      final defaultLocation = LocationModel(
        latitude: 0.0,
        longitude: 0.0,
        address: '',
        name: '',
      );

      // Create driver document
      await _firestore.collection('drivers').doc(userId).set({
        'id': userId,
        'user': user.toMap(),
        'licenseNumber': '',
        'licenseExpiry': '',
        'documents': {},
        'isVerified': false,
        'verificationStatus': 'pending',
        'rating': 0.0,
        'totalRides': 0,
        'vehicle': defaultVehicle.toJson(),
        'currentLocation': defaultLocation.toJson(),
        'status': 'offline',
        'isOnline': false,
        'lastStatusUpdate': FieldValue.serverTimestamp(),
        'totalEarnings': 0.0,
        'fcmToken': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create driver location document
      await _firestore.collection('driverLocations').doc(userId).set({
        'driverId': userId,
        'location': GeoPoint(0, 0),
        'status': 'offline',
        'isOnline': false,
        'isBusy': false,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      DevLogs.info('Driver profile created successfully');
    } catch (e) {
      DevLogs.error('Error creating driver profile', exception: e);
      throw e;
    }
  }

  Future<void> sendEmailVerification() async {
    isLoading.value = true;
    error.value = '';

    try {
      await authService.sendEmailVerification();
      isEmailVerificationSent.value = true;
    } catch (e) {
      error.value = 'Failed to send verification email: ${e.toString()}';
      DevLogs.error('Failed to send verification email', exception: e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkEmailVerification() async {
    isLoading.value = true;
    error.value = '';

    try {
      await authService.checkEmailVerification();

      if (authService.isEmailVerified) {
        // Navigate based on user type
        if (authService.isDriver) {
          Get.offAllNamed(Routes.driverHome);
        } else {
          Get.offAllNamed(Routes.riderHome);
        }
      } else {
        error.value = 'Email not verified yet. Please check your inbox.';
      }
    } catch (e) {
      error.value = 'Failed to check verification status: ${e.toString()}';
      DevLogs.error('Failed to check verification status', exception: e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendOTP() async {
    if (phoneNumber.value.isEmpty) {
      error.value = 'Phone number is required';
      return;
    }

    isLoading.value = true;
    error.value = '';

    try {
      await authService.verifyPhoneNumber(
        phoneNumber: phoneNumber.value,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await authService.signInWithCredential(credential);

          // Navigate based on user type
          if (authService.isDriver) {
            Get.offAllNamed(Routes.driverHome);
          } else {
            Get.offAllNamed(Routes.riderHome);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          handleAuthError(e);
        },
        codeSent: (String verId, int? resendToken) {
          verificationId.value = verId;
          Get.toNamed(Routes.otpVerification);
        },
        codeAutoRetrievalTimeout: (String verId) {
          verificationId.value = verId;
        },
      );
    } catch (e) {
      error.value = 'Failed to send OTP: ${e.toString()}';
      DevLogs.error('Failed to send OTP', exception: e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOTP(String otp) async {
    if (otp.isEmpty) {
      error.value = 'OTP is required';
      return;
    }

    isLoading.value = true;
    error.value = '';

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId.value,
        smsCode: otp,
      );

      UserCredential userCredential = await authService.signInWithCredential(credential);

      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        final userType = _prefsService.userRole.value;

        // Create user in Firestore for new users
        UserModel newUser = UserModel(
          id: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          phoneNumber: phoneNumber.value,
          userType: userType, // Use the role from preferences
          createdAt: DateTime.now(),
          fullName: "",
          updatedAt: DateTime.now(),
          emailVerified: true, // Phone auth doesn't need email verification
        );

        await authService.createUserInFirestore(newUser);

        // If user is a driver, create a driver profile
        if (userType == 'driver') {
          await _createDriverProfile(userCredential.user!.uid, newUser);
        }

        // Navigate to profile setup
        Get.offAllNamed(Routes.profileSetup);
      } else {
        // Navigate based on user type
        if (authService.isDriver) {
          Get.offAllNamed(Routes.driverHome);
        } else {
          Get.offAllNamed(Routes.riderHome);
        }
      }
    } on FirebaseAuthException catch (e) {
      handleAuthError(e);
    } catch (e) {
      error.value = 'Failed to verify OTP: ${e.toString()}';
      DevLogs.error('Failed to verify OTP', exception: e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    isLoading.value = true;

    try {
      await authService.signOut();
      // Don't reset preferences on sign out to keep role selection and intro status
      Get.offAllNamed(Routes.login);
    } catch (e) {
      error.value = 'Failed to sign out: ${e.toString()}';
      DevLogs.error('Failed to sign out', exception: e);
    } finally {
      isLoading.value = false;
    }
  }

  void setUserType(String userType) {
    selectedUserType.value = userType;
  }

  void handleAuthError(FirebaseAuthException e) {
    DevLogs.error('Auth error', exception: e);

    switch (e.code) {
      case 'user-not-found':
        error.value = 'No user found with this email';
        break;
      case 'wrong-password':
        error.value = 'Wrong password';
        break;
      case 'email-already-in-use':
        error.value = 'Email is already in use';
        break;
      case 'weak-password':
        error.value = 'Password is too weak';
        break;
      case 'invalid-email':
        error.value = 'Invalid email address';
        break;
      case 'invalid-verification-code':
        error.value = 'Invalid OTP code';
        break;
      case 'invalid-verification-id':
        error.value = 'Invalid verification ID';
        break;
      default:
        error.value = e.message ?? 'An unknown error occurred';
    }
  }
}
