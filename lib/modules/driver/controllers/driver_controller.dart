import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_ride/core/services/auth_service.dart';
import 'package:easy_ride/core/services/firebase_service.dart';
import 'package:easy_ride/core/services/location_service.dart';
import 'package:easy_ride/core/services/notification_service.dart';
import 'package:easy_ride/core/utils/logs.dart';
import 'package:easy_ride/core/values/constants.dart';
import 'package:easy_ride/models/driver_model.dart';
import 'package:easy_ride/models/location_model.dart';
import 'package:easy_ride/models/ride_model.dart';
import 'package:easy_ride/models/ride_request_model.dart';
import 'package:easy_ride/modules/driver/services/voice_navigation_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_ride/core/services/storage_service.dart';
import 'package:easy_ride/models/user_model.dart';
import 'dart:math';
import '../../../core/theme/app_theme.dart';
import '../models/driver.dart';
import 'package:easy_ride/routes/app_pages.dart';
import 'package:easy_ride/models/vehicle_model.dart';
import 'package:location/location.dart' as loc;
import 'package:easy_ride/models/ride_status.dart';
import 'package:easy_ride/modules/driver/models/earnings_model.dart';
import 'package:easy_ride/modules/driver/widgets/ride_request_modal.dart';

enum VerificationStatus {
  pending,
  approved,
  rejected,
  notSubmitted
}

class DriverController extends GetxController {
  // Services
  final AuthService _authService = Get.find();
  final FirebaseService firebaseService = Get.find();
  final LocationService _locationService = Get.find();
  final NotificationService _notificationService = Get.find();
  final VoiceNavigationService _voiceNavigationService = Get.find();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = Get.find<StorageService>();

  // Driver data
  final Rx<DriverModel?> currentDriver = Rx<DriverModel?>(null);
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final Rx<DriverStatus> driverStatus = DriverStatus.offline.obs;
  final RxBool isOnline = false.obs;
  final RxBool isVerified = false.obs;
  final RxBool isVerificationPending = true.obs;
  final RxMap<String, VerificationStatus> documentStatus = <String, VerificationStatus>{}.obs;
  final RxInt currentVerificationStep = 0.obs;
  final RxString rejectionReason = ''.obs;

  // Location tracking
  final Rx<LocationModel?> currentLocation = Rx<LocationModel?>(null);
  StreamSubscription<Position>? _locationSubscription;
  final RxBool isFollowingUser = true.obs;

  // Map state
  final Rx<GoogleMapController?> mapController = Rx<GoogleMapController?>(null);
  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxSet<Polyline> polylines = <Polyline>{}.obs;
  final RxSet<Circle> circles = <Circle>{}.obs;
  final RxString mapType = 'normal'.obs;
  final RxBool showTraffic = false.obs;
  final RxBool isMapLoading = true.obs;
  final RxDouble mapZoom = 15.0.obs;
  final Rx<CameraPosition> initialCameraPosition = Rx<CameraPosition>(
    const CameraPosition(
      target: LatLng(37.42796133580664, -122.085749655962),
      zoom: 14.4746,
    ),
  );

  // Ride requests and active ride
  final Rx<RideRequest?> pendingRideRequest = Rx<RideRequest?>(null);
  final Rx<RideModel?> activeRide = Rx<RideModel?>(null);
  final Rx<RideRequest?> incomingRideRequest = Rx<RideRequest?>(null);
  final RxBool hasIncomingRequest = false.obs;
  final RxDouble requestTimeRemaining = 30.0.obs;
  final RxBool isRideAccepted = false.obs;
  final Rx<RideModel?> currentRide = Rx<RideModel?>(null);
  final Rx<UserModel?> riderInfo = Rx<UserModel?>(null);

  // Navigation
  final RxBool isNavigating = false.obs;
  final RxList<LatLng> routePoints = <LatLng>[].obs;
  final RxString navigationInstructions = ''.obs;
  final RxDouble distanceToDestination = 0.0.obs;
  final RxInt estimatedTimeInMinutes = 0.obs;

  // Earnings
  final RxDouble todayEarnings = 0.0.obs;
  final RxDouble weeklyEarnings = 0.0.obs;
  final RxDouble monthlyEarnings = 0.0.obs;
  final RxDouble totalEarnings = 0.0.obs;
  final RxInt completedRides = 0.obs;

  // Ride history
  final RxList<RideModel> rideHistory = <RideModel>[].obs;
  final RxBool isLoadingRideHistory = false.obs;

  // UI state
  final RxBool showRideRequestModal = false.obs;
  final RxInt rideRequestCountdown = 30.obs;
  final RxInt selectedNavIndex = 0.obs;
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;
  final RxString error = ''.obs;

  // Timers and subscriptions
  Timer? _rideRequestTimer;
  Timer? _requestTimer;
  StreamSubscription? _rideRequestSubscription;
  StreamSubscription? _currentRideSubscription;

