import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_ride/modules/auth/controllers/auth_controller.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/core/services/preferences_service.dart';
import 'package:easy_ride/routes/app_pages.dart';

class SplashView extends StatefulWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();

    // Navigate after animation completes
    Future.delayed(const Duration(milliseconds: 2500), () {
      _navigateToNextScreen();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToNextScreen() {
    try {
      final PreferencesService prefsService = Get.find<PreferencesService>();
      final AuthController authController = Get.find<AuthController>();

      print('Navigating from splash: isFirstLaunch=${prefsService.isFirstLaunch.value}, '
          'introCompleted=${prefsService.introCompleted.value}, '
          'isLoggedIn=${authController.isLoggedIn}');

      // Check if it's first launch
      if (prefsService.isFirstLaunch.value) {
        print('First launch - going to role selection');
        Get.offAllNamed(Routes.roleSelection);
        return;
      }

      // Check if intro is completed
      if (!prefsService.introCompleted.value) {
        // Navigate to appropriate intro screen based on saved role
        if (prefsService.userRole.value == 'rider') {
          print('Intro not completed - going to rider intro');
          Get.offAllNamed(Routes.riderIntro);
        } else {
          print('Intro not completed - going to driver intro');
          Get.offAllNamed(Routes.driverIntro);
        }
        return;
      }

      // Check authentication status
      if (authController.isLoggedIn) {
        if (authController.currentUser.value == null) {
          // User is authenticated but profile not loaded yet
          print('User authenticated but profile not loaded - going to profile setup');
          Get.offAllNamed(Routes.profileSetup);
        } else {
          // User is authenticated and profile loaded
          if (authController.isDriver) {
            print('Driver logged in - going to driver home');
            Get.offAllNamed(Routes.driverHome);
          } else {
            print('Rider logged in - going to rider home');
            Get.offAllNamed(Routes.riderHome);
          }
        }
      } else {
        // User is not authenticated
        print('User not authenticated - going to login');
        Get.offAllNamed(Routes.login);
      }
    } catch (e) {
      print('Error during navigation: $e');
      // Fallback to login screen if there's an error
      Get.offAllNamed(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor,
              AppTheme.secondaryColor,
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(75),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'ER',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App Name
                    const Text(
                      'Easy Ride',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tagline
                    const Text(
                      'Your ride, your way',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Loading indicator
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
