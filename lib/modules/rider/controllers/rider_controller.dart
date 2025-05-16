import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:easy_ride/core/services/location_service.dart';
import 'package:easy_ride/core/services/auth_service.dart';
import 'package:easy_ride/core/services/storage_service.dart';
import 'package:easy_ride/core/services/safety_service.dart';
import 'package:easy_ride/models/ride_model.dart';
import 'package:easy_ride/models/driver_model.dart';
import 'package:easy_ride/models/user_model.dart';
import 'package:easy_ride/modules/rider/models/fare_model.dart';
import 'package:easy_ride/modules/rider/models/saved_location_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:uuid/uuid.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:math' show pi, sqrt, atan2, sin, cos;

class RiderController extends GetxController {
  final LocationService _locationService = Get.find<LocationService>();
  final AuthService _authService = Get.find<AuthService>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = Get.find<StorageService>();
  final SafetyService _safetyService = Get.find<SafetyService>();

  // Map controller
  Rx<GoogleMapController?> mapController = Rx<GoogleMapController?>(null);

  // User location
  final Rx<LatLng> currentLocation = Rx<LatLng>(const LatLng(0, 0));

  // Map state
  final RxDouble mapZoom = 15.0.obs;
  final RxBool isMapLoading = true.obs;
  final RxBool isFollowingUser = true.obs;

