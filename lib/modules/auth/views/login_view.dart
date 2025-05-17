import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/modules/auth/controllers/auth_controller.dart';
import 'package:easy_ride/routes/app_pages.dart';
import 'package:easy_ride/core/services/preferences_service.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final PreferencesService prefsService = Get.find<PreferencesService>();
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              
              // Logo
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Center(
                    child: Text(
                      'ER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // Header
              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Role display
              Obx(() => Text(
                prefsService.userRole.value.isNotEmpty
                    ? 'Login as a ${prefsService.userRole.value.capitalizeFirst}'
                    : 'Login to your account',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              )),
              const SizedBox(height: 40),
              
              // Email field
              TextField(
                onChanged: (value) => controller.email.value = value,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Password field
              Obx(() => TextField(
                onChanged: (value) => controller.password.value = value,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorText: controller.error.value.isNotEmpty ? controller.error.value : null,
                ),
              )),
              const SizedBox(height: 16),
              
              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: Implement forgot password
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Login button
              Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : controller.signInWithEmailAndPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: controller.isLoading.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              )),
              const SizedBox(height: 20),
              
              // Divider
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              
              // Phone login button
              OutlinedButton.icon(
                onPressed: () => Get.toNamed(Routes.otpVerification),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.phone),
                label: const Text('Log In with Phone Number'),
              ),
              const SizedBox(height: 40),
              
              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Don\'t have an account?'),
                  TextButton(
                    onPressed: () => Get.offNamed(Routes.register),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Debug button in development mode
              if (true) // Change to a debug flag in production
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: OutlinedButton(
                    onPressed: () async {
                      await prefsService.forceFirstLaunch();
                      Get.offAllNamed(Routes.splash);
                    },
                    child: const Text('Reset Onboarding (Debug)'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
