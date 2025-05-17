import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/modules/driver/controllers/driver_controller.dart';
import 'package:easy_ride/models/driver_model.dart';
import 'package:lottie/lottie.dart';

class DriverVerificationView extends GetView<DriverController> {
  const DriverVerificationView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Verification'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isVerified.value) {
            return _buildVerifiedView();
          } else {
            return _buildVerificationProcess();
          }
        }),
      ),
    );
  }

  Widget _buildVerifiedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/verification_success.json',
            width: 200,
            height: 200,
            repeat: false,
          ),
          const SizedBox(height: 24),
          const Text(
            'Verification Complete!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Your account has been verified. You can now go online and start accepting ride requests.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Go to Dashboard',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationProcess() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Complete Your Verification',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please upload the required documents to verify your account. This helps ensure safety and trust in our community.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          
          // Stepper for verification process
          Obx(() => Stepper(
            currentStep: controller.currentVerificationStep.value,
            onStepTapped: (step) {
              controller.currentVerificationStep.value = step;
            },
            controlsBuilder: (context, details) {
              return const SizedBox.shrink(); // Hide default controls
            },
            steps: [
              _buildVerificationStep(
                'Driver\'s License',
                'Upload a clear photo of your driver\'s license',
                'driver_license',
                controller.documentStatus['driverLicense'] ?? VerificationStatus.pending,
              ),
              _buildVerificationStep(
                'Vehicle Registration',
                'Upload a clear photo of your vehicle registration',
                'vehicle_registration',
                controller.documentStatus['vehicleRegistration'] ?? VerificationStatus.pending,
              ),
              _buildVerificationStep(
                'Insurance Document',
                'Upload a clear photo of your insurance document',
                'insurance',
                controller.documentStatus['insurance'] ?? VerificationStatus.pending,
              ),
              _buildVerificationStep(
                'Address Proof',
                'Upload a clear photo of a utility bill or other address proof',
                'address_proof',
                controller.documentStatus['addressProof'] ?? VerificationStatus.pending,
              ),
              _buildVerificationStep(
                'Selfie with Documents',
                'Upload a selfie of yourself holding your driver\'s license and address proof',
                'selfie_with_documents',
                controller.documentStatus['selfieWithDocuments'] ?? VerificationStatus.pending,
              ),
            ],
          )),
          
          const SizedBox(height: 24),
          
          // Rejection reason if any
          Obx(() => controller.rejectionReason.value.isNotEmpty
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verification Rejected',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reason: ${controller.rejectionReason.value}',
                      style: TextStyle(
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please resubmit the required documents with the corrections mentioned above.',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink()
          ),
          
          const SizedBox(height: 24),
          
          // Verification status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verification Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Our team will review your documents within 24-48 hours. You\'ll be notified once the verification is complete.',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _calculateVerificationProgress(),
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_calculateVerificationProgress() * 100).toStringAsFixed(0)}% Complete',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Step _buildVerificationStep(
    String title,
    String description,
    String documentType,
    VerificationStatus status,
  ) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (status) {
      case VerificationStatus.approved:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Approved';
        break;
      case VerificationStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
      case VerificationStatus.pending:
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Pending';
        break;
    }
    
    return Step(
      title: Row(
        children: [
          Text(title),
          const SizedBox(width: 8),
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      subtitle: Text(description),
      content: Column(
        children: [
          if (status == VerificationStatus.rejected)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please resubmit this document',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _uploadDocument(documentType),
            icon: const Icon(Icons.upload_file),
            label: Text(status == VerificationStatus.rejected ? 'Reupload Document' : 'Upload Document'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
      isActive: true,
      state: status == VerificationStatus.approved
          ? StepState.complete
          : status == VerificationStatus.rejected
              ? StepState.error
              : StepState.indexed,
    );
  }

  void _uploadDocument(String documentType) async {
    final ImagePicker picker = ImagePicker();
    
    // Show image source dialog
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Image Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                Get.back();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                if (image != null) {
                  await controller.uploadVerificationDocument(
                    documentType,
                    File(image.path),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Get.back();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (image != null) {
                  await controller.uploadVerificationDocument(
                    documentType,
                    File(image.path),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  double _calculateVerificationProgress() {
    if (controller.documentStatus.isEmpty) return 0.0;
    
    int totalDocuments = controller.documentStatus.length;
    int approvedDocuments = controller.documentStatus.values
        .where((status) => status == VerificationStatus.approved)
        .length;
    
    return approvedDocuments / totalDocuments;
  }
}
