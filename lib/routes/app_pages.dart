import 'package:get/get.dart';
import 'package:easy_ride/modules/auth/bindings/auth_binding.dart';
import 'package:easy_ride/modules/auth/views/splash_view.dart';
import 'package:easy_ride/modules/auth/views/login_view.dart';
import 'package:easy_ride/modules/auth/views/register_view.dart';
import 'package:easy_ride/modules/auth/views/otp_verification_view.dart';
import 'package:easy_ride/modules/auth/views/user_type_selection_view.dart';
import 'package:easy_ride/modules/profile/bindings/profile_binding.dart';
import 'package:easy_ride/modules/profile/views/profile_setup_view.dart';
import 'package:easy_ride/modules/profile/views/profile_view.dart';
import 'package:easy_ride/modules/driver/bindings/driver_binding.dart';
import 'package:easy_ride/modules/driver/views/driver_home_view.dart';
import 'package:easy_ride/modules/driver/views/driver_document_upload_view.dart';
import 'package:easy_ride/modules/driver/views/driver_ride_details_view.dart';
import 'package:easy_ride/modules/driver/views/driver_earnings_view.dart';
import 'package:easy_ride/modules/rider/bindings/rider_binding.dart';
import 'package:easy_ride/modules/rider/views/rider_home_view.dart';
import 'package:easy_ride/modules/rider/views/ride_booking_view.dart';
import 'package:easy_ride/modules/rider/views/ride_details_view.dart';
import 'package:easy_ride/modules/rider/views/ride_history_view.dart';
import 'package:easy_ride/modules/chat/bindings/chat_binding.dart';
import 'package:easy_ride/modules/chat/views/chat_view.dart';
import 'package:easy_ride/modules/onboarding/bindings/onboarding_binding.dart';
import 'package:easy_ride/modules/onboarding/views/role_selection_view.dart';
import 'package:easy_ride/modules/onboarding/views/rider_intro_view.dart';
import 'package:easy_ride/modules/onboarding/views/driver_intro_view.dart';
import 'package:easy_ride/modules/auth/views/email_verification_view.dart';
import 'package:easy_ride/modules/driver/views/driver_verification_view.dart';
import 'package:easy_ride/modules/chat/views/enhanced_chat_view.dart';
import 'package:easy_ride/modules/rider/views/enhanced_ride_history_view.dart';
import 'package:easy_ride/modules/profile/views/enhanced_profile_view.dart';

part 'app_routes.dart';

class AppPages {
  static const initial = Routes.splash;
  
  static final routes = [
    // Onboarding Routes
    GetPage(
      name: Routes.roleSelection,
      page: () => const RoleSelectionView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: Routes.riderIntro,
      page: () => const RiderIntroView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: Routes.driverIntro,
      page: () => const DriverIntroView(),
      binding: OnboardingBinding(),
    ),
    
    // Auth Routes
    GetPage(
      name: Routes.splash,
      page: () => const SplashView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.register,
      page: () => const RegisterView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.otpVerification,
      page: () => const OtpVerificationView(),
      binding: AuthBinding(),
    ),

    GetPage(
      name: Routes.emailVerification,
      page: () => const EmailVerificationView(),
      binding: AuthBinding(),
    ),

    GetPage(
      name: Routes.userTypeSelection,
      page: () => const UserTypeSelectionView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.emailVerification,
      page: () => const EmailVerificationView(),
      binding: AuthBinding(),
    ),
    
    // Profile Routes
    GetPage(
      name: Routes.profileSetup,
      page: () => const ProfileSetupView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: Routes.profile,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),

    GetPage(
      name: '/enhanced-profile',
      page: () => const EnhancedProfileView(),
      binding: ProfileBinding(),
    ),
    
    // Driver Routes
    GetPage(
      name: Routes.driverHome,
      page: () => DriverHomeView(),
      binding: DriverBinding(),
    ),
    GetPage(
      name: Routes.driverDocumentUpload,
      page: () => const DriverDocumentUploadView(),
      binding: DriverBinding(),
    ),
    GetPage(
      name: Routes.driverRideDetails,
      page: () => const DriverRideDetailsView(),
      binding: DriverBinding(),
    ),
    GetPage(
      name: Routes.driverEarnings,
      page: () => const DriverEarningsView(),
      binding: DriverBinding(),
    ),
    GetPage(
      name: Routes.driverVerification,
      page: () => const DriverVerificationView(),
      binding: DriverBinding(),
    ),


    // Rider Routes
    GetPage(
      name: Routes.riderHome,
      page: () => RiderHomeView(),
      binding: RiderBinding(),
    ),
    GetPage(
      name: Routes.rideBooking,
      page: () => RideBookingView(),
      binding: RiderBinding(),
    ),
    GetPage(
      name: Routes.rideDetails,
      page: () => RideDetailsView(),
      binding: RiderBinding(),
    ),
    GetPage(
      name: Routes.rideHistory,
      page: () => const RideHistoryView(),
      binding: RiderBinding(),
    ),
    GetPage(
      name: '/enhanced-ride-history',
      page: () => const EnhancedRideHistoryView(),
      binding: RiderBinding(),
    ),
    
    // Chat Routes
    GetPage(
      name: Routes.chat,
      page: () => const ChatView(),
      binding: ChatBinding(),
    ),
    GetPage(
      name: '/enhanced-chat',
      page: () => const EnhancedChatView(),
      binding: ChatBinding(),
    ),
  ];
}
