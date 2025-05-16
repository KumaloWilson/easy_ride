import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_ride/modules/auth/controllers/auth_controller.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpVerificationView extends GetView<AuthController> {
  const OtpVerificationView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Verification'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                
                // Header
                Text(
                  'Verify Your Phone',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Phone number input or OTP input based on verification state
                Obx(() => controller.verificationId.value.isEmpty
                  ? _buildPhoneInput()
                  : _buildOtpInput(context)
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter your phone number to receive a verification code',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 32),
        
        // Phone field
        TextField(
          onChanged: (value) => controller.phoneNumber.value = value,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: Icon(Icons.phone),
            hintText: '+1 234 567 8900',
          ),
        ),
        const SizedBox(height: 24),
        
        // Error message
        if (controller.error.value.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.error.value,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        
        // User type selection
        Text(
          'I want to:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        
        Obx(() => Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => controller.setUserType('rider'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: controller.selectedUserType.value == 'rider'
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: controller.selectedUserType.value == 'rider'
                          ? AppTheme.primaryColor
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.person,
                        size: 48,
                        color: controller.selectedUserType.value == 'rider'
                            ? AppTheme.primaryColor
                            : Colors.grey[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ride',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: controller.selectedUserType.value == 'rider'
                              ? AppTheme.primaryColor
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => controller.setUserType('driver'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: controller.selectedUserType.value == 'driver'
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: controller.selectedUserType.value == 'driver'
                          ? AppTheme.primaryColor
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.drive_eta,
                        size: 48,
                        color: controller.selectedUserType.value == 'driver'
                            ? AppTheme.primaryColor
                            : Colors.grey[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Drive',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: controller.selectedUserType.value == 'driver'
                              ? AppTheme.primaryColor
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        )),
        const SizedBox(height: 32),
        
        // Send OTP button
        SizedBox(
          width: double.infinity,
          child: Obx(() => ElevatedButton(
            onPressed: controller.isLoading.value
              ? null
              : controller.sendOTP,
            child: controller.isLoading.value
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Send Verification Code'),
          )),
        ),
      ],
    );
  }
  
  Widget _buildOtpInput(BuildContext context) {
    final TextEditingController otpController = TextEditingController();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter the 6-digit code sent to ${controller.phoneNumber.value}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 32),
        
        // OTP input
        PinCodeTextField(
          appContext: context,
          length: 6,
          obscureText: false,
          animationType: AnimationType.fade,
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(8),
            fieldHeight: 50,
            fieldWidth: 40,
            activeFillColor: Colors.white,
            inactiveFillColor: Colors.grey[100],
            selectedFillColor: Colors.white,
            activeColor: AppTheme.primaryColor,
            inactiveColor: Colors.grey[300],
            selectedColor: AppTheme.primaryColor,
          ),
          animationDuration: const Duration(milliseconds: 300),
          backgroundColor: Colors.transparent,
          enableActiveFill: true,
          controller: otpController,
          onCompleted: (v) {
            controller.verifyOTP(v);
          },
          onChanged: (value) {
            // Nothing to do here
          },
          beforeTextPaste: (text) {
            return true;
          },
        ),
        const SizedBox(height: 24),
        
        // Error message
        if (controller.error.value.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.error.value,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        
        // Verify button
        SizedBox(
          width: double.infinity,
          child: Obx(() => ElevatedButton(
            onPressed: controller.isLoading.value
              ? null
              : () => controller.verifyOTP(otpController.text),
            child: controller.isLoading.value
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Verify'),
          )),
        ),
        const SizedBox(height: 16),
        
        // Resend code
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Didn\'t receive the code?',
              style: TextStyle(color: Colors.grey[600]),
            ),
            TextButton(
              onPressed: () {
                controller.verificationId.value = '';
                controller.error.value = '';
              },
              child: const Text('Resend'),
            ),
          ],
        ),
      ],
    );
  }
}
