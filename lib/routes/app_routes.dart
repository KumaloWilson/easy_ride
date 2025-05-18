part of 'app_pages.dart';

abstract class Routes {
  // Onboarding Routes
  static const roleSelection = '/role-selection';
  static const riderIntro = '/rider-intro';
  static const driverIntro = '/driver-intro';
  
  // Auth Routes
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const otpVerification = '/otp-verification';
  static const emailVerification = '/email-verification';
  static const userTypeSelection = '/user-type-selection';
  
  // Profile Routes
  static const profileSetup = '/profile-setup';
  static const profile = '/profile';
  
  // Driver Routes
  static const driverHome = '/driver-home';
  static const driverVerification = '/driver-verification';
  static const driverDocumentUpload = '/driver-document-upload';
  static const driverRideDetails = '/driver-ride-details';
  static const driverEarnings = '/driver-earnings';
  
  // Rider Routes
  static const riderHome = '/rider-home';
  static const rideBooking = '/ride-booking';
  static const rideDetails = '/ride-details';
  static const rideHistory = '/ride-history';
  
  // Vehicle Hire Routes
  static const vehicleHire = '/vehicle-hire';
  static const vehicleHireDetails = '/vehicle-hire-details/:id';
  static const hireDetails = '/hire-details';
  static const hireHistory = '/hire-history';
  
  // Chat Routes
  static const chat = '/chat';
}