  // Initial camera position (default to a central location)
  final Rx<CameraPosition> initialCameraPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194), // Default to San Francisco
    zoom: 15.0,
  ).obs;

  // Ride request state
  final RxBool isRequestingRide = false.obs;
  final RxBool isRideAccepted = false.obs;
  final RxBool isRideInProgress = false.obs;
  final RxBool isRideCompleted = false.obs;
  final Rx<RideModel?> currentRide = Rx<RideModel?>(null);

  // Pickup and dropoff locations
  final Rx<Map<String, dynamic>?> pickupLocation = Rx<Map<String, dynamic>?>(null);
  final Rx<Map<String, dynamic>?> dropoffLocation = Rx<Map<String, dynamic>?>(null);

  // Ride options
  final RxString selectedRideType = 'Standard'.obs;
  final RxString selectedPaymentMethod = 'card'.obs;

  // Fare estimate
  final Rx<FareModel?> fareEstimate = Rx<FareModel?>(null);
  final RxBool isCalculatingFare = false.obs;
  final RxBool showFareBreakdown = false.obs;

  // Saved locations
  final RxList<SavedLocationModel> savedLocations = <SavedLocationModel>[].obs;
  final Rx<SavedLocationModel?> homeLocation = Rx<SavedLocationModel?>(null);
  final Rx<SavedLocationModel?> workLocation = Rx<SavedLocationModel?>(null);
  final RxBool isLoadingSavedLocations = false.obs;

  // Map markers and polylines
  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxSet<Polyline> polylines = <Polyline>{}.obs;
  final RxList<LatLng> routePoints = <LatLng>[].obs;

  // Driver info
  final Rx<Map<String, dynamic>?> driverInfo = Rx<Map<String, dynamic>?>(null);

  // ETA
  final RxDouble distanceToPickup = 0.0.obs;
  final RxDouble durationToPickup = 0.0.obs;
  final RxDouble distanceToDestination = 0.0.obs;
  final RxDouble durationToDestination = 0.0.obs;

  // Ride status
  final RxString rideStatus = 'idle'.obs; // idle, searching, accepted, arrived, started, completed

  // Surge pricing
  final RxDouble surgeFactor = 1.0.obs;

  // UI state
  final RxInt currentStep = 0.obs;
  final RxBool showLocationSearch = false.obs;
  final RxBool showRideOptions = false.obs;
  final RxBool showDriverInfo = false.obs;
  final RxBool showRideDetails = false.obs;

  // Streams
  StreamSubscription? _locationSubscription;
  StreamSubscription? _rideSubscription;
  StreamSubscription? _driverLocationSubscription;

  // Loading
  final RxBool isLoading = false.obs;

  // Ride history
  final RxList<RideModel> rideHistory = <RideModel>[].obs;
  final RxBool isLoadingRideHistory = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initLocationTracking();
    _loadSavedLocations();
    _checkForActiveRide();
    _loadSurgePricing();
  }

  @override
  void onClose() {
    _locationSubscription?.cancel();
    _rideSubscription?.cancel();
    _driverLocationSubscription?.cancel();
    mapController.value?.dispose();
    super.onClose();
  }

  void _initLocationTracking() {
    _locationSubscription = _locationService.locationStream.listen((position) {
      if (position.latitude != null && position.longitude != null) {
        currentLocation.value = LatLng(position.latitude!, position.longitude!);

        // Update initial camera position if it's still the default
        if (initialCameraPosition.value.target.latitude == 37.7749 &&
            initialCameraPosition.value.target.longitude == -122.4194) {
          initialCameraPosition.value = CameraPosition(
            target: currentLocation.value,
            zoom: mapZoom.value,
          );
        }

        if (isFollowingUser.value && mapController.value != null) {
          mapController.value!.animateCamera(
            CameraUpdate.newLatLng(currentLocation.value),
          );
        }

        _updateUserMarker();

        // If ride is in progress, update ETA
        if (isRideAccepted.value && !isRideInProgress.value) {
          _updateETAToPickup();
        } else if (isRideInProgress.value && !isRideCompleted.value) {
          _updateETAToDestination();
        }
      }
    });
  }

  void onMapCreated(GoogleMapController controller) {
    mapController.value = controller;
    isMapLoading.value = false;

    if (currentLocation.value.latitude != 0) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation.value, mapZoom.value),
      );
      _updateUserMarker();
    }

    // Apply custom map style
    _setMapStyle();
  }

  Future<void> _setMapStyle() async {
    try {
      String style = await rootBundle.loadString('assets/map_style.json');
      mapController.value?.setMapStyle(style);
    } catch (e) {
      print('Error setting map style: $e');
    }
  }

  void toggleFollowUser() {
    isFollowingUser.value = !isFollowingUser.value;

    if (isFollowingUser.value && currentLocation.value.latitude != 0 && mapController.value != null) {
      mapController.value!.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation.value, mapZoom.value),
      );
    }
  }

  Future<void> _updateUserMarker() async {
    if (currentLocation.value.latitude == 0) return;

    try {
      final BitmapDescriptor icon = await _createCustomMarkerBitmap(
        'assets/images/user_marker.png',
        size: 120,
      );

      final marker = Marker(
        markerId: const MarkerId('user_location'),
        position: currentLocation.value,
        icon: icon,
        zIndex: 2,
      );

      final updatedMarkers = {...markers};
      updatedMarkers.removeWhere((m) => m.markerId.value == 'user_location');
      updatedMarkers.add(marker);
      markers.value = updatedMarkers;
    } catch (e) {
      print('Error updating user marker: $e');
      // Fallback to default marker if custom one fails
      final marker = Marker(
        markerId: const MarkerId('user_location'),
        position: currentLocation.value,
        zIndex: 2,
      );

      final updatedMarkers = {...markers};
      updatedMarkers.removeWhere((m) => m.markerId.value == 'user_location');
      updatedMarkers.add(marker);
      markers.value = updatedMarkers;
    }
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap(String assetName, {int size = 150}) async {
    try {
      final ByteData data = await rootBundle.load(assetName);
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: size,
        targetHeight: size,
      );
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ByteData? byteData = await fi.image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
      } else {
        throw Exception('Failed to get byte data from image');
      }
    } catch (e) {
      print('Error creating custom marker: $e');
      return BitmapDescriptor.defaultMarker;
    }
  }

  Future<void> _loadSavedLocations() async {
    if (_authService.firebaseUser.value == null) return;

    isLoadingSavedLocations.value = true;

    try {
      final userId = _authService.firebaseUser.value!.uid;
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_locations')
          .orderBy('createdAt', descending: true)
          .get();

      final locations = snapshot.docs.map((doc) {
        return SavedLocationModel.fromMap(doc.data());
      }).toList();

      savedLocations.value = locations;

      // Set home and work locations
      homeLocation.value = locations.firstWhereOrNull((loc) => loc.type == 'home');
      workLocation.value = locations.firstWhereOrNull((loc) => loc.type == 'work');
    } catch (e) {
      print('Error loading saved locations: $e');
    } finally {
      isLoadingSavedLocations.value = false;
    }
  }

  Future<void> _checkForActiveRide() async {
    if (_authService.firebaseUser.value == null) return;

    try {
      final userId = _authService.firebaseUser.value!.uid;
      final snapshot = await _firestore
          .collection('rides')
          .where('riderId', isEqualTo: userId)
          .where('status', whereIn: ['requested', 'accepted', 'arrived', 'started'])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final rideData = snapshot.docs.first.data();
        final ride = RideModel.fromMap(rideData, snapshot.docs.first.id);

        currentRide.value = ride;

        // Set ride state based on status
        _setRideStateFromStatus(ride.status);

        // Set pickup and dropoff locations
        pickupLocation.value = ride.pickup;
        dropoffLocation.value = ride.dropoff;

        // Set ride options
        selectedRideType.value = ride.rideType;
        selectedPaymentMethod.value = ride.paymentMethod;

        // Update markers and route
        _updateRideMarkers();
        _calculateRoute();

        // Start listening for ride updates
        _listenForRideUpdates(ride.id);

        // If ride is accepted, get driver info
        if (ride.status == 'accepted' || ride.status == 'arrived' || ride.status == 'started') {
          _getDriverInfo(ride.driverId!);
        }
      }
    } catch (e) {
      print('Error checking for active ride: $e');
    }
  }

  void _setRideStateFromStatus(String status) {
    rideStatus.value = status;

    switch (status) {
      case 'requested':
        isRequestingRide.value = true;
        isRideAccepted.value = false;
        isRideInProgress.value = false;
        isRideCompleted.value = false;
        break;
      case 'accepted':
        isRequestingRide.value = false;
        isRideAccepted.value = true;
        isRideInProgress.value = false;
        isRideCompleted.value = false;
        break;
      case 'arrived':
        isRequestingRide.value = false;
        isRideAccepted.value = true;
        isRideInProgress.value = false;
        isRideCompleted.value = false;
        break;
      case 'started':
        isRequestingRide.value = false;
        isRideAccepted.value = true;
        isRideInProgress.value = true;
        isRideCompleted.value = false;
        break;
      case 'completed':
        isRequestingRide.value = false;
        isRideAccepted.value = false;
        isRideInProgress.value = false;
        isRideCompleted.value = true;
        break;
      default:
        isRequestingRide.value = false;
        isRideAccepted.value = false;
        isRideInProgress.value = false;
        isRideCompleted.value = false;
        break;
    }
  }

  void _listenForRideUpdates(String rideId) {
    _rideSubscription?.cancel();

    _rideSubscription = _firestore
        .collection('rides')
        .doc(rideId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final rideData = snapshot.data()!;
        final ride = RideModel.fromMap(rideData, snapshot.id);

        currentRide.value = ride;

        // Set ride state based on status
        _setRideStateFromStatus(ride.status);

        // If ride is accepted, get driver info
        if (ride.status == 'accepted' && driverInfo.value == null && ride.driverId != null) {
          _getDriverInfo(ride.driverId!);
        }

        // If ride is completed, stop listening
        if (ride.status == 'completed' || ride.status == 'cancelled') {
          _rideSubscription?.cancel();
          _driverLocationSubscription?.cancel();
        }
      }
    });
  }

  Future<void> _getDriverInfo(String driverId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(driverId).get();
      final driverDoc = await _firestore.collection('drivers').doc(driverId).get();

      if (userDoc.exists && driverDoc.exists) {
        final userData = userDoc.data()!;
        final driverData = driverDoc.data()!;

        final UserModel user = UserModel.fromMap(userData, driverId);
        final DriverModel driver = DriverModel.fromMap(driverData, driverId);

        driverInfo.value = {
          'user': user,
          'driver': driver,
        };

        // Start listening for driver location updates
        _listenForDriverLocationUpdates(driverId);
      }
    } catch (e) {
      print('Error getting driver info: $e');
    }
  }

  void _listenForDriverLocationUpdates(String driverId) {
    _driverLocationSubscription?.cancel();

    _driverLocationSubscription = _firestore
        .collection('drivers')
        .doc(driverId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;

        if (data['currentLocation'] != null) {
          final GeoPoint location = data['currentLocation']['geopoint'];
          final driverLatLng = LatLng(location.latitude, location.longitude);

          // Update driver marker
          _updateDriverMarker(driverLatLng);

          // Update ETA
          if (isRideAccepted.value && !isRideInProgress.value) {
            _updateETAToPickup();
          }
        }
      }
    });
  }

  Future<void> _updateDriverMarker(LatLng position) async {
    try {
      final BitmapDescriptor icon = await _createCustomMarkerBitmap(
        'assets/images/car_marker.png',
        size: 120,
      );

      final marker = Marker(
        markerId: const MarkerId('driver_location'),
        position: position,
        icon: icon,
        zIndex: 3,
      );

      final updatedMarkers = {...markers};
      updatedMarkers.removeWhere((m) => m.markerId.value == 'driver_location');
      updatedMarkers.add(marker);
      markers.value = updatedMarkers;
    } catch (e) {
      print('Error updating driver marker: $e');
      // Fallback to default marker
      final marker = Marker(
        markerId: const MarkerId('driver_location'),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        zIndex: 3,
      );

      final updatedMarkers = {...markers};
      updatedMarkers.removeWhere((m) => m.markerId.value == 'driver_location');
      updatedMarkers.add(marker);
      markers.value = updatedMarkers;
    }
  }

  Future<void> setPickupLocation(Map<String, dynamic> location) async {
    pickupLocation.value = location;

    // Update marker
    await _updateLocationMarker(
      'pickup_location',
      LatLng(
        location['latitude'],
        location['longitude'],
      ),
      'assets/images/pickup_marker.png',
    );

    // If both pickup and dropoff are set, calculate route and fare
    if (dropoffLocation.value != null) {
      await _calculateRoute();
      await calculateFare();
    }

    // Move to next step if on step 0
    if (currentStep.value == 0) {
      currentStep.value = 1;
    }
  }

  Future<void> setDropoffLocation(Map<String, dynamic> location) async {
    dropoffLocation.value = location;

    // Update marker
    await _updateLocationMarker(
      'dropoff_location',
      LatLng(
        location['latitude'],
        location['longitude'],
      ),
      'assets/images/dropoff_marker.png',
    );

    // If both pickup and dropoff are set, calculate route and fare
    if (pickupLocation.value != null) {
      await _calculateRoute();
      await calculateFare();
    }

    // Move to next step if on step 1
    if (currentStep.value == 1) {
      currentStep.value = 2;
      showRideOptions.value = true;
    }
  }

  Future<void> _updateLocationMarker(String id, LatLng position, String assetPath) async {
    try {
      final BitmapDescriptor icon = await _createCustomMarkerBitmap(
        assetPath,
        size: 120,
      );

      final marker = Marker(
        markerId: MarkerId(id),
        position: position,
        icon: icon,
        zIndex: 1,
      );

      final updatedMarkers = {...markers};
      updatedMarkers.removeWhere((m) => m.markerId.value == id);
      updatedMarkers.add(marker);
      markers.value = updatedMarkers;

      // Center map to show all markers
      _fitMapToMarkers();
    } catch (e) {
      print('Error updating location marker: $e');
      // Fallback to default marker
      final marker = Marker(
        markerId: MarkerId(id),
        position: position,
        icon: id == 'pickup_location'
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        zIndex: 1,
      );

      final updatedMarkers = {...markers};
      updatedMarkers.removeWhere((m) => m.markerId.value == id);
      updatedMarkers.add(marker);
      markers.value = updatedMarkers;

      // Center map to show all markers
      _fitMapToMarkers();
    }
  }

  void _fitMapToMarkers() {
    if (mapController.value == null) return;

    // Get all marker positions except user and driver
    final positions = markers.where((m) {
      return m.markerId.value != 'user_location' && m.markerId.value != 'driver_location';
    }).map((m) => m.position).toList();

    if (positions.isEmpty) return;

    // If only one marker, zoom to it
    if (positions.length == 1) {
      mapController.value!.animateCamera(
        CameraUpdate.newLatLngZoom(positions[0], 15),
      );
      return;
    }

    // Calculate bounds
    double minLat = positions[0].latitude;
    double maxLat = positions[0].latitude;
    double minLng = positions[0].longitude;
    double maxLng = positions[0].longitude;

    for (final pos in positions) {
      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;
    }

    // Add padding
    final bounds = LatLngBounds(
      southwest: LatLng(minLat - 0.01, minLng - 0.01),
      northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
    );

    mapController.value!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  Future<void> _calculateRoute() async {
    if (pickupLocation.value == null || dropoffLocation.value == null) return;

    try {
      final pickupLatLng = LatLng(
        pickupLocation.value!['latitude'],
        pickupLocation.value!['longitude'],
      );

      final dropoffLatLng = LatLng(
        dropoffLocation.value!['latitude'],
        dropoffLocation.value!['longitude'],
      );

      PolylinePoints polylinePoints = PolylinePoints();

      // For demo purposes, we'll create a direct line between points
      // In a real app, you would use the Google Directions API
      final List<LatLng> points = [pickupLatLng, dropoffLatLng];
      routePoints.value = points;

      final polyline = Polyline(
        polylineId: const PolylineId('route'),
        color: Colors.blue,
        points: routePoints,
        width: 5,
      );

      polylines.value = {polyline};

      // Calculate distance
      double distance = _calculateDistance(
        pickupLatLng.latitude,
        pickupLatLng.longitude,
        dropoffLatLng.latitude,
        dropoffLatLng.longitude,
      );

      // Estimate duration (assuming average speed of 30 km/h)
      double duration = (distance / 30) * 60; // in minutes

      distanceToDestination.value = distance;
      durationToDestination.value = duration;
    } catch (e) {
      print('Error calculating route: $e');
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

  Future<void> calculateFare() async {
    if (pickupLocation.value == null || dropoffLocation.value == null) return;

    isCalculatingFare.value = true;

    try {
      // Calculate fare based on distance and duration
      final fare = FareModel.calculate(
        rideType: selectedRideType.value,
        distance: distanceToDestination.value,
        duration: durationToDestination.value,
        surgeFactor: surgeFactor.value,
      );

      fareEstimate.value = fare;
    } catch (e) {
      print('Error calculating fare: $e');
    } finally {
      isCalculatingFare.value = false;
    }
  }

  Future<void> _loadSurgePricing() async {
    try {
      // In a real app, this would be fetched from the server based on demand
      // For now, we'll simulate surge pricing based on time of day
      final hour = DateTime.now().hour;

      // Simulate surge pricing during peak hours (7-9 AM and 5-7 PM)
      if ((hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19)) {
        surgeFactor.value = 1.5; // 50% surge
      } else {
        surgeFactor.value = 1.0; // No surge
      }
    } catch (e) {
      print('Error loading surge pricing: $e');
      surgeFactor.value = 1.0; // Default to no surge
    }
  }

  Future<void> requestRide() async {
    if (pickupLocation.value == null || dropoffLocation.value == null) return;
    if (_authService.firebaseUser.value == null) return;

    isRequestingRide.value = true;
    rideStatus.value = 'searching';

    try {
      final userId = _authService.firebaseUser.value!.uid;
      final rideId = const Uuid().v4();

      // Calculate fare
      await calculateFare();

      // Create ride request
      final ride = {
        'id': rideId,
        'riderId': userId,
        'driverId': null,
        'pickup': pickupLocation.value,
        'dropoff': dropoffLocation.value,
        'rideType': selectedRideType.value,
        'paymentMethod': selectedPaymentMethod.value,
        'fare': fareEstimate.value!.totalFare,
        'distance': distanceToDestination.value,
        'duration': durationToDestination.value,
        'status': 'requested',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'acceptedAt': null,
        'arrivedAt': null,
        'startedAt': null,
        'completedAt': null,
        'cancelledAt': null,
        'cancelledBy': null,
        'cancellationReason': null,
        'driverRating': null,
        'driverFeedback': null,
        'isPaid': false,
      };

      // Save ride to Firestore
      await _firestore.collection('rides').doc(rideId).set(ride);

      // Start listening for ride updates
      _listenForRideUpdates(rideId);

      // Save recent location
      _saveRecentLocation(dropoffLocation.value!);

      // For demo purposes, simulate ride acceptance after 5 seconds
      if (GetPlatform.isAndroid) {
        Future.delayed(const Duration(seconds: 5), () {
          _simulateRideAcceptance(rideId);
        });
      }
    } catch (e) {
      print('Error requesting ride: $e');
      isRequestingRide.value = false;
      rideStatus.value = 'idle';

      Get.snackbar(
        'Error',
        'Failed to request ride. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // For demo purposes only
  Future<void> _simulateRideAcceptance(String rideId) async {
    try {
      // Simulate a driver accepting the ride
      await _firestore.collection('rides').doc(rideId).update({
        'driverId': 'demo_driver_id',
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Simulate driver arrival after 10 seconds
      Future.delayed(const Duration(seconds: 10), () {
        _simulateDriverArrival(rideId);
      });
    } catch (e) {
      print('Error simulating ride acceptance: $e');
    }
  }

  // For demo purposes only
  Future<void> _simulateDriverArrival(String rideId) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
        'status': 'arrived',
        'arrivedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Simulate ride start after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        _simulateRideStart(rideId);
      });
    } catch (e) {
      print('Error simulating driver arrival: $e');
    }
  }

  // For demo purposes only
  Future<void> _simulateRideStart(String rideId) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
        'status': 'started',
        'startedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Simulate ride completion after 15 seconds
      Future.delayed(const Duration(seconds: 15), () {
        _simulateRideCompletion(rideId);
      });
    } catch (e) {
      print('Error simulating ride start: $e');
    }
  }

  // For demo purposes only
  Future<void> _simulateRideCompletion(String rideId) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isPaid': true,
      });
    } catch (e) {
      print('Error simulating ride completion: $e');
    }
  }

  Future<void> cancelRide() async {
    if (currentRide.value == null) return;

    try {
      await _firestore.collection('rides').doc(currentRide.value!.id).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': 'rider',
        'cancellationReason': 'Cancelled by rider',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Reset state
      _resetRideState();
    } catch (e) {
      print('Error cancelling ride: $e');

      Get.snackbar(
        'Error',
        'Failed to cancel ride. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _resetRideState() {
    isRequestingRide.value = false;
    isRideAccepted.value = false;
    isRideInProgress.value = false;
    isRideCompleted.value = false;
    rideStatus.value = 'idle';
    currentRide.value = null;
    driverInfo.value = null;

    // Clear markers and polylines
    final updatedMarkers = {...markers};
    updatedMarkers.removeWhere((m) => m.markerId.value != 'user_location');
    markers.value = updatedMarkers;

    polylines.clear();

    // Reset steps
    currentStep.value = 0;
    showRideOptions.value = false;
    showDriverInfo.value = false;
    showRideDetails.value = false;

    // Clear pickup and dropoff
    pickupLocation.value = null;
    dropoffLocation.value = null;
  }

  Future<void> _saveRecentLocation(Map<String, dynamic> location) async {
    if (_authService.firebaseUser.value == null) return;

    try {
      final userId = _authService.firebaseUser.value!.uid;

      // Check if location already exists
      final existingLocations = savedLocations.where((loc) {
        return loc.address == location['address'];
      }).toList();

      if (existingLocations.isNotEmpty) {
        // Update existing location
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('saved_locations')
            .doc(existingLocations.first.id)
            .update({
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Add new location
        final newLocation = {
          'userId': userId,
          'name': location['name'],
          'address': location['address'],
          'latitude': location['latitude'],
          'longitude': location['longitude'],
          'type': 'recent',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await _firestore
            .collection('users')
            .doc(userId)
            .collection('saved_locations')
            .add(newLocation);
      }

      // Reload saved locations
      _loadSavedLocations();
    } catch (e) {
      print('Error saving recent location: $e');
    }
  }

  Future<void> saveHomeLocation(String name, String address, double latitude, double longitude) async {
    if (_authService.firebaseUser.value == null) return;

    try {
      final userId = _authService.firebaseUser.value!.uid;

      // Check if home location already exists
      final homeLocations = savedLocations.where((loc) => loc.type == 'home').toList();

      if (homeLocations.isNotEmpty) {
        // Update existing home location
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('saved_locations')
            .doc(homeLocations.first.id)
            .update({
          'name': name,
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Add new home location
        final newLocation = {
          'userId': userId,
          'name': name,
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
          'type': 'home',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await _firestore
            .collection('users')
            .doc(userId)
            .collection('saved_locations')
            .add(newLocation);
      }

      // Reload saved locations
      _loadSavedLocations();
    } catch (e) {
      print('Error saving home location: $e');
    }
  }

  Future<void> saveWorkLocation(String name, String address, double latitude, double longitude) async {
    if (_authService.firebaseUser.value == null) return;

    try {
      final userId = _authService.firebaseUser.value!.uid;

      // Check if work location already exists
      final workLocations = savedLocations.where((loc) => loc.type == 'work').toList();

      if (workLocations.isNotEmpty) {
        // Update existing work location
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('saved_locations')
            .doc(workLocations.first.id)
            .update({
          'name': name,
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Add new work location
        final newLocation = {
          'userId': userId,
          'name': name,
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
          'type': 'work',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await _firestore
            .collection('users')
            .doc(userId)
            .collection('saved_locations')
            .add(newLocation);
      }

      // Reload saved locations
      _loadSavedLocations();
    } catch (e) {
      print('Error saving work location: $e');
    }
  }

  Future<void> saveFavoriteLocation(String name, String address, double latitude, double longitude) async {
    if (_authService.firebaseUser.value == null) return;

    try {
      final userId = _authService.firebaseUser.value!.uid;

      // Add new favorite location
      final newLocation = {
        'userId': userId,
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'type': 'favorite',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_locations')
          .add(newLocation);

      // Reload saved locations
      _loadSavedLocations();
    } catch (e) {
      print('Error saving favorite location: $e');
    }
  }

  Future<void> _updateETAToPickup() async {
    if (currentRide.value == null || driverInfo.value == null) return;

    try {
      // Get driver location
      final driverMarker = markers.firstWhere(
            (m) => m.markerId.value == 'driver_location',
        orElse: () => Marker(markerId: const MarkerId('not_found')),
      );

      if (driverMarker.markerId.value == 'not_found') return;

      // Get pickup location
      final pickupLatLng = LatLng(
        pickupLocation.value!['latitude'],
        pickupLocation.value!['longitude'],
      );

      // Calculate distance
      final distance = _calculateDistance(
        driverMarker.position.latitude,
        driverMarker.position.longitude,
        pickupLatLng.latitude,
        pickupLatLng.longitude,
      );

      // Estimate duration (assuming average speed of 30 km/h)
      final duration = (distance / 30) * 60; // in minutes

      distanceToPickup.value = distance;
      durationToPickup.value = duration;
    } catch (e) {
      print('Error updating ETA to pickup: $e');
    }
  }

  Future<void> _updateETAToDestination() async {
    if (currentRide.value == null || currentLocation.value.latitude == 0) return;

    try {
      // Get dropoff location
      final dropoffLatLng = LatLng(
        dropoffLocation.value!['latitude'],
        dropoffLocation.value!['longitude'],
      );

      // Calculate distance
      final distance = _calculateDistance(
        currentLocation.value.latitude,
        currentLocation.value.longitude,
        dropoffLatLng.latitude,
        dropoffLatLng.longitude,
      );

      // Estimate duration (assuming average speed of 30 km/h)
      final duration = (distance / 30) * 60; // in minutes

      distanceToDestination.value = distance;
      durationToDestination.value = duration;
    } catch (e) {
      print('Error updating ETA to destination: $e');
    }
  }

  Future<RideModel?> getRideDetails(String rideId) async {
    try {
      final doc = await _firestore.collection('rides').doc(rideId).get();

      if (doc.exists) {
        return RideModel.fromMap(doc.data()!, doc.id);
      }

      return null;
    } catch (e) {
      print('Error getting ride details: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDriverDetails(String driverId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(driverId).get();
      final driverDoc = await _firestore.collection('drivers').doc(driverId).get();

      if (userDoc.exists && driverDoc.exists) {
        final userData = userDoc.data()!;
        final driverData = driverDoc.data()!;

        return {
          ...userData,
          ...driverData,
        };
      }

      return null;
    } catch (e) {
      print('Error getting driver details: $e');
      return null;
    }
  }

  Future<void> rateDriver(double rating, String feedback) async {
    if (currentRide.value == null) return;

    isLoading.value = true;

    try {
      await _firestore.collection('rides').doc(currentRide.value!.id).update({
        'driverRating': rating,
        'driverFeedback': feedback,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Thank You',
        'Your rating has been submitted',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error rating driver: $e');
      Get.snackbar(
        'Error',
        'Failed to submit rating',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reportDriver(String issues, String details) async {
    if (currentRide.value == null) return;

    isLoading.value = true;

    try {
      final userId = _authService.firebaseUser.value!.uid;

      // Create report
      final report = {
        'reporterId': userId,
        'reportedUserId': currentRide.value!.driverId,
        'rideId': currentRide.value!.id,
        'issues': issues,
        'details': details,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('reports').add(report);

      Get.snackbar(
        'Report Submitted',
        'Thank you for your report. We will review it shortly.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error reporting driver: $e');
      Get.snackbar(
        'Error',
        'Failed to submit report',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<RideModel>> fetchRideHistory() async {
    if (_authService.firebaseUser.value == null) return [];

    isLoadingRideHistory.value = true;

    try {
      final String userId = _authService.firebaseUser.value!.uid;

      final QuerySnapshot snapshot = await _firestore
          .collection('rides')
          .where('riderId', isEqualTo: userId)
          .where('status', whereIn: ['completed', 'cancelled'])
          .orderBy('createdAt', descending: true)
          .get();

      final List<RideModel> rides = snapshot.docs
          .map((doc) => RideModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      rideHistory.value = rides;
      return rides;
    } catch (e) {
      print('Error fetching ride history: $e');
      return [];
    } finally {
      isLoadingRideHistory.value = false;
    }
  }

  void _updateRideMarkers() async {
    if (pickupLocation.value != null) {
      await _updateLocationMarker(
        'pickup_location',
        LatLng(
          pickupLocation.value!['latitude'],
          pickupLocation.value!['longitude'],
        ),
        'assets/images/pickup_marker.png',
      );
    }

    if (dropoffLocation.value != null) {
      await _updateLocationMarker(
        'dropoff_location',
        LatLng(
          dropoffLocation.value!['latitude'],
          dropoffLocation.value!['longitude'],
        ),
        'assets/images/dropoff_marker.png',
      );
    }
  }

  void callDriver() {
    if (driverInfo.value == null) return;

    final phone = driverInfo.value!['user']['phoneNumber'];
    if (phone != null && phone.isNotEmpty) {
      // Launch phone call
      _safetyService.makePhoneCall(phone);
    } else {
      Get.snackbar(
        'Error',
        'Driver phone number not available',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void showReceipt() {
    if (currentRide.value == null) return;

    // Navigate to receipt screen
    Get.toNamed('/receipt/${currentRide.value!.id}');
  }

  void resetRide() {
    _resetRideState();

    // Reset UI
    currentStep.value = 0;
    showRideOptions.value = false;
    showFareBreakdown.value = false;

    // Reset locations
    pickupLocation.value = null;
    dropoffLocation.value = null;

    // Reset map
    _updateUserMarker();

    // Center map on user location
    if (currentLocation.value.latitude != 0 && mapController.value != null) {
      mapController.value!.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation.value, 15),
      );
    }
  }


  // Add these methods to the RiderController class

  /// Save a new location to the user's saved locations
  Future<void> saveLocation(Map<String, dynamic> location) async {
    if (_authService.firebaseUser.value == null) {
      throw Exception('User not authenticated');
    }

    isLoading.value = true;

    try {
      final userId = _authService.firebaseUser.value!.uid;

      // Validate required fields
      if (location['name'] == null || location['name'].isEmpty ||
          location['address'] == null || location['address'].isEmpty ||
          location['latitude'] == null || location['longitude'] == null) {
        throw Exception('Missing required location fields');
      }

      // Set default type if not provided
      final locationType = location['type'] ?? 'saved';

      // Check if location with same type already exists (for home/work)
      if (locationType == 'home' || locationType == 'work') {
        final existingLocations = savedLocations.where((loc) => loc.type == locationType).toList();

        if (existingLocations.isNotEmpty) {
          // Update existing location instead of creating new one
          await updateLocation({
            'id': existingLocations.first.id,
            ...location,
          });
          return;
        }
      }

      // Create new location document
      final newLocation = {
        'userId': userId,
        'name': location['name'],
        'address': location['address'],
        'latitude': location['latitude'],
        'longitude': location['longitude'],
        'type': locationType,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add to Firestore
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_locations')
          .add(newLocation);

      // Update local list
      final savedLocation = SavedLocationModel.fromMap({
        ...newLocation,
        'id': docRef.id,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });

      savedLocations.add(savedLocation);

      // Update specific location references
      if (locationType == 'home') {
        homeLocation.value = savedLocation;
      } else if (locationType == 'work') {
        workLocation.value = savedLocation;
      }

      Get.snackbar(
        'Success',
        'Location saved successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error saving location: $e');
      Get.snackbar(
        'Error',
        'Failed to save location: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update an existing saved location
  Future<void> updateLocation(Map<String, dynamic> updatedLocation) async {
    if (_authService.firebaseUser.value == null) {
      throw Exception('User not authenticated');
    }

    isLoading.value = true;

    try {
      final userId = _authService.firebaseUser.value!.uid;

      // Validate required fields
      if (updatedLocation['id'] == null || updatedLocation['id'].isEmpty) {
        throw Exception('Location ID is required for update');
      }

      final locationId = updatedLocation['id'];

      // Find the location in local list
      final locationIndex = savedLocations.indexWhere((loc) => loc.id == locationId);
      if (locationIndex == -1) {
        throw Exception('Location not found');
      }

      // Prepare update data
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only include fields that are provided and not null
      if (updatedLocation['name'] != null) {
        updateData['name'] = updatedLocation['name'];
      }
      if (updatedLocation['address'] != null) {
        updateData['address'] = updatedLocation['address'];
      }
      if (updatedLocation['latitude'] != null) {
        updateData['latitude'] = updatedLocation['latitude'];
      }
      if (updatedLocation['longitude'] != null) {
        updateData['longitude'] = updatedLocation['longitude'];
      }
      if (updatedLocation['type'] != null) {
        updateData['type'] = updatedLocation['type'];
      }

      // Update in Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_locations')
          .doc(locationId)
          .update(updateData);

      // Update local list
      final currentLocation = savedLocations[locationIndex];
      final updatedLocationModel = SavedLocationModel.fromMap({
        'id': currentLocation.id,
        'userId': userId,
        'name': updatedLocation['name'] ?? currentLocation.name,
        'address': updatedLocation['address'] ?? currentLocation.address,
        'latitude': updatedLocation['latitude'] ?? currentLocation.latitude,
        'longitude': updatedLocation['longitude'] ?? currentLocation.longitude,
        'type': updatedLocation['type'] ?? currentLocation.type,
        'updatedAt': DateTime.now(),
      });

      savedLocations[locationIndex] = updatedLocationModel;

      // Update specific location references if needed
      if (updatedLocationModel.type == 'home') {
        homeLocation.value = updatedLocationModel;
      } else if (updatedLocationModel.type == 'work') {
        workLocation.value = updatedLocationModel;
      }

      Get.snackbar(
        'Success',
        'Location updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error updating location: $e');
      Get.snackbar(
        'Error',
        'Failed to update location: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete a saved location
  Future<void> deleteLocation(String locationId) async {
    if (_authService.firebaseUser.value == null) {
      throw Exception('User not authenticated');
    }

    isLoading.value = true;

    try {
      final userId = _authService.firebaseUser.value!.uid;

      // Validate location ID
      if (locationId.isEmpty) {
        throw Exception('Location ID is required');
      }

      // Find the location in local list
      final locationIndex = savedLocations.indexWhere((loc) => loc.id == locationId);
      if (locationIndex == -1) {
        throw Exception('Location not found');
      }

      final locationToDelete = savedLocations[locationIndex];

      // Delete from Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_locations')
          .doc(locationId)
          .delete();

      // Remove from local list
      savedLocations.removeAt(locationIndex);

      // Clear specific location references if needed
      if (homeLocation.value?.id == locationId) {
        homeLocation.value = null;
      }
      if (workLocation.value?.id == locationId) {
        workLocation.value = null;
      }

      Get.snackbar(
        'Success',
        'Location deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error deleting location: $e');
      Get.snackbar(
        'Error',
        'Failed to delete location: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }


}
