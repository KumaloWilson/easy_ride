import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/core/services/auth_service.dart';
import 'package:easy_ride/core/services/storage_service.dart';
import 'package:easy_ride/routes/app_pages.dart';

class DriverDocumentUploadView extends StatefulWidget {
  const DriverDocumentUploadView({Key? key}) : super(key: key);

  @override
  State<DriverDocumentUploadView> createState() => _DriverDocumentUploadViewState();
}

class _DriverDocumentUploadViewState extends State<DriverDocumentUploadView> {
  final AuthService _authService = Get.find<AuthService>();
  final StorageService _storageService = Get.find<StorageService>();
  final ImagePicker _imagePicker = ImagePicker();
  
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _vehicleColorController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  
  File? _driverLicenseImage;
  File? _vehicleRegistrationImage;
  File? _insuranceDocumentImage;
  
  bool _isLoading = false;
  String _error = '';
  
  @override
  void initState() {
    super.initState();
    _loadDriverDetails();
  }
  
  @override
  void dispose() {
    _vehicleTypeController.dispose();
    _vehicleModelController.dispose();
    _vehicleColorController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }
  
  Future<void> _loadDriverDetails() async {
    if (_authService.currentUser.value != null && 
        _authService.currentUser.value!.driverDetails != null) {
      final driverDetails = _authService.currentUser.value!.driverDetails!;
      
      setState(() {
        _vehicleTypeController.text = driverDetails['vehicleType'] ?? '';
        _vehicleModelController.text = driverDetails['vehicleModel'] ?? '';
        _vehicleColorController.text = driverDetails['vehicleColor'] ?? '';
        _licensePlateController.text = driverDetails['licensePlate'] ?? '';
      });
    }
  }
  
  Future<void> _pickImage(String type) async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (image != null) {
      setState(() {
        if (type == 'license') {
          _driverLicenseImage = File(image.path);
        } else if (type == 'registration') {
          _vehicleRegistrationImage = File(image.path);
        } else if (type == 'insurance') {
          _insuranceDocumentImage = File(image.path);
        }
      });
    }
  }
  
  Future<void> _takePhoto(String type) async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    
    if (image != null) {
      setState(() {
        if (type == 'license') {
          _driverLicenseImage = File(image.path);
        } else if (type == 'registration') {
          _vehicleRegistrationImage = File(image.path);
        } else if (type == 'insurance') {
          _insuranceDocumentImage = File(image.path);
        }
      });
    }
  }
  
  void _showImageSourceDialog(String type) {
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
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Get.back();
                _pickImage(type);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Get.back();
                _takePhoto(type);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _saveDriverDocuments() async {
    if (_vehicleTypeController.text.isEmpty ||
        _vehicleModelController.text.isEmpty ||
        _vehicleColorController.text.isEmpty ||
        _licensePlateController.text.isEmpty) {
      setState(() {
        _error = 'Please fill in all vehicle details';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = '';
    });
    
    try {
      final String userId = _authService.firebaseUser.value!.uid;
      
      // Upload documents if selected
      String? driverLicenseUrl;
      String? vehicleRegistrationUrl;
      String? insuranceDocumentUrl;
      
      if (_driverLicenseImage != null) {
        driverLicenseUrl = await _storageService.uploadDocumentImage(
          _driverLicenseImage!,
          userId,
          'driver_license',
        );
      }
      
      if (_vehicleRegistrationImage != null) {
        vehicleRegistrationUrl = await _storageService.uploadDocumentImage(
          _vehicleRegistrationImage!,
          userId,
          'vehicle_registration',
        );
      }
      
      if (_insuranceDocumentImage != null) {
        insuranceDocumentUrl = await _storageService.uploadDocumentImage(
          _insuranceDocumentImage!,
          userId,
          'insurance',
        );
      }
      
      // Get existing driver details
      Map<String, dynamic> existingDriverDetails = 
          _authService.currentUser.value?.driverDetails ?? {};
      
      // Update driver details
      Map<String, dynamic> driverDetails = {
        ...existingDriverDetails,
        'vehicleType': _vehicleTypeController.text,
        'vehicleModel': _vehicleModelController.text,
        'vehicleColor': _vehicleColorController.text,
        'licensePlate': _licensePlateController.text,
      };
      
      if (driverLicenseUrl != null) {
        driverDetails['driverLicenseUrl'] = driverLicenseUrl;
      }
      
      if (vehicleRegistrationUrl != null) {
        driverDetails['vehicleRegistrationUrl'] = vehicleRegistrationUrl;
      }
      
      if (insuranceDocumentUrl != null) {
        driverDetails['insuranceDocumentUrl'] = insuranceDocumentUrl;
      }
      
      // Update user data in Firestore
      await _authService.updateUserData({
        'driverDetails': driverDetails,
        'updatedAt': DateTime.now(),
      });
      
      Get.snackbar(
        'Success',
        'Driver documents updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      // Navigate to driver home
      Get.offAllNamed(Routes.driverHome);
    } catch (e) {
      setState(() {
        _error = 'Failed to save documents: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Documents'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vehicle Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              
              // Vehicle Type
              TextField(
                controller: _vehicleTypeController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Type',
                  hintText: 'e.g., Sedan, SUV, Hatchback',
                  prefixIcon: Icon(Icons.directions_car),
                ),
              ),
              const SizedBox(height: 16),
              
              // Vehicle Model
              TextField(
                controller: _vehicleModelController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Model',
                  hintText: 'e.g., Toyota Camry, Honda Civic',
                  prefixIcon: Icon(Icons.car_repair),
                ),
              ),
              const SizedBox(height: 16),
              
              // Vehicle Color
              TextField(
                controller: _vehicleColorController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Color',
                  hintText: 'e.g., Black, White, Silver',
                  prefixIcon: Icon(Icons.color_lens),
                ),
              ),
              const SizedBox(height: 16),
              
              // License Plate
              TextField(
                controller: _licensePlateController,
                decoration: const InputDecoration(
                  labelText: 'License Plate Number',
                  hintText: 'e.g., ABC123',
                  prefixIcon: Icon(Icons.confirmation_number),
                ),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Required Documents',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              
              // Driver License
              _buildDocumentUploadCard(
                title: 'Driver\'s License',
                description: 'Upload a clear photo of your driver\'s license',
                image: _driverLicenseImage,
                onTap: () => _showImageSourceDialog('license'),
              ),
              const SizedBox(height: 16),
              
              // Vehicle Registration
              _buildDocumentUploadCard(
                title: 'Vehicle Registration',
                description: 'Upload a clear photo of your vehicle registration',
                image: _vehicleRegistrationImage,
                onTap: () => _showImageSourceDialog('registration'),
              ),
              const SizedBox(height: 16),
              
              // Insurance Document
              _buildDocumentUploadCard(
                title: 'Insurance Document',
                description: 'Upload a clear photo of your insurance document',
                image: _insuranceDocumentImage,
                onTap: () => _showImageSourceDialog('insurance'),
              ),
              const SizedBox(height: 24),
              
              // Error message
              if (_error.isNotEmpty)
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
                          _error,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveDriverDocuments,
                  child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Save & Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDocumentUploadCard({
    required String title,
    required String description,
    required File? image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: image != null ? AppTheme.primaryColor : Colors.grey[300]!,
            width: image != null ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (image != null)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  image,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to upload',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
