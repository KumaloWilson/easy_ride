import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/modules/auth/controllers/auth_controller.dart';
import 'package:lottie/lottie.dart';

class EmailVerificationView extends GetView<AuthController> {
  const EmailVerificationView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Start a timer to check verification status periodically
    Timer.periodic(const Duration(seconds: 3), (timer) {
      controller.checkEmailVerification();
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/email_verification.json',
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 32),
              Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'We\'ve sent a verification email to ${controller.email.value}. Please check your inbox and click the verification link to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 32),
              Obx(() => controller.isLoading.value
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () => controller.checkEmailVerification(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'I\'ve Verified My Email',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )),
              const SizedBox(height: 16),
              Obx(() => controller.error.value.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        controller.error.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    )
                  : const SizedBox.shrink()),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => controller.sendEmailVerification(),
                child: Text(
                  'Resend Verification Email',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => controller.signOut(),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
