import 'dart:async';
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_ride/core/services/auth_service.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class SafetyService extends GetxService {
  final AuthService _authService = Get.find<AuthService>();
  final Location _location = Location();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  final RxBool isEmergencyActive = false.obs;
  final RxBool isRecording = false.obs;
  final RxString recordingPath = ''.obs;
  final RxString emergencyContactName = ''.obs;
  final RxString emergencyContactPhone = ''.obs;
  
  StreamSubscription<LocationData>? _locationSubscription;
  Timer? _emergencyUpdateTimer;
  String? _emergencyId;
  
  Future<SafetyService> init() async {
    // Load emergency contact
    await _loadEmergencyContact();
    return this;
  }

  Future<bool> makePhoneCall(String phoneNumber) async {
    // Format the phone number into a valid tel: URI
    final Uri uri = Uri.parse('tel:$phoneNumber');

    // Check if the URL can be launched
    if (await canLaunchUrl(uri)) {
      // Launch the URL
      return await launchUrl(uri);
    } else {
      // Throw an exception if the URL can't be launched
      throw Exception('Could not launch $uri');
    }
  }

  Future<void> _loadEmergencyContact() async {
    if (_authService.firebaseUser.value != null) {
      try {
        final doc = await _firestore
            .collection('users')
            .doc(_authService.firebaseUser.value!.uid)
            .collection('settings')
            .doc('emergency')
            .get();
        
        if (doc.exists) {
          final data = doc.data();
          emergencyContactName.value = data?['name'] ?? '';
          emergencyContactPhone.value = data?['phone'] ?? '';
        }
      } catch (e) {
        print('Error loading emergency contact: $e');
      }
    }
  }
  
  Future<void> setEmergencyContact(String name, String phone) async {
    if (_authService.firebaseUser.value != null) {
      try {
        await _firestore
            .collection('users')
            .doc(_authService.firebaseUser.value!.uid)
            .collection('settings')
            .doc('emergency')
            .set({
              'name': name,
              'phone': phone,
              'updatedAt': FieldValue.serverTimestamp(),
            });
        
        emergencyContactName.value = name;
        emergencyContactPhone.value = phone;
      } catch (e) {
        print('Error setting emergency contact: $e');
        throw Exception('Failed to save emergency contact');
      }
    }
  }
  
  Future<void> activateEmergency({String? rideId, String? notes}) async {
    if (isEmergencyActive.value) return;
    
    try {
      // Create emergency record
      final userId = _authService.firebaseUser.value?.uid;
      if (userId == null) return;
      
      final locationData = await _location.getLocation();
      
      final emergency = {
        'userId': userId,
        'userType': _authService.currentUser.value?.userType,
        'rideId': rideId,
        'notes': notes,
        'status': 'active',
        'location': GeoPoint(
          locationData.latitude!,
          locationData.longitude!,
        ),
        'locationHistory': [
          {
            'location': GeoPoint(
              locationData.latitude!,
              locationData.longitude!,
            ),
            'timestamp': FieldValue.serverTimestamp(),
          }
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      final docRef = await _firestore.collection('emergencies').add(emergency);
      _emergencyId = docRef.id;
      
      // Start location tracking
      _startLocationTracking();
      
      // Set emergency active
      isEmergencyActive.value = true;
      
      // Contact emergency services if available
      if (emergencyContactPhone.value.isNotEmpty) {
        await _contactEmergencyContact();
      }
    } catch (e) {
      print('Error activating emergency: $e');
      throw Exception('Failed to activate emergency mode');
    }
  }
  
  Future<void> deactivateEmergency() async {
    if (!isEmergencyActive.value || _emergencyId == null) return;
    
    try {
      // Update emergency record
      await _firestore.collection('emergencies').doc(_emergencyId).update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Stop location tracking
      _stopLocationTracking();
      
      // Stop recording if active
      if (isRecording.value) {
        await stopRecording();
      }
      
      // Reset emergency state
      isEmergencyActive.value = false;
      _emergencyId = null;
    } catch (e) {
      print('Error deactivating emergency: $e');
      throw Exception('Failed to deactivate emergency mode');
    }
  }
  
  void _startLocationTracking() {
    // Cancel existing subscription if any
    _locationSubscription?.cancel();
    _emergencyUpdateTimer?.cancel();
    
    // Start location updates
    _locationSubscription = _location.onLocationChanged.listen((locationData) {
      if (_emergencyId != null && locationData.latitude != null && locationData.longitude != null) {
        _updateEmergencyLocation(locationData);
      }
    });
    
    // Set timer to ensure updates even if location doesn't change
    _emergencyUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _location.getLocation().then((locationData) {
        if (_emergencyId != null && locationData.latitude != null && locationData.longitude != null) {
          _updateEmergencyLocation(locationData);
        }
      });
    });
  }
  
  void _stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    
    _emergencyUpdateTimer?.cancel();
    _emergencyUpdateTimer = null;
  }
  
  Future<void> _updateEmergencyLocation(LocationData locationData) async {
    if (_emergencyId == null) return;
    
    try {
      await _firestore.collection('emergencies').doc(_emergencyId).update({
        'location': GeoPoint(
          locationData.latitude!,
          locationData.longitude!,
        ),
        'locationHistory': FieldValue.arrayUnion([
          {
            'location': GeoPoint(
              locationData.latitude!,
              locationData.longitude!,
            ),
            'timestamp': FieldValue.serverTimestamp(),
          }
        ]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating emergency location: $e');
    }
  }
  
  Future<void> _contactEmergencyContact() async {
    if (emergencyContactPhone.value.isEmpty) return;
    
    final Uri uri = Uri.parse('tel:${emergencyContactPhone.value}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
  
  Future<void> startRecording() async {
    if (isRecording.value) return;
    
    try {
      // Check permissions
      if (await _audioRecorder.hasPermission()) {
        // Get temp directory
        final tempDir = await getTemporaryDirectory();
        final now = DateTime.now();
        final formatter = DateFormat('yyyyMMdd_HHmmss');
        final fileName = 'recording_${formatter.format(now)}.m4a';
        final path = '${tempDir.path}/$fileName';
        
        // Start recording
        if (await _audioRecorder.hasPermission()) {
          // Start recording to file
          await _audioRecorder.start(const RecordConfig(), path: 'aFullPath/myFile.m4a');
          // ... or to stream
          final stream = await _audioRecorder.startStream(const RecordConfig(encoder: AudioEncoder.pcm16bits));

          recordingPath.value = path;
          isRecording.value = true;
        }

        
        // Update emergency record if active
        if (isEmergencyActive.value && _emergencyId != null) {
          await _firestore.collection('emergencies').doc(_emergencyId).update({
            'isRecording': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Error starting recording: $e');
      throw Exception('Failed to start recording');
    }
  }
  
  Future<String?> stopRecording() async {
    if (!isRecording.value) return null;
    
    try {
      // Stop recording
      final path = await _audioRecorder.stop();
      isRecording.value = false;
      
      // Update emergency record if active
      if (isEmergencyActive.value && _emergencyId != null) {
        await _firestore.collection('emergencies').doc(_emergencyId).update({
          'isRecording': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      return path;
    } catch (e) {
      print('Error stopping recording: $e');
      throw Exception('Failed to stop recording');
    }
  }
  
  Future<void> shareRecording() async {
    final path = await stopRecording();
    if (path == null) return;
    
    try {
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Emergency Recording',
        text: 'Emergency recording from Easy Ride app.',
      );
    } catch (e) {
      print('Error sharing recording: $e');
      throw Exception('Failed to share recording');
    }
  }
  
  @override
  void onClose() {
    _stopLocationTracking();
    _audioRecorder.dispose();
    super.onClose();
  }
}
