import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/modules/onboarding/controllers/onboarding_controller.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class RiderIntroView extends GetView<OnboardingController> {
  const RiderIntroView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final PageController pageController = PageController();
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: controller.skipIntro,
                  child: const Text('Skip'),
                ),
              ),
            ),
            
            // Page view
            Expanded(
              child: PageView(
                controller: pageController,
                onPageChanged: controller.setCurrentPage,
                children: [
                  _buildIntroPage(
                    title: 'Request Rides Anytime',
                    description: 'Book a ride whenever you need it, day or night, with just a few taps.',
                    image: Icons.access_time,
                  ),
                  _buildIntroPage(
                    title: 'Track Your Driver',
                    description: 'See your driver approaching in real-time and share your trip status with friends.',
                    image: Icons.location_on,
                  ),
                  _buildIntroPage(
                    title: 'Safe & Reliable',
                    description: 'All drivers are verified and rated by other riders for your safety.',
                    image: Icons.verified_user,
                  ),
                  _buildIntroPage(
                    title: 'Multiple Payment Options',
                    description: 'Pay with cash, card, or mobile wallet - whatever works for you.',
                    image: Icons.payment,
                  ),
                ],
              ),
            ),
            
            // Bottom navigation
            Container(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page indicator
                  SmoothPageIndicator(
                    controller: pageController,
                    count: 4,
                    effect: WormEffect(
                      dotHeight: 10,
                      dotWidth: 10,
                      activeDotColor: AppTheme.primaryColor,
                      dotColor: Colors.grey.shade300,
                    ),
                  ),
                  
                  // Next/Get Started button
                  Obx(() => ElevatedButton(
                    onPressed: () {
                      if (controller.isLastPage.value) {
                        controller.completeIntro();
                      } else {
                        pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      controller.isLastPage.value ? 'Get Started' : 'Next',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildIntroPage({
    required String title,
    required String description,
    required IconData image,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image placeholder
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              image,
              size: 100,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 40),
          
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Description
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
