import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_ride/core/services/auth_service.dart';
import 'package:easy_ride/core/services/preferences_service.dart';
import 'package:easy_ride/models/user_model.dart';
import 'package:easy_ride/routes/app_pages.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final PreferencesService _prefsService = Get.find<PreferencesService>();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString verificationId = ''.obs;
  final RxString phoneNumber = ''.obs;
  final RxString email = ''.obs;
  final RxString password = ''.obs;
  final RxString selectedUserType = ''.obs;

  // Expose auth service properties
  bool get isLoggedIn => _authService.isLoggedIn;
  bool get isDriver => _authService.isDriver;
  Rx<UserModel?> get currentUser => _authService.currentUser;

  @override
  void onInit() {
    super.onInit();
    // Initialize selectedUserType from preferences if available
    if (_prefsService.userRole.value.isNotEmpty) {
      selectedUserType.value = _prefsService.userRole.value;
    } else {
      selectedUserType.value = 'rider'; // Default value
    }

    print('AuthController initialized: userRole=${selectedUserType.value}');
  }

  Future<void> signInWithEmailAndPassword() async {
    if (email.value.isEmpty || password.value.isEmpty) {
      error.value = 'Email and password are required';
      return;
    }

    isLoading.value = true;
    error.value = '';

    try {
      await _authService.signInWithEmailAndPassword(email.value, password.value);

      // Navigate based on user type
      if (_authService.isDriver) {
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
      UserCredential? userCredential = await _authService.signUpWithEmailAndPassword(email.value, password.value);

      if (userCredential != null && userCredential.user != null) {
        // Create user in Firestore
        UserModel newUser = UserModel(
          id: userCredential.user!.uid,
          email: email.value,
          userType: _prefsService.userRole.value, // Use the role from preferences
          createdAt: DateTime.now(),
        );

        await _authService.createUserInFirestore(newUser);

        // Navigate to profile setup
        Get.offAllNamed(Routes.profileSetup);
      }
    } on FirebaseAuthException catch (e) {
      handleAuthError(e);
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
      await _authService.verifyPhoneNumber(
        phoneNumber: phoneNumber.value,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _authService.signInWithCredential(credential);

          // Navigate based on user type
          if (_authService.isDriver) {
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

      UserCredential userCredential = await _authService.signInWithCredential(credential);

      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        // Create user in Firestore for new users
        UserModel newUser = UserModel(
          id: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          phoneNumber: phoneNumber.value,
          userType: _prefsService.userRole.value, // Use the role from preferences
          createdAt: DateTime.now(),
        );

        await _authService.createUserInFirestore(newUser);

        // Navigate to profile setup
        Get.offAllNamed(Routes.profileSetup);
      } else {
        // Navigate based on user type
        if (_authService.isDriver) {
          Get.offAllNamed(Routes.driverHome);
        } else {
          Get.offAllNamed(Routes.riderHome);
        }
      }
    } on FirebaseAuthException catch (e) {
      handleAuthError(e);
    } catch (e) {
      error.value = 'Failed to verify OTP: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    isLoading.value = true;

    try {
      await _authService.signOut();
      // Don't reset preferences on sign out to keep role selection and intro status
      Get.offAllNamed(Routes.login);
    } catch (e) {
      error.value = 'Failed to sign out: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  void setUserType(String userType) {
    selectedUserType.value = userType;
  }

  void handleAuthError(FirebaseAuthException e) {
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
