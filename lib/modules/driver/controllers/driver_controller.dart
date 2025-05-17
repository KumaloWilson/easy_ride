import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:easy_ride/core/services/auth_service.dart';
import 'package:easy_ride/core/services/location_service.dart';
import 'package:easy_ride/core/services/firebase_service.dart';
import 'package:easy_ride/core/services/notification_service.dart';
import 'package:easy_ride/core/services/api_service.dart';
import 'package:easy_ride/models/ride_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_ride/routes/app_pages.dart';
import 'package:easy_ride/models/driver_model.dart';
import 'package:easy_ride/models/user_model.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:easy_ride/core/services/storage_service.dart';
import 'package:easy_ride/core/utils/logs.dart';
import 'package:easy_ride/models/location_model.dart';
import 'package:easy_ride/core/values/constants.dart';
import 'package:url_launcher/url_launcher.dart';

enum VerificationStatus {
  pending,
  approved,
  rejected,
  notSubmitted
}

class DriverController extends GetxController {
  final AuthService authService = Get.find<AuthService>();
  final LocationService _locationService = Get.find<LocationService>();
  final FirebaseService firebaseService = Get.find<FirebaseService>();
  final StorageService _storageService = Get.find<StorageService>();
  final NotificationService _notificationService = Get.find<NotificationService>();
  final ApiService _apiService = Get.find<ApiService>();

  final Rx<GoogleMapController?> mapController = Rx<GoogleMapController?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  // Driver status
  final RxBool isOnline = false.obs;

  // Map related
  final Rx<CameraPosition> initialCameraPosition = Rx<CameraPosition>(
    const CameraPosition(
      target: LatLng(37.42796133580664, -122.085749655962),
      zoom: 14.4746,
    ),
  );
  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxSet<Polyline> polylines = <Polyline>{}.obs;
  final RxSet<Circle> circles = <Circle>{}.obs;
  final Rx<MapType> mapType = MapType.normal.obs;
  final RxBool showTraffic = false.obs;

  // Ride related
  final Rx<RideModel?> currentRide = Rx<RideModel?>(null);
  final RxList<RideModel> rideRequests = <RideModel>[].obs;
  final RxList<RideModel> rideHistory = <RideModel>[].obs;
  final Rx<RideModel?> incomingRideRequest = Rx<RideModel?>(null);
  final RxBool isRideAccepted = false.obs;
  final RxInt requestTimeRemaining = 30.obs;
  final RxBool isLoadingRideHistory = false.obs;

  // Rider info
  final Rx<Map<String, dynamic>?> riderInfo = Rx<Map<String, dynamic>?>(null);

  // Earnings
  final RxDouble todayEarnings = 0.0.obs;
  final RxDouble weeklyEarnings = 0.0.obs;
  final RxDouble totalEarnings = 0.0.obs;
  final RxInt completedRides = 0.obs;

  // Driver verification
  final RxBool isVerified = false.obs;
  final RxBool isVerificationPending = false.obs;
  final RxMap<String, VerificationStatus> documentStatus = <String, VerificationStatus>{}.obs;
  final RxInt currentVerificationStep = 0.obs;
  final RxString rejectionReason = ''.obs;

  // Navigation
  final RxInt selectedNavIndex = 0.obs;

  // Map state
  final RxBool isFollowingUser = true.obs;
  final RxDouble mapZoom = 15.0.obs;

  // Streams
  StreamSubscription? _locationSubscription;
  StreamSubscription? _rideRequestsSubscription;
  StreamSubscription? _currentRideSubscription;
  Timer? _requestTimer;