  // Add these to the class variables section
  final RxBool isCompletingRide = false.obs;
  final RxBool paymentReceived = false.obs;
  final RxBool isPaymentAcknowledged = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _disposeResources();
    super.onClose();
  }

  // MARK: - Initialization Methods

  Future<void> _initialize() async {
    DevLogs.info('DriverController initialized');
    await _loadUserData();
    await _initializeDriver();
    _setupListeners();
    _initLocationTracking();
    _checkDriverVerification();
    _listenForRideRequests();

    // Add a delay to ensure location is obtained before updating the map
    Future.delayed(Duration(seconds: 1), () {
      _updateInitialMapPosition();
    });
  }

  // Add a new method to update the initial map position
  void _updateInitialMapPosition() {
    if (currentLocation.value != null &&
        currentLocation.value!.latitude != 0 &&
        currentLocation.value!.longitude != 0) {

      initialCameraPosition.value = CameraPosition(
        target: LatLng(currentLocation.value!.latitude, currentLocation.value!.longitude),
        zoom: 15.0,
      );

      if (mapController.value != null) {
        mapController.value!.animateCamera(
          CameraUpdate.newLatLngZoom(
              LatLng(currentLocation.value!.latitude, currentLocation.value!.longitude),
              15.0
          ),
        );
        DevLogs.info('Map centered on driver location: ${currentLocation.value!.latitude}, ${currentLocation.value!.longitude}');
      }
    } else {
      // If location is not available yet, try again after a delay
      DevLogs.warning('Driver location not available yet, retrying...');
      Future.delayed(Duration(seconds: 2), () {
        _updateInitialMapPosition();
      });
    }
  }

  void _disposeResources() {
    _locationSubscription?.cancel();
    _rideRequestTimer?.cancel();
    _rideRequestSubscription?.cancel();
    _currentRideSubscription?.cancel();
    _requestTimer?.cancel();
    mapController.value?.dispose();
  }

  // Fix the _loadUserData method to use proper document paths

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get user data
        final userDoc = await _firestore.collection(Constants.usersCollection).doc(user.uid).get();

        if (userDoc.exists) {
          currentUser.value = UserModel.fromMap(userDoc.data() as Map<String, dynamic>, user.uid);

          // Get driver data
          final driverDoc = await _firestore.collection(Constants.driversCollection).doc(user.uid).get();

          DevLogs.info(driverDoc.data().toString());

          if (driverDoc.exists) {
            currentDriver.value = DriverModel.fromJson(driverDoc.data() as Map<String, dynamic>);

            // Load earnings
            await _loadEarnings();
          } else {
            // Create driver profile if it doesn't exist
            await _createDriverProfile(user.uid);
          }
        }
      }
    } catch (e) {
      DevLogs.error('Error loading user data', exception: e);
    }
  }

  Future<void> _createDriverProfile(String userId) async {
    try {
      DevLogs.info('Creating missing driver profile for user $userId');

      // Get user data
      final userDoc = await _firestore.collection(Constants.usersCollection).doc(userId).get();
      if (!userDoc.exists) {
        DevLogs.error('User document not found for uid: $userId');
        return;
      }

      final userData = userDoc.data()!;
      final userModel = UserModel.fromMap(userData, userId);

      // Check if user is actually a driver
      if (userModel.userType != 'driver') {
        DevLogs.error('Cannot create driver profile for non-driver user: $userId');
        return;
      }

      // Create a default vehicle model
      // Create a default vehicle model
      final defaultVehicle = VehicleModel(
        id: 'default',
        make: '',
        model: '',
        year: DateTime.now().year.toString(),
        color: '',
        licensePlate: '',
        features: [],
        photos: [],
        vehicleType: 'sedan',
        capacity: 4,
      );


      // Create a default location
      final defaultLocation = LocationModel(
        latitude: 0.0,
        longitude: 0.0,
        address: '',
        name: '',
      );

      // Create driver document
      await _firestore.collection(Constants.driversCollection).doc(userId).set({
        'id': userId,
        'user': userModel.toMap(),
        'licenseNumber': '',
        'licenseExpiry': '',
        'documents': {},
        'isVerified': false,
        'verificationStatus': 'pending',
        'rating': 0.0,
        'totalRides': 0,
        'vehicle': defaultVehicle.toJson(),
        'currentLocation': defaultLocation.toJson(),
        'status': 'offline',
        'isOnline': false,
        'lastStatusUpdate': FieldValue.serverTimestamp(),
        'totalEarnings': 0.0,
        'fcmToken': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create driver location document
      await _firestore.collection(Constants.driverLocationsCollection).doc(userId).set({
        'driverId': userId,
        'location': GeoPoint(0, 0),
        'status': 'offline',
        'isOnline': false,
        'isBusy': false,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Reload driver data
      final newDriverDoc = await _firestore.collection(Constants.driversCollection).doc(userId).get();
      if (newDriverDoc.exists) {
        currentDriver.value = DriverModel.fromJson(newDriverDoc.data() as Map<String, dynamic>);
      }

      DevLogs.info('Driver profile created successfully');
    } catch (e) {
      DevLogs.error('Error creating driver profile', exception: e);
    }
  }

  Future<void> _initializeDriver() async {
    try {
      isMapLoading.value = true;

      // Get current user ID
      final user = _auth.currentUser;
      if (user == null) {
        DevLogs.error('DriverController No user logged in');
        return;
      }

      // Get driver data if not already loaded
      if (currentDriver.value == null) {
        final driverDoc = await _firestore.collection(Constants.driversCollection).doc(user.uid).get();

        if (driverDoc.exists) {
          currentDriver.value = DriverModel.fromJson(driverDoc.data() as Map<String, dynamic>);
        } else {
          // Create driver profile if it doesn't exist
          await _createDriverProfile(user.uid);

          if (currentDriver.value == null) {
            DevLogs.error('DriverController No driver profile found for user ${user.uid}');
            return;
          }
        }
      }

      // Set initial status
      driverStatus.value = currentDriver.value?.status ?? DriverStatus.offline;
      isOnline.value = driverStatus.value != DriverStatus.offline;

      // Start location tracking if driver is online
      if (driverStatus.value != DriverStatus.offline) {
        _startLocationTracking();
      }

      // Check for active ride
      await _checkForActiveRide();

      // Load earnings data
      await _loadEarningsData();

      // Load ride history
      await loadRideHistory();

    } catch (e) {
      DevLogs.error('DriverController Error initializing driver: $e');
    } finally {
      isMapLoading.value = false;
    }
  }

  void _setupListeners() {
    // Create custom streams for notifications since the service doesn't have them
    firebaseService.firestore
        .collection(Constants.rideRequestsCollection)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data()!;
          final rideRequest = RideRequest.fromJson(data);
          _handleIncomingRideRequest(rideRequest);
        }
      }
    });

    // Listen for ride cancellations
    firebaseService.firestore
        .collection(Constants.ridesCollection)
        .where('status', isEqualTo: 'cancelled')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data()!;
          if (data['cancelledBy'] == 'rider') {
            _handleRideCancellation(change.doc.id);
          }
        }
      }
    });
  }

  // MARK: - Location Tracking

  // Update the _initLocationTracking method to be more robust
  void _initLocationTracking() {
    DevLogs.debug('Initializing location tracking in DriverController');

    // Get initial location from LocationService if available
    final locationService = Get.find<LocationService>();
    if (locationService.currentLocation.value != null &&
        locationService.currentLocation.value!.latitude != null &&
        locationService.currentLocation.value!.longitude != null) {

      currentLocation.value = LocationModel(
          latitude: locationService.currentLocation.value!.latitude!,
          longitude: locationService.currentLocation.value!.longitude!,
          address: '',
          name: ''
      );

      DevLogs.info('Initial location set from LocationService: ${currentLocation.value!.latitude}, ${currentLocation.value!.longitude}');
    }

    _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // Update every 5 meters
        )
    ).listen(_handleLocationUpdate);
  }

  void _handleLocationUpdate(Position position) {
    currentLocation.value = LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        address: '',
        name: ""
    );

    if (isFollowingUser.value && mapController.value != null) {
      mapController.value!.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    }

    if (driverStatus.value != DriverStatus.offline) {
      _updateDriverLocation();
    }

    // Update navigation if in progress
    if (isNavigating.value) {
      _updateNavigation();
    }
  }

  void _startLocationTracking() {
    _locationSubscription ??= Geolocator.getPositionStream().listen(_handleLocationUpdate);
  }

  void _stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  Future<void> _updateDriverLocation() async {
    try {
      final user = _auth.currentUser;
      if (user != null && currentLocation.value != null) {
        await _firestore.collection(Constants.driverLocationsCollection).doc(user.uid).set({
          'location': GeoPoint(
            currentLocation.value!.latitude,
            currentLocation.value!.longitude,
          ),
          'status': driverStatus.value.toString().split('.').last,
          'isOnline': driverStatus.value != DriverStatus.offline,
          'isBusy': driverStatus.value == DriverStatus.busy,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      DevLogs.error('Error updating driver location', exception: e);
    }
  }

  // MARK: - Driver Status Management

  // Fix the _checkDriverVerification method to use proper document paths

  Future<void> _checkDriverVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final driverDoc = await _firestore.collection(Constants.driversCollection).doc(user.uid).get();

        if (driverDoc.exists) {
          final Map<String, dynamic> data = driverDoc.data() as Map<String, dynamic>;
          isVerificationPending.value = data['verificationStatus'] != 'approved';
          isVerified.value = data['verificationStatus'] == 'approved';

          // Update document status map
          if (data.containsKey('documents')) {
            final documents = data['documents'] as Map<String, dynamic>;
            documents.forEach((key, value) {
              if (value is Map<String, dynamic> && value.containsKey('status')) {
                final status = value['status'];
                if (status == 'approved') {
                  documentStatus[key] = VerificationStatus.approved;
                } else if (status == 'rejected') {
                  documentStatus[key] = VerificationStatus.rejected;
                  if (value.containsKey('rejectionReason')) {
                    rejectionReason.value = value['rejectionReason'] ?? '';
                  }
                } else if (status == 'pending') {
                  documentStatus[key] = VerificationStatus.pending;
                }
              }
            });
          }
        } else {
          // No driver document exists yet
          isVerificationPending.value = true;
          isVerified.value = false;

          // Create driver profile if it doesn't exist
          await _createDriverProfile(user.uid);
        }
      }
    } catch (e) {
      DevLogs.error('Error checking driver verification', exception: e);
    }
  }

  Future<void> updateDriverStatus(DriverStatus status) async {
    try {
      // Prevent going online if not verified
      if (status != DriverStatus.offline && !isVerified.value) {
        Get.snackbar(
          'Verification Required',
          'You must complete the verification process before going online.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // If driver is busy, they can't go offline
      if (driverStatus.value == DriverStatus.busy && status == DriverStatus.offline) {
        Get.snackbar(
          'Cannot Change Status',
          'You cannot go offline while on an active ride.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Update local state
      final previousStatus = driverStatus.value;
      driverStatus.value = status;
      isOnline.value = status != DriverStatus.offline;

      // Start or stop location tracking
      if (status != DriverStatus.offline) {
        _startLocationTracking();
      } else {
        _stopLocationTracking();
      }

      // Update in Firestore
      await _updateDriverStatusInFirestore(status);

      // Update FCM token when going online
      if (status != DriverStatus.offline && previousStatus == DriverStatus.offline) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await firebaseService.firestore
              .collection(Constants.driversCollection)
              .doc(currentDriver.value!.id)
              .update({
            'fcmToken': token,
          });
        }
      }

      Get.snackbar(
        'Status Updated',
        'You are now ${status == DriverStatus.online ? 'online' : status == DriverStatus.busy ? 'busy' : 'offline'}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: status == DriverStatus.online ? Colors.green : status == DriverStatus.busy ? Colors.orange : Colors.grey,
        colorText: Colors.white,
      );

    } catch (e) {
      DevLogs.error('DriverController Error updating driver status: $e');
      // Revert local state on error
      driverStatus.value = driverStatus.value;

      Get.snackbar(
        'Error',
        'Failed to update status. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> toggleOnlineStatus() async {
    // Check if driver is verified before allowing to go online
    if (driverStatus.value == DriverStatus.offline && !isVerified.value) {
      Get.snackbar(
        'Verification Required',
        'You must complete the verification process before going online.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Prompt to complete verification
      final bool goToVerification = await Get.dialog(
        AlertDialog(
          title: const Text('Verification Required'),
          content: const Text('You need to complete the verification process before you can go online. Would you like to complete your verification now?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Complete Verification'),
            ),
          ],
        ),
      ) ?? false;

      if (goToVerification) {
        Get.toNamed(Routes.driverVerification);
      }

      return;
    }

    final newStatus = driverStatus.value == DriverStatus.offline
        ? DriverStatus.online
        : DriverStatus.offline;

    await updateDriverStatus(newStatus);
  }

  Future<void> _updateDriverStatusInFirestore(DriverStatus status) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection(Constants.driverLocationsCollection).doc(user.uid).update({
          'status': status.toString().split('.').last,
          'isOnline': status != DriverStatus.offline,
          'isBusy': status == DriverStatus.busy,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Also update the driver document
        await _firestore.collection(Constants.driversCollection).doc(user.uid).update({
          'status': status.toString().split('.').last,
          'isOnline': status != DriverStatus.offline,
          'lastStatusUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      DevLogs.error('Error updating driver status in Firestore', exception: e);
      throw e; // Rethrow to handle in the calling method
    }
  }

  // MARK: - Ride Request Handling

  void _listenForRideRequests() {
    final user = _auth.currentUser;
    if (user == null) return;

    _rideRequestSubscription?.cancel();

    _rideRequestSubscription = _firestore
        .collection(Constants.rideRequestsCollection)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      if (driverStatus.value != DriverStatus.online || isRideAccepted.value) return;

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data()!;
          final rideRequest = RideRequest.fromJson(data);

          // Check if the request is within the driver's radius
          final pickupLat = rideRequest.pickupLocation.latitude ?? 0.0;
          final pickupLng = rideRequest.pickupLocation.longitude ?? 0.0;
          final pickupLocation = LatLng(pickupLat, pickupLng);

          if (currentLocation.value == null) continue;

          final distance = _calculateDistance(
            currentLocation.value!.latitude,
            currentLocation.value!.longitude,
            pickupLocation.latitude,
            pickupLocation.longitude,
          );

          // If within 5km radius, show the request
          if (distance <= 5.0) {

            incomingRideRequest.value = rideRequest.copyWith(distance: distance, id: change.doc.id);

            hasIncomingRequest.value = true;
            _startRequestTimer();

            // Add a circle to show the pickup location
            _addPickupCircle(pickupLocation);
          }
        }
      }
    });
  }

  void _handleIncomingRideRequest(RideRequest rideRequestData) {
    try {
      // Only process if driver is online and not busy
      if (driverStatus.value != DriverStatus.online) {
        return;
      }

      // Check if the request is within the driver's radius
      final pickupLat = rideRequestData.pickupLocation.latitude ?? 0.0;
      final pickupLng = rideRequestData.pickupLocation.longitude ?? 0.0;
      final pickupLocation = LatLng(pickupLat, pickupLng);

      if (currentLocation.value == null) return;

      final distance = _calculateDistance(
        currentLocation.value!.latitude,
        currentLocation.value!.longitude,
        pickupLocation.latitude,
        pickupLocation.longitude,
      );

      // If within 5km radius, show the request
      if (distance <= 5.0) {
        // Convert to RideRequestModel if needed
        try {
          pendingRideRequest.value = rideRequestData;
        } catch (e) {
          // If conversion fails, use the raw data
          incomingRideRequest.value = rideRequestData.copyWith(distance: distance);
        }

        // Show ride request modal
        _showRideRequestModal();

        // Add a circle to show the pickup location
        _addPickupCircle(pickupLocation);
      }
    } catch (e) {
      DevLogs.error('DriverController Error handling ride request: $e');
    }
  }

  void _showRideRequestModal() {
    showRideRequestModal.value = true;
    rideRequestCountdown.value = 30;
    hasIncomingRequest.value = true;

    // Start countdown timer
    _rideRequestTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (rideRequestCountdown.value > 0) {
        rideRequestCountdown.value--;
      } else {
        // Auto-reject if timer expires
        rejectRideRequest();
        timer.cancel();
      }
    });
  }

  void _startRequestTimer() {
    requestTimeRemaining.value = 30.0;
    _requestTimer?.cancel();

    _requestTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (requestTimeRemaining.value <= 0) {
        timer.cancel();
        declineRideRequest();
      } else {
        requestTimeRemaining.value--;
      }
    });
  }

  void _addPickupCircle(LatLng position) {
    final circle = Circle(
      circleId: const CircleId('pickup_location'),
      center: position,
      radius: 300, // 300 meters
      fillColor: Colors.blue.withOpacity(0.3),
      strokeColor: Colors.blue,
      strokeWidth: 2,
    );

    circles.value = {circle};
  }

  Future<void> acceptRideRequest() async {
    if (pendingRideRequest.value == null) return;

    _requestTimer?.cancel();
    _rideRequestTimer?.cancel();

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      String? requestId;
      String rideId;

      // Handle both types of ride requests
      if (pendingRideRequest.value != null) {
        requestId = pendingRideRequest.value!.id;
        rideId = requestId;
      } else {
        requestId = incomingRideRequest.value?.id;
        rideId = incomingRideRequest.value!.riderId;
      }

      // Update driver status to busy
      await updateDriverStatus(DriverStatus.busy);

      // Update the request status
      await _firestore.collection(Constants.rideRequestsCollection).doc(requestId).update({
        'status': 'accepted',
        'driverId': user.uid,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Update the ride with driver info
      await _firestore.collection(Constants.ridesCollection).doc(rideId).update({
        'status': 'accepted',
        'driverId': user.uid,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Start sharing location in real-time
      await _locationService.shareDriverLocationInRealTime(rideId, user.uid);

      // Get the ride details
      final rideDoc = await _firestore.collection(Constants.ridesCollection).doc(rideId).get();

      if (rideDoc.exists) {
        final rideData = rideDoc.data()!;
        final RideModel ride = RideModel.fromJson(rideData as String);
        currentRide.value = ride.copyWith(id: rideDoc.id);
        
        // Get rider info
        final riderId = ride.riderId;
        if (riderId != null) {
          final riderDoc = await _firestore.collection(Constants.usersCollection).doc(riderId).get();

          final UserModel rider = UserModel.fromMap(riderDoc.data() as Map<String, dynamic>, riderId);

          if (riderDoc.exists) {
            riderInfo.value = rider.copyWith(
              id: riderId,
            );
          }
        }

        // Listen for ride updates
        _listenForRideUpdates(rideId);

        // Send notification to rider
        await _sendNotification(
          riderId,
          'Driver Accepted',
          'A driver has accepted your ride request',
          {
            'type': 'ride_accepted',
            'rideId': rideId,
          },
        );

        isRideAccepted.value = true;
        hasIncomingRequest.value = false;
        incomingRideRequest.value = null;
        pendingRideRequest.value = null;
        showRideRequestModal.value = false;
        circles.clear();

        // Calculate route to pickup
        _calculateRouteToLocation(isPickup: true);
      }
    } catch (e) {
      DevLogs.error('Error accepting ride request', exception: e);
      Get.snackbar(
        'Error',
        'Failed to accept ride request',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> rejectRideRequest() async {
    if (pendingRideRequest.value == null) return;

    _requestTimer?.cancel();
    _rideRequestTimer?.cancel();

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      String requestId;
      String rideId;
      String riderId;

      // Handle both types of ride requests
      if (pendingRideRequest.value != null) {
        requestId = pendingRideRequest.value!.id;
        rideId = requestId; // In this case, they're the same
        riderId = pendingRideRequest.value!.riderId;
      } else {
        requestId = incomingRideRequest.value!.id;
        rideId = incomingRideRequest.value!.riderId ?? requestId;
        riderId = incomingRideRequest.value!.riderId;
      }

      // Update the request status to rejected
      await _firestore.collection(Constants.rideRequestsCollection).doc(requestId).update({
        'status': 'rejected',
        'driverId': user.uid,
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      // Update the ride with driver info
      await _firestore.collection(Constants.ridesCollection).doc(rideId).update({
        'status': 'rejected',
        'driverId': user.uid,
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to rider about rejection
      await _sendNotification(
        riderId,
        'Ride Rejected',
        'A driver has rejected your ride request',
        {
          'type': 'ride_rejected',
          'rideId': rideId,
        },
      );

      // Reset request state
      hasIncomingRequest.value = false;
      incomingRideRequest.value = null;
      pendingRideRequest.value = null;
      showRideRequestModal.value = false;

      // No need to update driver status to offline as that should be a separate decision
      // The driver might want to remain online to receive other requests

      DevLogs.info('Ride request rejected successfully');
    } catch (e) {
      DevLogs.error('Error rejecting ride request', exception: e);
      Get.snackbar(
        'Error',
        'Failed to reject ride request',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }


  void declineRideRequest() {
    rejectRideRequest();
  }

  // MARK: - Active Ride Management

  Future<void> _checkForActiveRide() async {
    try {
      final userId = _authService.currentUser.value!.id;
      if (userId == null || currentDriver.value == null) return;

      // Check for active ride
      final activeRideQuery = await firebaseService.firestore
          .collection(Constants.ridesCollection)
          .where('driverId', isEqualTo: currentDriver.value!.id)
          .where('status', whereIn: [
        'accepted',
        'arrived',
        'started',
      ])
          .limit(1)
          .get();

      if (activeRideQuery.docs.isNotEmpty) {
        final rideData = activeRideQuery.docs.first.data();

        final ride = RideModel.fromJson(rideData as String);

        currentRide.value = ride.copyWith(id: ride.id);

        // Get rider info
        final riderId = ride.riderId;

        if (riderId != null) {
          final riderDoc = await _firestore.collection(Constants.usersCollection).doc(riderId).get();
          if (riderDoc.exists) {
            final UserModel rider = UserModel.fromMap(riderDoc.data() as Map<String, dynamic>, riderId);

            if (riderDoc.exists) {
              riderInfo.value = rider.copyWith(
                id: riderId,
              );
            }
          }
        }

        // Set driver status to busy
        driverStatus.value = DriverStatus.busy;
        isRideAccepted.value = true;

        // Listen for ride updates
        _listenForRideUpdates(ride.id);

        // Start location tracking if not already started
        _startLocationTracking();

        // Start navigation based on ride status
        final status = ride.status;

        if (status == 'accepted') {
          _calculateRouteToLocation(isPickup: true);
        } else if (status == 'started') {
          _calculateRouteToLocation(isPickup: false);
        }
      }
    } catch (e) {
      DevLogs.error('DriverController Error checking for active ride: $e');
    }
  }

  void _listenForRideUpdates(String rideId) {
    _currentRideSubscription?.cancel();

    _currentRideSubscription = _firestore
        .collection(Constants.ridesCollection)
        .doc(rideId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {

        final ride = RideModel.fromMap(snapshot.data()!, rideId);

        currentRide.value = ride.copyWith(
          id: rideId,
        );


        if (ride.status == 'cancelled') {
          _resetRideState();

          Get.snackbar(
            'Ride Cancelled',
            'The ride has cancelled',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    });
  }

  Future<void> updateRideStatus(String status) async {
    if (currentRide == null) return;

    try {
      final rideId = currentRide.value?.id;

      await _firestore.collection(Constants.ridesCollection).doc(rideId).update({
        'status': status,
        '${status}At': FieldValue.serverTimestamp(),
      });

      // Send notification to rider
      final riderId = currentRide.value?.riderId;

      String title = '';
      String body = '';

      switch (status) {
        case 'arrived':
          title = 'Driver Arrived';
          body = 'Your driver has arrived at the pickup location';
          break;
        case 'started':
          title = 'Ride Started';
          body = 'Your ride has started';
          // Start navigation to destination
          _calculateRouteToLocation(isPickup: false);
          break;
        case 'completed':
          title = 'Ride Completed';
          body = 'Your ride has been completed';
          // Reset ride state and update driver status back to online
          _resetRideState();
          updateDriverStatus(DriverStatus.online);
          _loadEarnings();
          break;
      }

      await _sendNotification(
        riderId!,
        title,
        body,
        {
          'type': 'ride_${status}',
          'rideId': rideId,
        },
      );

      DevLogs.debug('Updated ride status to: $status');
    } catch (e) {
      DevLogs.error('Error updating ride status', exception: e);
      Get.snackbar(
        'Error',
        'Failed to update ride status',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void arrivedAtPickup() {
    updateRideStatus('arrived');
  }

  void startRide() {
    updateRideStatus('started');
  }

  Future<void> completeRide() async {
    if (currentRide == null) return;

    try {
      isCompletingRide.value = true;
      final rideId = currentRide.value?.id;

      // Update ride status to completed
      await _firestore.collection(Constants.ridesCollection).doc(rideId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'waitingForPayment': true,
      });

      // Send notification to rider
      final riderId = currentRide.value?.riderId;
      await _sendNotification(
        riderId!,
        'Ride Completed',
        'Your ride has been completed. Please complete the payment.',
        {
          'type': 'ride_completed',
          'rideId': rideId,
        },
      );

      // Start listening for payment status
      _listenForPaymentStatus(rideId!);

      DevLogs.debug('Ride marked as completed, waiting for payment');
    } catch (e) {
      isCompletingRide.value = false;
      DevLogs.error('Error completing ride', exception: e);
      Get.snackbar(
        'Error',
        'Failed to complete ride',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _listenForPaymentStatus(String rideId) {
    // Listen for payment status updates
    _firestore
        .collection(Constants.ridesCollection)
        .doc(rideId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        
        // Check if payment is completed
        if (data['isPaid'] == true && isCompletingRide.value) {
          isCompletingRide.value = false;
          paymentReceived.value = true;
          
          // Update earnings data
          _loadEarnings();
          DevLogs.info('Payment received for ride: $rideId');
        }
      }
    });
  }

  Future<void> acknowledgePayment() async {
    try {
      isPaymentAcknowledged.value = true;
      
      // Reset ride state and update driver status back to online
      _resetRideState();
      updateDriverStatus(DriverStatus.online);
      
      // Navigate back to home
      Get.offAllNamed(Routes.driverHome);
      
      DevLogs.info('Payment acknowledged, returned to home screen');
    } catch (e) {
      DevLogs.error('Error acknowledging payment', exception: e);
    }
  }

  Future<void> cancelRide() async {
    if (currentRide == null) return;

    try {
      // Show confirmation dialog
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: Text('Cancel Ride'),
          content: Text('Are you sure you want to cancel this ride? This may affect your rating.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Yes, Cancel'),
            ),
          ],
        ),
      );

      if (result != true) return;

      final rideId = currentRide.value?.id;

      await _firestore.collection(Constants.ridesCollection).doc(rideId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': 'driver',
        'cancellationReason': 'Cancelled by driver',
      });

      // Stop sharing location
      _locationService.stopSharingDriverLocation(rideId!);

      // Send notification to rider
      final riderId = currentRide.value?.riderId;

      await _sendNotification(
        riderId!,
        'Ride Cancelled',
        'Your ride has been cancelled by the driver',
        {
          'type': 'ride_cancelled',
          'rideId': rideId,
        },
      );

      // Reset ride state and update driver status back to online
      _resetRideState();
      updateDriverStatus(DriverStatus.online);

      DevLogs.debug('Cancelled ride: $rideId');
    } catch (e) {
      DevLogs.error('Error cancelling ride', exception: e);
      Get.snackbar(
        'Error',
        'Failed to cancel ride',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _resetRideState() {
    isRideAccepted.value = false;
    currentRide.value = null;
    riderInfo.value = null;
    isNavigating.value = false;
    routePoints.clear();
    polylines.clear();
    _currentRideSubscription?.cancel();
  }

  void _handleRideCancellation(String rideId) {
    try {
      if (currentRide.value?.id == rideId) {
        // Clear active ride
        _resetRideState();

        // Update driver status
        updateDriverStatus(DriverStatus.online);

        // Show notification
        Get.snackbar(
          'Ride Cancelled',
          'The rider has cancelled the ride.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      DevLogs.error('DriverController Error handling ride cancellation: $e');
    }
  }

  // MARK: - Navigation

  Future<void> _calculateRouteToLocation({required bool isPickup}) async {
    if (currentRide.value == null || currentLocation.value == null) return;

    try {
      final targetLat = isPickup
          ? currentRide.value?.pickup?.latitude ?? 0.0
          : currentRide.value?.dropoff?.latitude ?? 0.0;
      final targetLng = isPickup
          ? currentRide.value?.pickup?.longitude ?? 0.0
          : currentRide.value?.dropoff?.longitude ?? 0.0;

      if (targetLat == 0.0 || targetLng == 0.0) return;

      final targetLocation = LatLng(targetLat, targetLng);

      // Get directions from the LocationService
      final directions = await _locationService.getDirections(
        LatLng(currentLocation.value!.latitude, currentLocation.value!.longitude),
        targetLocation,
      );

      // Create polyline
      final polyline = Polyline(
        polylineId: const PolylineId('route'),
        color: Colors.blue,
        points: directions['polylinePoints'],
        width: 5,
      );

      polylines.value = {polyline};
      routePoints.value = directions['polylinePoints'];

      // Add target marker
      final targetMarker = Marker(
        markerId: MarkerId(isPickup ? 'pickup_location' : 'dropoff_location'),
        position: targetLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(
            isPickup ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed
        ),
        infoWindow: InfoWindow(
            title: isPickup ? 'Pickup' : 'Dropoff',
            snippet: isPickup ? currentRide.value?.pickup?.name : currentRide.value?.pickup?.name
        ),
      );

      // Add current location marker
      final currentLocationMarker = Marker(
        markerId: const MarkerId('current_location'),
        position: LatLng(currentLocation.value!.latitude, currentLocation.value!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Your Location'),
      );

      markers.value = {targetMarker, currentLocationMarker};

      // Fit map to show route
      _fitMapToRoute(directions['polylinePoints']);

      // Start navigation
      isNavigating.value = true;

      // Calculate ETA
      distanceToDestination.value = directions['distance'];
      estimatedTimeInMinutes.value = directions['duration'];

      // Update ride with ETA
      await _firestore.collection(Constants.ridesCollection).doc(currentRide.value?.id).update({
        'eta': estimatedTimeInMinutes.value,
      });

      // Start voice navigation
      _voiceNavigationService.speak(
        'Navigate to ${isPickup ? 'pickup' : 'dropoff'} location',
      );

      DevLogs.debug('Route calculated');
    } catch (e) {
      DevLogs.error('Error calculating route', exception: e);
    }
  }

  Future<void> _updateNavigation() async {
    try {
      if (!isNavigating.value || currentRide.value == null || currentLocation.value == null) return;

      final isPickupPhase = currentRide.value?.status == 'accepted';
      final targetLat = isPickupPhase
          ? currentRide.value?.pickup?.latitude ?? 0.0
          : currentRide.value?.dropoff?.latitude ?? 0.0;
      final targetLng = isPickupPhase
          ? currentRide.value?.pickup?.longitude ?? 0.0
          : currentRide.value?.dropoff?.longitude ?? 0.0;

      if (targetLat == 0.0 || targetLng == 0.0) return;

      final targetLocation = LatLng(targetLat, targetLng);

      // Check if we're close to destination
      final distanceInMeters = Geolocator.distanceBetween(
        currentLocation.value!.latitude,
        currentLocation.value!.longitude,
        targetLocation.latitude,
        targetLocation.longitude,
      );

      // If we're close to target location
      if (distanceInMeters < 50) {
        if (isPickupPhase) {
          // Arrived at pickup
          isNavigating.value = false;
          arrivedAtPickup();
        } else {
          // Arrived at dropoff - show completion dialog
          isNavigating.value = false;

          Get.dialog(
            AlertDialog(
              title: Text('Destination Reached'),
              content: Text('You have arrived at the destination. Complete the ride?'),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text('Not Yet'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Get.back();
                    completeRide();
                  },
                  child: Text('Complete Ride'),
                ),
              ],
            ),
          );

          // Voice notification
          _voiceNavigationService.speak('You have arrived at the destination');
        }
        return;
      }

      // Update current location marker
      final updatedMarkers = {...markers.value};
      updatedMarkers.removeWhere((m) => m.markerId.value == 'current_location');
      updatedMarkers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(currentLocation.value!.latitude, currentLocation.value!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
      markers.value = updatedMarkers;

      // Periodically recalculate route (every 30 seconds)
      final now = DateTime.now();
      if (now.second % 30 == 0) {
        _calculateRouteToLocation(isPickup: isPickupPhase);
      }
    } catch (e) {
      DevLogs.error('Error updating navigation', exception: e);
    }
  }

  void _fitMapToRoute(List<LatLng> points) {
    if (mapController.value == null || points.isEmpty) return;

    try {
      // Calculate bounds
      double minLat = points[0].latitude;
      double maxLat = points[0].latitude;
      double minLng = points[0].longitude;
      double maxLng = points[0].longitude;

      for (final point in points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }

      // Add padding
      final bounds = LatLngBounds(
        southwest: LatLng(minLat - 0.01, minLng - 0.01),
        northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
      );

      mapController.value!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    } catch (e) {
      DevLogs.error('Error fitting map to route', exception: e);
    }
  }

  // MARK: - Rider Communication

  Future<void> callRider() async {
    try {
      if (riderInfo.value == null) return;

      final phone = riderInfo.value?.phoneNumber ?? '';

      if (phone != null && phone.isNotEmpty) {
        // Launch phone call
        final url = 'tel:$phone';
        if (await canLaunch(url)) {
          await launch(url);
        } else {
          Get.snackbar(
            'Error',
            'Could not launch phone dialer.',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
        DevLogs.info('Calling rider: $phone');
      } else {
        Get.snackbar(
          'Error',
          'Rider phone number not available',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      DevLogs.error('Error calling rider', exception: e);
      Get.snackbar(
        'Error',
        'Failed to initiate call',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void messageRider() {
    if (currentRide.value == null || riderInfo.value == null) return;

    // Navigate to chat screen
    Get.toNamed(
      '/chat',
      arguments: {
        'rideId': currentRide.value!.id,
        'recipientId': currentRide.value?.riderId,
        'recipientName': '${riderInfo.value?.fullName}}',
      },
    );
    DevLogs.info('Opening chat with rider');
  }

  // MARK: - Earnings and History

  Future<void> _loadEarnings() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get today's earnings
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);

        final todayRides = await _firestore
            .collection(Constants.ridesCollection)
            .where('driverId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'completed')
            .where('completedAt', isGreaterThanOrEqualTo: startOfDay)
            .get();

        double todayTotal = 0;
        for (var doc in todayRides.docs) {
          final data = doc.data();
          todayTotal += (data['fare'] ?? 0) * 0.8; // Driver gets 80% of fare
        }

        todayEarnings.value = todayTotal;

        // Get weekly earnings
        final startOfWeek = DateTime(today.year, today.month, today.day - today.weekday + 1);

        final weeklyRides = await _firestore
            .collection(Constants.ridesCollection)
            .where('driverId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'completed')
            .where('completedAt', isGreaterThanOrEqualTo: startOfWeek)
            .get();

        double weeklyTotal = 0;
        for (var doc in weeklyRides.docs) {
          final data = doc.data();
          weeklyTotal += (data['fare'] ?? 0) * 0.8;
        }

        weeklyEarnings.value = weeklyTotal;

        // Get total earnings
        final allRides = await _firestore
            .collection(Constants.ridesCollection)
            .where('driverId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'completed')
            .get();

        double total = 0;
        for (var doc in allRides.docs) {
          final data = doc.data();
          total += (data['fare'] ?? 0) * 0.8;
        }

        totalEarnings.value = total;
      }
    } catch (e) {
      DevLogs.error('Error loading earnings', exception: e);
    }
  }

  Future<void> _loadEarningsData() async {
    try {
      if (currentDriver.value == null) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      // Get today's earnings
      final todayRidesQuery = await firebaseService.firestore
          .collection(Constants.ridesCollection)
          .where('driverId', isEqualTo: currentDriver.value!.id)
          .where('status', isEqualTo: 'completed')
          .where('endTime', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .get();

      double todayTotal = 0;
      for (var doc in todayRidesQuery.docs) {
        final data = doc.data();
        todayTotal += data['finalFare'] ?? data['fare'] ?? 0;
      }
      todayEarnings.value = todayTotal;

      // Get weekly earnings
      final weeklyRidesQuery = await firebaseService.firestore
          .collection(Constants.ridesCollection)
          .where('driverId', isEqualTo: currentDriver.value!.id)
          .where('status', isEqualTo: 'completed')
          .where('endTime', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .get();

      double weeklyTotal = 0;
      for (var doc in weeklyRidesQuery.docs) {
        final data = doc.data();
        weeklyTotal += data['finalFare'] ?? data['fare'] ?? 0;
      }
      weeklyEarnings.value = weeklyTotal;

      // Get monthly earnings
      final monthlyRidesQuery = await firebaseService.firestore
          .collection(Constants.ridesCollection)
          .where('driverId', isEqualTo: currentDriver.value!.id)
          .where('status', isEqualTo: 'completed')
          .where('endTime', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .get();

      double monthlyTotal = 0;
      for (var doc in monthlyRidesQuery.docs) {
        final data = doc.data();
        monthlyTotal += data['finalFare'] ?? data['fare'] ?? 0;
      }
      monthlyEarnings.value = monthlyTotal;

      // Get completed rides count
      completedRides.value = currentDriver.value!.totalRides;

    } catch (e) {
      DevLogs.error('DriverController Error loading earnings data: $e');
    }
  }

  Future<void> loadRideHistory() async {
    try {
      if (currentDriver.value == null) return;

      isLoadingRideHistory.value = true;

      final ridesQuery = await firebaseService.firestore
          .collection(Constants.ridesCollection)
          .where('driverId', isEqualTo: currentDriver.value!.id)
          .orderBy('requestTime', descending: true)
          .limit(50)
          .get();

      final rides = ridesQuery.docs
          .map((doc) => {
        ...doc.data(),
        'id': doc.id,
      })
          .toList();

      rideHistory.value = rides.map((data) => RideModel.fromJson(data as String)).toList();

    } catch (e) {
      DevLogs.error('DriverController Error loading ride history: $e');
    } finally {
      isLoadingRideHistory.value = false;
    }
  }

  void centerOnUserLocation() {
    if (currentLocation.value != null && mapController.value != null) {
      mapController.value!.animateCamera(
        CameraUpdate.newLatLngZoom(
            LatLng(currentLocation.value!.latitude, currentLocation.value!.longitude),
            15
        ),
      );
      isFollowingUser.value = true;
    }
  }

  // Update the setMapController method to center on user location
  void setMapController(GoogleMapController controller) {
    mapController.value = controller;

    // Center map on user location if available
    if (currentLocation.value != null &&
        currentLocation.value!.latitude != 0 &&
        currentLocation.value!.longitude != 0) {

      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
            LatLng(currentLocation.value!.latitude, currentLocation.value!.longitude),
            15.0
        ),
      );
      DevLogs.info('Map centered on driver location during controller setup');
    } else {
      DevLogs.warning('Driver location not available during map controller setup');
      // Try to get location and center map after a short delay
      Future.delayed(Duration(seconds: 1), () {
        if (currentLocation.value != null &&
            currentLocation.value!.latitude != 0 &&
            currentLocation.value!.longitude != 0) {

          controller.animateCamera(
            CameraUpdate.newLatLngZoom(
                LatLng(currentLocation.value!.latitude, currentLocation.value!.longitude),
                15.0
            ),
          );
          DevLogs.info('Map centered on driver location after delay');
        }
      });
    }
  }

  // MARK: - UI Controls

  void setNavIndex(int index) {
    selectedNavIndex.value = index;
  }

  void logout() {
    _auth.signOut();
    Get.offAllNamed('/login');
  }

  // MARK: - Utility Methods

  Future<void> _sendNotification(String userId, String title, String body, Map<String, dynamic> data) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection(Constants.usersCollection).doc(userId).get();
      if (!userDoc.exists) return;

      final fcmToken = userDoc.data()?['fcmToken'];
      if (fcmToken == null || fcmToken.isEmpty) return;

      // Send notification using Firebase Cloud Messaging
      await FirebaseMessaging.instance.sendMessage(
        to: fcmToken,
        data: {
          'title': title,
          'body': body,
          ...data,
        },
      );
    } catch (e) {
      DevLogs.error('Error sending notification', exception: e);
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // in km

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = (
        sin(dLat / 2) * sin(dLat / 2) +
            cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
                sin(dLon / 2) * sin(dLon / 2)
    );

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  double min(double a, double b) {
    return a < b ? a : b;
  }

  double max(double a, double b) {
    return a > b ? a : b;
  }

  Future<String?> uploadVerificationDocument(String documentType, File file) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        error.value = 'User not authenticated';
        return null;
      }

      DevLogs.info('Uploading $documentType document');

      // Use the storage service to upload the document
      final documentUrl = await _storageService.uploadDocumentImage(
          file,
          user.uid,
          documentType
      );

      if (documentUrl == null) {
        error.value = 'Failed to upload document';
        return null;
      }

      // Update the document status in Firestore
      await _firestore.collection(Constants.driversCollection).doc(user.uid).update({
        'documents.$documentType': {
          'url': documentUrl,
          'uploadedAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        }
      });

      // Update local state
      documentStatus[documentType] = VerificationStatus.pending;
      isVerificationPending.value = true;

      // Show success message
      Get.snackbar(
        'Document Uploaded',
        '$documentType has been uploaded successfully and is pending verification.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return documentUrl;
    } catch (e) {
      DevLogs.error('Error uploading verification document', exception: e);
      error.value = 'Failed to upload document: ${e.toString()}';

      Get.snackbar(
        'Upload Failed',
        'Failed to upload $documentType. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      return null;
    }
  }
}