  // Theme
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    DevLogs.info('DriverController initialized');
    _initializeLocation();
    _listenToRideRequests();
    _listenToCurrentRide();
    fetchRideHistory();
    _calculateEarnings();
    _checkVerificationStatus();
  }

  @override
  void onClose() {
    _locationSubscription?.cancel();
    _rideRequestsSubscription?.cancel();
    _currentRideSubscription?.cancel();
    _requestTimer?.cancel();
    mapController.value?.dispose();
    DevLogs.info('DriverController disposed');
    super.onClose();
  }

  Future<void> _initializeLocation() async {
    DevLogs.debug('Initializing location tracking');
    await _locationService.init();

    // Set initial camera position to current location
    _locationSubscription = _locationService.locationStream.listen((locationData) {
      if (locationData != null && locationData.latitude != null && locationData.longitude != null) {
        final LatLng currentLatLng = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );

        initialCameraPosition.value = CameraPosition(
          target: currentLatLng,
          zoom: mapZoom.value,
        );

        if (isFollowingUser.value && mapController.value != null) {
          mapController.value!.animateCamera(
            CameraUpdate.newCameraPosition(initialCameraPosition.value),
          );
        }

        // Add marker for current location
        _updateCurrentLocationMarker(currentLatLng);
      }
    });

    DevLogs.debug('Location tracking initialized');
  }

  void _updateCurrentLocationMarker(LatLng position) {
    try {
      markers.removeWhere((marker) => marker.markerId.value == 'current_location');

      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );

      DevLogs.debug('Current location marker updated');
    } catch (e) {
      DevLogs.error('Error updating current location marker', exception: e);
    }
  }

  Future<void> toggleOnlineStatus() async {
    if (!isVerified.value) {
      Get.snackbar(
        'Verification Required',
        'You need to be verified before going online. Please complete the verification process.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    try {
      isOnline.value = !isOnline.value;

      if (isOnline.value) {
        // Go online
        await _locationService.startLocationUpdates();
        DevLogs.info('Driver went online');
      } else {
        // Go offline
        await _locationService.setDriverOffline();
        await _locationService.stopLocationUpdates();
        DevLogs.info('Driver went offline');
      }
    } catch (e) {
      DevLogs.error('Error toggling online status', exception: e);
      error.value = 'Failed to update status';
    } finally {
      isLoading.value = false;
    }
  }

  void _listenToRideRequests() {
    if (authService.firebaseUser.value == null) return;

    DevLogs.debug('Starting to listen for ride requests');
    // Listen for pending ride requests
    _rideRequestsSubscription?.cancel();
    _rideRequestsSubscription = firebaseService.collectionStream<RideModel>(
      path: Constants.ridesCollection,
      queryBuilder: (query) => query
          .where('status', isEqualTo: Constants.pending)
          .orderBy('createdAt', descending: true),
      builder: (data, documentId) => RideModel.fromMap(data, documentId),
    ).listen((rides) {
      rideRequests.value = rides;
      DevLogs.debug('Received ${rides.length} ride requests');

      // Check if there's a new incoming request
      if (rides.isNotEmpty && incomingRideRequest.value == null && isOnline.value) {
        incomingRideRequest.value = rides.first;
        _startRequestTimer();
      }
    });
  }

  void _startRequestTimer() {
    requestTimeRemaining.value = 30; // 30 seconds to accept or decline
    _requestTimer?.cancel();
    _requestTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (requestTimeRemaining.value > 0) {
        requestTimeRemaining.value--;
      } else {
        declineRideRequest();
        timer.cancel();
      }
    });
  }

  void _listenToCurrentRide() {
    if (authService.firebaseUser.value == null) return;

    final String driverId = authService.firebaseUser.value!.uid;

    DevLogs.debug('Starting to listen for current ride');
    // Listen for active rides assigned to this driver
    _currentRideSubscription?.cancel();
    _currentRideSubscription = firebaseService.collectionStream<RideModel>(
      path: Constants.ridesCollection,
      queryBuilder: (query) => query
          .where('driverId', isEqualTo: driverId)
          .where('status', whereIn: [Constants.accepted, Constants.arrived, Constants.started])
          .orderBy('createdAt', descending: true)
          .limit(1),
      builder: (data, documentId) => RideModel.fromMap(data, documentId),
    ).listen((rides) {
      if (rides.isNotEmpty) {
        currentRide.value = rides.first;
        _updateRideMapView(rides.first);
        _fetchRiderInfo(rides.first.riderId);
        DevLogs.debug('Current ride updated: ${rides.first.id}');
      } else {
        currentRide.value = null;
        riderInfo.value = null;
      }
    });
  }

  Future<void> _fetchRiderInfo(String riderId) async {
    try {
      final DocumentSnapshot userDoc = await firebaseService.getDocument(
        path: '${Constants.usersCollection}/$riderId',
      );

      if (userDoc.exists) {
        final Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        final UserModel user = UserModel.fromMap(userData, riderId);

        riderInfo.value = {
          'user': user,
        };
      }
    } catch (e) {
      DevLogs.error('Error fetching rider info', exception: e);
    }
  }

  Future<void> fetchRideHistory() async {
    if (authService.firebaseUser.value == null) return;

    isLoadingRideHistory.value = true;
    final String driverId = authService.firebaseUser.value!.uid;

    DevLogs.debug('Fetching ride history');
    try {
      final QuerySnapshot snapshot = await firebaseService.getCollection(
        path: Constants.ridesCollection,
        queryBuilder: (query) => query
            .where('driverId', isEqualTo: driverId)
            .where('status', whereIn: [Constants.completed, Constants.cancelled])
            .orderBy('createdAt', descending: true),
      );

      final List<RideModel> rides = snapshot.docs
          .map((doc) => RideModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      rideHistory.value = rides;
      DevLogs.debug('Fetched ${rides.length} rides for history');
    } catch (e) {
      DevLogs.error('Error fetching ride history', exception: e);
      Get.snackbar(
        'Error',
        'Failed to load ride history',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoadingRideHistory.value = false;
    }
  }

  Future<void> _calculateEarnings() async {
    if (authService.firebaseUser.value == null) return;

    final String driverId = authService.firebaseUser.value!.uid;

    DevLogs.debug('Calculating earnings');
    try {
      // Get completed rides
      final QuerySnapshot snapshot = await firebaseService.getCollection(
        path: Constants.ridesCollection,
        queryBuilder: (query) => query
            .where('driverId', isEqualTo: driverId)
            .where('status', isEqualTo: Constants.completed),
      );

      final List<RideModel> completedRidesList = snapshot.docs
          .map((doc) => RideModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      completedRides.value = completedRidesList.length;

      // Calculate total earnings
      double total = 0;
      for (var ride in completedRidesList) {
        total += ride.fare;
      }
      totalEarnings.value = total;

      // Calculate today's earnings
      final DateTime today = DateTime.now();
      final DateTime startOfDay = DateTime(today.year, today.month, today.day);

      double todayTotal = 0;
      for (var ride in completedRidesList) {
        if (ride.completedAt != null && ride.completedAt!.isAfter(startOfDay)) {
          todayTotal += ride.fare;
        }
      }
      todayEarnings.value = todayTotal;

      // Calculate weekly earnings
      final DateTime startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final DateTime startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

      double weeklyTotal = 0;
      for (var ride in completedRidesList) {
        if (ride.completedAt != null && ride.completedAt!.isAfter(startOfWeekDay)) {
          weeklyTotal += ride.fare;
        }
      }
      weeklyEarnings.value = weeklyTotal;

      DevLogs.debug('Earnings calculated: Today: \$${todayTotal.toStringAsFixed(2)}, Week: \$${weeklyTotal.toStringAsFixed(2)}, Total: \$${total.toStringAsFixed(2)}');
    } catch (e) {
      DevLogs.error('Error calculating earnings', exception: e);
    }
  }

  void _updateRideMapView(RideModel ride) {
    if (ride.pickup!.isEmpty || ride.dropoff!.isEmpty) return;

    DevLogs.debug('Updating ride map view');
    // Clear previous markers and polylines
    markers.clear();
    polylines.clear();

    // Add current location marker
    if (_locationService.currentLocation.value != null) {
      final LatLng currentLatLng = LatLng(
        _locationService.currentLocation.value!.latitude!,
        _locationService.currentLocation.value!.longitude!,
      );

      _updateCurrentLocationMarker(currentLatLng);
    }

    // Add pickup marker
    final LatLng pickupLatLng = ride.pickup!.latLng;

    markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: pickupLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Pickup', snippet: ride.pickup!.name),
      ),
    );

    // Add dropoff marker
    final LatLng dropoffLatLng = ride.dropoff!.latLng;

    markers.add(
      Marker(
        markerId: const MarkerId('dropoff'),
        position: dropoffLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(title: 'Dropoff', snippet: ride.dropoff!.name),
      ),
    );

    // Add polyline
    if (ride.polyline != null) {
      final polylinePoints = PolylinePoints();
      final points = polylinePoints.decodePolyline(ride.polyline!);

      final List<LatLng> polylineCoordinates = points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: polylineCoordinates,
          color: Colors.blue,
          width: 5,
        ),
      );
    } else {
      // Fallback to direct line if no polyline
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [pickupLatLng, dropoffLatLng],
          color: Colors.blue,
          width: 5,
        ),
      );
    }

    // Adjust camera to show the entire route
    if (mapController.value != null) {
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          min(pickupLatLng.latitude, dropoffLatLng.latitude) - 0.01,
          min(pickupLatLng.longitude, dropoffLatLng.longitude) - 0.01,
        ),
        northeast: LatLng(
          max(pickupLatLng.latitude, dropoffLatLng.latitude) + 0.01,
          max(pickupLatLng.longitude, dropoffLatLng.longitude) + 0.01,
        ),
      );

      mapController.value!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    }

    DevLogs.debug('Ride map view updated');
  }

  Future<void> acceptRideRequest() async {
    if (incomingRideRequest.value == null) return;

    isLoading.value = true;
    isRideAccepted.value = true;
    _requestTimer?.cancel();

    DevLogs.info('Accepting ride: ${incomingRideRequest.value!.id}');
    try {
      final String driverId = authService.firebaseUser.value!.uid;

      // Get driver details
      final DocumentSnapshot driverDoc = await firebaseService.getDocument(
        path: '${Constants.driversCollection}/$driverId',
      );

      final DocumentSnapshot userDoc = await firebaseService.getDocument(
        path: '${Constants.usersCollection}/$driverId',
      );

      // Combine driver info
      final Map<String, dynamic> driverInfo = {
        ...driverDoc.data() as Map<String, dynamic>? ?? {},
        'fullName': (userDoc.data() as Map<String, dynamic>?)?['fullName'] ?? 'Driver',
        'phoneNumber': (userDoc.data() as Map<String, dynamic>?)?['phoneNumber'] ?? '',
        'profileImageUrl': (userDoc.data() as Map<String, dynamic>?)?['profileImageUrl'] ?? '',
      };

      await firebaseService.updateData(
        path: '${Constants.ridesCollection}/${incomingRideRequest.value!.id}',
        data: {
          'driverId': driverId,
          'driverInfo': driverInfo,
          'status': Constants.accepted,
          'acceptedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // Get ride details to send notification to rider
      final DocumentSnapshot rideDoc = await firebaseService.getDocument(
        path: '${Constants.ridesCollection}/${incomingRideRequest.value!.id}',
      );

      if (rideDoc.exists) {
        final Map<String, dynamic> rideData = rideDoc.data() as Map<String, dynamic>;
        final String riderId = rideData['riderId'] as String;

        // Send notification to rider
        await _notificationService.sendNotificationToUser(
          riderId,
          'Driver Found',
          'A driver has accepted your ride request',
          {
            'type': NotificationService.rideAccepted,
            'rideId': incomingRideRequest.value!.id,
            'driverName': driverInfo['fullName'],
          },
        );
      }

      // Reset incoming request
      final String rideId = incomingRideRequest.value!.id;
      incomingRideRequest.value = null;

      Get.toNamed('/driver/ride-details/$rideId');
      DevLogs.info('Ride accepted successfully');
    } catch (e) {
      DevLogs.error('Error accepting ride', exception: e);
      error.value = 'Failed to accept ride';
      Get.snackbar(
        'Error',
        'Failed to accept ride. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      isRideAccepted.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  void declineRideRequest() {
    if (incomingRideRequest.value == null) return;

    _requestTimer?.cancel();
    incomingRideRequest.value = null;
    DevLogs.debug('Ride request declined');
  }

  Future<void> arrivedAtPickup() async {
    if (currentRide.value == null) return;

    await updateRideStatus(currentRide.value!.id, Constants.arrived);
  }

  Future<void> startRide() async {
    if (currentRide.value == null) return;

    await updateRideStatus(currentRide.value!.id, Constants.started);
  }

  Future<void> completeRide() async {
    if (currentRide.value == null) return;

    await updateRideStatus(currentRide.value!.id, Constants.completed);
  }

  Future<void> updateRideStatus(String rideId, String status) async {
    isLoading.value = true;

    DevLogs.info('Updating ride status: $rideId to $status');
    try {
      Map<String, dynamic> updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      switch (status) {
        case Constants.arrived:
          updateData['arrivedAt'] = FieldValue.serverTimestamp();
          break;
        case Constants.started:
          updateData['startedAt'] = FieldValue.serverTimestamp();
          break;
        case Constants.completed:
          updateData['completedAt'] = FieldValue.serverTimestamp();
          updateData['isPaid'] = true; // Assuming cash payment is completed
          break;
      }

      await firebaseService.updateData(
        path: '${Constants.ridesCollection}/$rideId',
        data: updateData,
      );

      // Get ride details to send notification to rider
      final DocumentSnapshot rideDoc = await firebaseService.getDocument(
        path: '${Constants.ridesCollection}/$rideId',
      );

      if (rideDoc.exists) {
        final Map<String, dynamic> rideData = rideDoc.data() as Map<String, dynamic>;
        final String riderId = rideData['riderId'] as String;

        // Send notification to rider based on status
        String title = '';
        String body = '';
        String notificationType = '';

        switch (status) {
          case Constants.arrived:
            title = 'Driver Arrived';
            body = 'Your driver has arrived at the pickup location';
            notificationType = NotificationService.rideArrived;
            break;
          case Constants.started:
            title = 'Ride Started';
            body = 'Your ride has started';
            notificationType = NotificationService.rideStarted;
            break;
          case Constants.completed:
            title = 'Ride Completed';
            body = 'Your ride has been completed';
            notificationType = NotificationService.rideCompleted;
            break;
        }

        await _notificationService.sendNotificationToUser(
          riderId,
          title,
          body,
          {
            'type': notificationType,
            'rideId': rideId,
          },
        );
      }

      if (status == Constants.completed) {
        await _calculateEarnings();
        Get.offAllNamed(Routes.driverHome);
      }

      DevLogs.info('Ride status updated successfully');
    } catch (e) {
      DevLogs.error('Error updating ride status', exception: e);
      error.value = 'Failed to update ride status';
      Get.snackbar(
        'Error',
        'Failed to update ride status. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rateRider(String rideId, double rating, String feedback) async {
    isLoading.value = true;

    DevLogs.info('Rating rider for ride: $rideId');
    try {
      await firebaseService.updateData(
        path: '${Constants.ridesCollection}/$rideId',
        data: {
          'riderRating': rating,
          'riderFeedback': feedback,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // Get rider ID from ride
      final DocumentSnapshot rideDoc = await firebaseService.getDocument(
        path: '${Constants.ridesCollection}/$rideId',
      );

      if (rideDoc.exists) {
        final Map<String, dynamic> rideData = rideDoc.data() as Map<String, dynamic>;
        final String riderId = rideData['riderId'] as String;

        // Update rider's average rating
        await _updateRiderRating(riderId, rating);
      }

      Get.back();
      Get.snackbar(
        'Thank You',
        'Your rating has been submitted',
        snackPosition: SnackPosition.BOTTOM,
      );

      DevLogs.info('Rider rated successfully');
    } catch (e) {
      DevLogs.error('Error rating rider', exception: e);
      error.value = 'Failed to submit rating';
      Get.snackbar(
        'Error',
        'Failed to submit rating. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _updateRiderRating(String riderId, double newRating) async {
    try {
      // Get rider document
      final DocumentSnapshot riderDoc = await firebaseService.getDocument(
        path: '${Constants.usersCollection}/$riderId',
      );

      if (riderDoc.exists) {
        final Map<String, dynamic> data = riderDoc.data() as Map<String, dynamic>;
        final double currentRating = (data['rating'] as num?)?.toDouble() ?? 0.0;
        final int ratingCount = (data['ratingCount'] as int?) ?? 0;

        // Calculate new average rating
        final double newAvgRating = ((currentRating * ratingCount) + newRating) / (ratingCount + 1);

        // Update rider document
        await firebaseService.updateData(
          path: '${Constants.usersCollection}/$riderId',
          data: {
            'rating': newAvgRating,
            'ratingCount': ratingCount + 1,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        DevLogs.debug('Rider rating updated: $newAvgRating (${ratingCount + 1} ratings)');
      }
    } catch (e) {
      DevLogs.error('Error updating rider rating', exception: e);
    }
  }

  Future<void> uploadVerificationDocument(String documentType, File file) async {
    if (authService.firebaseUser.value == null) return;

    isLoading.value = true;
    error.value = '';

    DevLogs.info('Uploading verification document: $documentType');
    try {
      final String userId = authService.firebaseUser.value!.uid;
      String? documentUrl;

      // Upload document
      documentUrl = await _storageService.uploadDocumentImage(
        file,
        userId,
        documentType,
      );

      // Get existing driver details
      Map<String, dynamic> existingDriverDetails =
          authService.currentUser.value?.driverDetails ?? {};

      // Update document URL based on type
      switch (documentType) {
        case 'driver_license':
          existingDriverDetails['driverLicenseUrl'] = documentUrl;
          documentStatus['driverLicense'] = VerificationStatus.pending;
          break;
        case 'vehicle_registration':
          existingDriverDetails['vehicleRegistrationUrl'] = documentUrl;
          documentStatus['vehicleRegistration'] = VerificationStatus.pending;
          break;
        case 'insurance':
          existingDriverDetails['insuranceDocumentUrl'] = documentUrl;
          documentStatus['insurance'] = VerificationStatus.pending;
          break;
        case 'address_proof':
          existingDriverDetails['addressProofUrl'] = documentUrl;
          documentStatus['addressProof'] = VerificationStatus.pending;
          break;
        case 'selfie_with_documents':
          existingDriverDetails['selfieWithDocumentsUrl'] = documentUrl;
          documentStatus['selfieWithDocuments'] = VerificationStatus.pending;
          break;
      }

      // Update document status
      Map<String, int> statusMap = {};
      documentStatus.forEach((key, value) {
        statusMap[key] = value.index;
      });

      existingDriverDetails['documentStatus'] = statusMap;

      // Update user data in Firestore
      await authService.updateUserData({
        'driverDetails': existingDriverDetails,
        'updatedAt': DateTime.now(),
      });

      Get.snackbar(
        'Success',
        'Document uploaded successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      DevLogs.info('Document uploaded successfully');
    } catch (e) {
      error.value = 'Failed to upload document: ${e.toString()}';
      DevLogs.error('Failed to upload document', exception: e);
      Get.snackbar(
        'Error',
        error.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  bool areAllDocumentsVerified() {
    if (documentStatus.isEmpty) return false;

    return documentStatus.values.every((status) => status == VerificationStatus.approved);
  }

  String? getNextPendingDocument() {
    for (var entry in documentStatus.entries) {
      if (entry.value == VerificationStatus.pending || entry.value == VerificationStatus.rejected) {
        return entry.key;
      }
    }
    return null;
  }

  void _checkVerificationStatus() {
    if (authService.currentUser.value != null) {
      isVerified.value = authService.currentUser.value!.isVerified;
      isVerificationPending.value = authService.currentUser.value!.isVerificationPending ?? false;

      if (authService.currentUser.value!.driverDetails != null) {
        final Map<String, dynamic> driverDetails = authService.currentUser.value!.driverDetails!;

        if (driverDetails['documentStatus'] != null) {
          final Map<String, dynamic> status = driverDetails['documentStatus'] as Map<String, dynamic>;

          Map<String, VerificationStatus> updatedStatus = {};
          status.forEach((key, value) {
            if (value is int) {
              updatedStatus[key] = VerificationStatus.values[value];
            } else if (value is String) {
              updatedStatus[key] = VerificationStatus.values.firstWhere(
                    (e) => e.toString().split('.').last == value,
                orElse: () => VerificationStatus.pending,
              );
            } else {
              updatedStatus[key] = VerificationStatus.pending;
            }
          });

          documentStatus.value = updatedStatus;
        } else {
          documentStatus.value = {
            'driverLicense': VerificationStatus.notSubmitted,
            'vehicleRegistration': VerificationStatus.notSubmitted,
            'insurance': VerificationStatus.notSubmitted,
            'addressProof': VerificationStatus.notSubmitted,
            'selfieWithDocuments': VerificationStatus.notSubmitted,
          };
        }

        if (driverDetails['rejectionReason'] != null) {
          rejectionReason.value = driverDetails['rejectionReason'] as String;
        }
      }

      DevLogs.debug('Driver verification status: ${isVerified.value}');
    }
  }

  void setNavIndex(int index) {
    selectedNavIndex.value = index;
    DevLogs.debug('Navigation index set to: $index');
  }

  void toggleFollowUser() {
    isFollowingUser.value = !isFollowingUser.value;

    if (isFollowingUser.value && _locationService.currentLocation.value != null && mapController.value != null) {
      final LatLng currentLatLng = LatLng(
        _locationService.currentLocation.value!.latitude!,
        _locationService.currentLocation.value!.longitude!,
      );

      mapController.value!.animateCamera(
        CameraUpdate.newLatLngZoom(currentLatLng, mapZoom.value),
      );
      DevLogs.debug('Following user location enabled');
    } else {
      DevLogs.debug('Following user location disabled');
    }
  }

  void centerOnUserLocation() {
    if (_locationService.currentLocation.value != null && mapController.value != null) {
      final LatLng currentLatLng = LatLng(
        _locationService.currentLocation.value!.latitude!,
        _locationService.currentLocation.value!.longitude!,
      );

      mapController.value!.animateCamera(
        CameraUpdate.newLatLngZoom(currentLatLng, mapZoom.value),
      );
      isFollowingUser.value = true;
      DevLogs.debug('Centered on user location');
    }
  }

  void toggleTraffic() {
    showTraffic.value = !showTraffic.value;
    DevLogs.debug('Traffic display toggled: ${showTraffic.value}');
  }

  void toggleMapType() {
    if (mapType.value == MapType.normal) {
      mapType.value = MapType.satellite;
    } else if (mapType.value == MapType.satellite) {
      mapType.value = MapType.terrain;
    } else {
      mapType.value = MapType.normal;
    }
    DevLogs.debug('Map type changed to: ${mapType.value}');
  }

  void onMapCreated(GoogleMapController controller) {
    mapController.value = controller;

    if (_locationService.currentLocation.value != null) {
      final LatLng currentLatLng = LatLng(
        _locationService.currentLocation.value!.latitude!,
        _locationService.currentLocation.value!.longitude!,
      );

      controller.animateCamera(
        CameraUpdate.newLatLngZoom(currentLatLng, mapZoom.value),
      );

      _updateCurrentLocationMarker(currentLatLng);
    }

    // Apply custom map style using the new recommended approach
    _setMapStyle();
    DevLogs.debug('Map created and initialized');
  }

  Future<void> _setMapStyle() async {
    try {
      // Using the new recommended approach instead of the deprecated setMapStyle
      String style = await rootBundle.loadString('assets/map_style.json');
      if (mapController.value != null) {
        // Use GoogleMap.style property instead of setMapStyle
        // This is handled in the GoogleMap widget with the style property
        // For now, we'll still use setMapStyle but with a note that it's deprecated
        mapController.value!.setMapStyle(style);
      }
      DevLogs.debug('Map style applied');
    } catch (e) {
      DevLogs.error('Error setting map style', exception: e);
    }
  }

  void callRider() {
    if (riderInfo.value == null) {
      Get.snackbar(
        'Error',
        'Rider information not available',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final UserModel user = riderInfo.value!['user'] as UserModel;
    if (user.phoneNumber == null || user.phoneNumber!.isEmpty) {
      Get.snackbar(
        'Error',
        'Rider phone number not available',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final Uri uri = Uri.parse('tel:${user.phoneNumber}');
    launchUrl(uri);
    DevLogs.debug('Calling rider: ${user.phoneNumber}');
  }

  void messageRider() {
    if (currentRide.value == null) return;

    Get.toNamed('/chat/${currentRide.value!.id}');
    DevLogs.debug('Opening chat with rider');
  }

  void logout() async {
    try {
      await authService.signOut();
      Get.offAllNamed(Routes.login);
      DevLogs.info('Driver logged out');
    } catch (e) {
      DevLogs.error('Error logging out', exception: e);
      Get.snackbar(
        'Error',
        'Failed to logout. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  double min(double a, double b) {
    return a < b ? a : b;
  }

  double max(double a, double b) {
    return a > b ? a : b;
  }
}
