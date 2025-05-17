import 'dart:async';
import 'package:easy_ride/modules/rider/views/nearby_drivers_view.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:easy_ride/core/services/location_service.dart';
import 'package:easy_ride/core/services/auth_service.dart';
import 'package:easy_ride/core/services/storage_service.dart';
import 'package:easy_ride/core/services/safety_service.dart';
import 'package:easy_ride/core/services/notification_service.dart';
import 'package:easy_ride/core/services/api_service.dart';
import 'package:easy_ride/models/ride_model.dart';
import 'package:easy_ride/models/driver_model.dart';
import 'package:easy_ride/models/user_model.dart';
import 'package:easy_ride/modules/rider/models/fare_model.dart';
import 'package:easy_ride/modules/rider/models/saved_location_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:uuid/uuid.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:math' show pi, sqrt, atan2, sin, cos;
import 'dart:io';
import 'package:easy_ride/core/values/constants.dart';
import 'package:easy_ride/models/location_model.dart';
import 'package:easy_ride/core/utils/logs.dart';

class RiderController extends GetxController {
  final LocationService _locationService = Get.find<LocationService>();
  final AuthService _authService = Get.find<AuthService>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = Get.find<StorageService>();
  final SafetyService _safetyService = Get.find<SafetyService>();
  final NotificationService _notificationService = Get.find<NotificationService>();
  final ApiService _apiService = Get.find<ApiService>();

  // Map controller
  Rx<GoogleMapController?> mapController = Rx<GoogleMapController?>(null);
  Rx<GoogleMapController?> tempMapController = Rx<GoogleMapController?>(null);

  final Rx<UserModel?> userProfile = Rx<UserModel?>(null);
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
  final Rx<LocationModel?> pickupLocation = Rx<LocationModel?>(null);
  final Rx<LocationModel?> dropoffLocation = Rx<LocationModel?>(null);

  // Ride options
  final RxString selectedRideType = Constants.standardRide.obs;
  final RxString selectedPaymentMethod = Constants.cardPayment.obs;

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

  // Search state
  final RxString searchQuery = ''.obs;
  final RxList<LocationModel> searchResults = <LocationModel>[].obs;
  final RxBool isSearching = false.obs;
  final RxBool showRecentSearches = false.obs;
  final RxList<String> recentSearches = <String>[].obs;

  // Navigation
  final RxInt selectedNavIndex = 0.obs;

  // Streams
  StreamSubscription? _locationSubscription;
  StreamSubscription? _rideSubscription;
  StreamSubscription? _driverLocationSubscription;

  // Loading
  final RxBool isLoading = false.obs;

  // Ride history
  final RxList<RideModel> rideHistory = <RideModel>[].obs;
  final RxBool isLoadingRideHistory = false.obs;

  // Polyline string for ride request
  String? polylineString;

  // Theme
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  // Nearby drivers
  final RxList<Map<String, dynamic>> nearbyDrivers = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingNearbyDrivers = false.obs;
  final RxSet<Marker> nearbyDriverMarkers = <Marker>{}.obs;

  // Ride start confirmation
  final RxBool isWaitingForRideStart = false.obs;
  final RxBool hasRiderConfirmedStart = false.obs;
  final RxBool hasDriverConfirmedStart = false.obs;

  @override
  void onInit() {
    super.onInit();
    DevLogs.info('RiderController initialized');
    _initLocationTracking();
    _loadSavedLocations();
    _checkForActiveRide();
    _loadSurgePricing();
    _loadRecentSearches();

    // Add a delay to ensure location is obtained before updating the map
    Future.delayed(Duration(seconds: 1), () {
      _updateInitialMapPosition();
    });
  }

  // Add a new method to update the initial map position
  void _updateInitialMapPosition() {
    if (currentLocation.value.latitude != 0 && currentLocation.value.longitude != 0) {
      initialCameraPosition.value = CameraPosition(
        target: currentLocation.value,
        zoom: mapZoom.value,
      );

      if (mapController.value != null) {
        mapController.value!.animateCamera(
          CameraUpdate.newLatLngZoom(currentLocation.value, mapZoom.value),
        );
        _updateUserMarker();
      }

      DevLogs.info('Map centered on user location: ${currentLocation.value.latitude}, ${currentLocation.value.longitude}');
    } else {
      // If location is not available yet, try again after a delay
      DevLogs.warning('User location not available yet, retrying...');
      Future.delayed(Duration(seconds: 2), () {
        _updateInitialMapPosition();
      });
    }
  }

  // Update the _initLocationTracking method to be more robust
  void _initLocationTracking() {
    DevLogs.debug('Initializing location tracking in RiderController');

    // Get initial location from LocationService if available
    final locationService = Get.find<LocationService>();
    if (locationService.currentLocation.value != null &&
        locationService.currentLocation.value!.latitude != null &&
        locationService.currentLocation.value!.longitude != null) {

      currentLocation.value = LatLng(
          locationService.currentLocation.value!.latitude!,
          locationService.currentLocation.value!.longitude!
      );

      DevLogs.info('Initial location set from LocationService: ${currentLocation.value.latitude}, ${currentLocation.value.longitude}');
    }

    _locationSubscription = _locationService.locationStream.listen((position) {
      if (position.latitude != null && position.longitude != null) {
        currentLocation.value = LatLng(position.latitude!, position.longitude!);
        DevLogs.debug('Location updated in RiderController: ${position.latitude}, ${position.longitude}');

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

  // Update the onMapCreated method to center on user location
  void onMapCreated(GoogleMapController controller) {
    mapController.value = controller;
    isMapLoading.value = false;


    // Center map on user location if available
    if (currentLocation.value.latitude != 0) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation.value, mapZoom.value),
      );
      _updateUserMarker();
      DevLogs.info('Map centered on user location during creation');
    } else {
      DevLogs.warning('User location not available during map creation');
      // Try to get location and center map after a short delay
      Future.delayed(Duration(seconds: 1), () {
        if (currentLocation.value.latitude != 0) {
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(currentLocation.value, mapZoom.value),
          );
          _updateUserMarker();
          DevLogs.info('Map centered on user location after delay');
        }
      });
    }
  }

  @override
  void onClose() {
    _locationSubscription?.cancel();
    _rideSubscription?.cancel();
    _driverLocationSubscription?.cancel();
    mapController.value?.dispose();
    tempMapController.value?.dispose();
    DevLogs.info('RiderController disposed');
    super.onClose();
  }



  void toggleFollowUser() {
    isFollowingUser.value = !isFollowingUser.value;

    if (isFollowingUser.value && currentLocation.value.latitude != 0 && mapController.value != null) {
      mapController.value!.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation.value, mapZoom.value),
      );
      DevLogs.debug('Following user location enabled');
    } else {
      DevLogs.debug('Following user location disabled');
    }
  }

  Future<void> _updateUserMarker() async {
    if (currentLocation.value.latitude == 0) {
      DevLogs.warning('Cannot update user marker: invalid location');
      return;
    }

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
      DevLogs.debug('User marker updated at: ${currentLocation.value.latitude}, ${currentLocation.value.longitude}');
    } catch (e) {
      DevLogs.error('Error updating user marker', exception: e);
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
      DevLogs.debug('Used fallback marker for user location');
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
      DevLogs.error('Error creating custom marker', exception: e);
      return BitmapDescriptor.defaultMarker;
    }
  }

  Future<void> _loadSavedLocations() async {
    if (_authService.firebaseUser.value == null) return;

    isLoadingSavedLocations.value = true;
    DevLogs.debug('Loading saved locations');

    try {
      final userId = _authService.firebaseUser.value!.uid;
      final snapshot = await _firestore
          .collection(Constants.usersCollection)
          .doc(userId)
          .collection(Constants.savedLocationsCollection)
          .orderBy('createdAt', descending: true)
          .get();

      final locations = snapshot.docs.map((doc) {
        return SavedLocationModel.fromMap(doc.data(), doc.id);
      }).toList();

      savedLocations.value = locations;

      // Set home and work locations
      homeLocation.value = locations.firstWhereOrNull((loc) => loc.type == LocationType.home);
      workLocation.value = locations.firstWhereOrNull((loc) => loc.type == LocationType.work);

      DevLogs.debug('Loaded ${locations.length} saved locations');
    } catch (e) {
      DevLogs.error('Error loading saved locations', exception: e);
    } finally {
      isLoadingSavedLocations.value = false;
    }
  }

  Future<void> _checkForActiveRide() async {
    if (_authService.firebaseUser.value == null) return;

    DevLogs.debug('Checking for active ride');
    try {
      final userId = _authService.firebaseUser.value!.uid;
      final snapshot = await _firestore
          .collection(Constants.ridesCollection)
          .where('riderId', isEqualTo: userId)
          .where('status', whereIn: [Constants.pending, Constants.accepted, Constants.arrived, Constants.started])
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
        if (ride.status == Constants.accepted || ride.status == Constants.arrived || ride.status == Constants.started) {
          _getDriverInfo(ride.driverId!);
        }

        DevLogs.info('Active ride found: ${ride.id}');
      } else {
        DevLogs.debug('No active ride found');
      }
    } catch (e) {
      DevLogs.error('Error checking for active ride', exception: e);
    }
  }

  void _setRideStateFromStatus(String status) {
    rideStatus.value = status;

    switch (status) {
      case Constants.pending:
        isRequestingRide.value = true;
        isRideAccepted.value = false;
        isRideInProgress.value = false;
        isRideCompleted.value = false;
        break;
      case Constants.accepted:
        isRequestingRide.value = false;
        isRideAccepted.value = true;
        isRideInProgress.value = false;
        isRideCompleted.value = false;
        break;
      case Constants.arrived:
        isRequestingRide.value = false;
        isRideAccepted.value = true;
        isRideInProgress.value = false;
        isRideCompleted.value = false;
        isWaitingForRideStart.value = true;
        break;
      case Constants.started:
        isRequestingRide.value = false;
        isRideAccepted.value = true;
        isRideInProgress.value = true;
        isRideCompleted.value = false;
        isWaitingForRideStart.value = false;
        break;
      case Constants.completed:
        isRequestingRide.value = false;
        isRideAccepted.value = false;
        isRideInProgress.value = false;
        isRideCompleted.value = true;
        isWaitingForRideStart.value = false;
        break;
      default:
        isRequestingRide.value = false;
        isRideAccepted.value = false;
        isRideInProgress.value = false;
        isRideCompleted.value = false;
        isWaitingForRideStart.value = false;
        break;
    }
  }

  void _listenForRideUpdates(String rideId) {
    _rideSubscription?.cancel();

    DevLogs.debug('Starting to listen for ride updates: $rideId');
    _rideSubscription = _firestore
        .collection(Constants.ridesCollection)
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
        if (ride.status == Constants.accepted && driverInfo.value == null && ride.driverId != null) {
          _getDriverInfo(ride.driverId!);
        }

        // If driver has arrived, show ride start confirmation
        if (ride.status == Constants.arrived) {
          isWaitingForRideStart.value = true;
          hasDriverConfirmedStart.value = true;
          hasRiderConfirmedStart.value = false;
        }

        // If ride is completed or cancelled, stop listening
        if (ride.status == Constants.completed || ride.status == Constants.cancelled) {
          _rideSubscription?.cancel();
          _driverLocationSubscription?.cancel();

          // Show rating dialog if completed
          if (ride.status == Constants.completed) {
            Get.toNamed('/rider/rate-driver', arguments: ride.id);
          }
        }

        DevLogs.debug('Ride update received: ${ride.status}');
      }
    });
  }

  Future<void> _getDriverInfo(String driverId) async {
    DevLogs.debug('Getting driver info: $driverId');
    try {
      final userDoc = await _firestore.collection(Constants.usersCollection).doc(driverId).get();
      final driverDoc = await _firestore.collection(Constants.driversCollection).doc(driverId).get();

      if (userDoc.exists && driverDoc.exists) {
        final userData = userDoc.data()!;
        final driverData = driverDoc.data()!;

        final UserModel user = UserModel.fromMap(userData, driverId);
        final DriverModel driver = DriverModel.fromJson(driverData);

        driverInfo.value = {
          'user': user,
          'driver': driver,
        };

        // Start listening for driver location updates
        _listenForDriverLocationUpdates(driverId);

        DevLogs.debug('Driver info retrieved successfully');
      }
    } catch (e) {
      DevLogs.error('Error getting driver info', exception: e);
    }
  }

  void _listenForDriverLocationUpdates(String driverId) {
    _driverLocationSubscription?.cancel();

    DevLogs.debug('Starting to listen for driver location updates: $driverId');

    // First, try to listen to the dedicated rideLocations collection
    _driverLocationSubscription = _firestore
        .collection('rideLocations')
        .doc(currentRide.value!.id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;

        if (data['location'] != null) {
          final GeoPoint location = data['location'];
          final driverLatLng = LatLng(location.latitude, location.longitude);

          // Update driver marker
          _updateDriverMarker(driverLatLng);

          // Update ETA
          if (isRideAccepted.value && !isRideInProgress.value) {
            _updateETAToPickup();
          }

          DevLogs.debug('Driver location updated from rideLocations');
        }
      }
    }, onError: (e) {
      // Fallback to the driver_locations collection if there's an error
      DevLogs.error('Error listening to rideLocations, falling back to driver_locations', exception: e);

      _driverLocationSubscription?.cancel();
      _driverLocationSubscription = _firestore
          .collection(Constants.driverLocationsCollection)
          .doc(driverId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data()!;

          if (data['location'] != null) {
            final GeoPoint location = data['location'];
            final driverLatLng = LatLng(location.latitude, location.longitude);

            // Update driver marker
            _updateDriverMarker(driverLatLng);

            // Update ETA
            if (isRideAccepted.value && !isRideInProgress.value) {
              _updateETAToPickup();
            }

            DevLogs.debug('Driver location updated from driver_locations');
          }
        }
      });
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
      DevLogs.error('Error updating driver marker', exception: e);
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

  Future<void> setPickupLocation(LocationModel location) async {
    DevLogs.debug('Setting pickup location: ${location.name}');
    pickupLocation.value = location;

    // Update marker
    await _updateLocationMarker(
      'pickup_location',
      location.latLng,
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

  Future<void> setDropoffLocation(LocationModel location) async {
    DevLogs.debug('Setting dropoff location: ${location.name}');
    dropoffLocation.value = location;

    // Update marker
    await _updateLocationMarker(
      'dropoff_location',
      location.latLng,
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
      DevLogs.error('Error updating location marker', exception: e);
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

    DevLogs.debug('Calculating route between pickup and dropoff');
    try {
      final pickupLatLng = pickupLocation.value!.latLng;
      final dropoffLatLng = dropoffLocation.value!.latLng;

      // Get directions from the LocationService
      final directions = await _locationService.getDirections(pickupLatLng, dropoffLatLng);

      // Update route points
      routePoints.value = directions['polylinePoints'];

      // Create polyline
      final polyline = Polyline(
        polylineId: const PolylineId('route'),
        color: Colors.blue,
        points: routePoints,
        width: 5,
      );

      polylines.value = {polyline};

      // Update distance and duration
      distanceToDestination.value = directions['distance']['value'] / 1000; // Convert to km
      durationToDestination.value = directions['duration']['value'] / 60; // Convert to minutes

      // Save polyline for ride request
      polylineString = directions['polyline'];

      DevLogs.debug('Route calculated: ${distanceToDestination.value.toStringAsFixed(2)} km, ${durationToDestination.value.toStringAsFixed(0)} min');
    } catch (e) {
      DevLogs.error('Error calculating route', exception: e);
      Get.snackbar(
        'Error',
        'Failed to calculate route. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
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
    DevLogs.debug('Calculating fare for ride');

    try {
      // Calculate fare based on distance and duration
      final fare = FareModel.calculate(
        rideType: selectedRideType.value,
        distance: distanceToDestination.value,
        duration: durationToDestination.value,
        surgeFactor: surgeFactor.value,
      );

      fareEstimate.value = fare;
      DevLogs.debug('Fare calculated: \$${fare.totalFare.toStringAsFixed(2)}');
    } catch (e) {
      DevLogs.error('Error calculating fare', exception: e);
    } finally {
      isCalculatingFare.value = false;
    }
  }

  Future<void> _loadSurgePricing() async {
    DevLogs.debug('Loading surge pricing');
    try {
      // In a real app, this would be fetched from the server based on demand
      // For now, we'll get it from Firestore
      final doc = await _firestore.collection('settings').doc('pricing').get();

      if (doc.exists) {
        final data = doc.data()!;
        surgeFactor.value = data['surgeFactor'] ?? 1.0;
      } else {
        // Fallback to time-based surge if no server data
        final hour = DateTime.now().hour;

        // Simulate surge pricing during peak hours (7-9 AM and 5-7 PM)
        if ((hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19)) {
          surgeFactor.value = 1.5; // 50% surge
        } else {
          surgeFactor.value = 1.0; // No surge
        }
      }

      DevLogs.debug('Surge factor: ${surgeFactor.value}');
    } catch (e) {
      DevLogs.error('Error loading surge pricing', exception: e);
      surgeFactor.value = 1.0; // Default to no surge
    }
  }

  Future<void> _loadRecentSearches() async {
    if (_authService.firebaseUser.value == null) return;

    DevLogs.debug('Loading recent searches');
    try {
      final userId = _authService.firebaseUser.value!.uid;
      final doc = await _firestore
          .collection(Constants.usersCollection)
          .doc(userId)
          .collection('app_data')
          .doc('searches')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final searches = List<String>.from(data['recent'] ?? []);
        recentSearches.value = searches;
        DevLogs.debug('Loaded ${searches.length} recent searches');
      }
    } catch (e) {
      DevLogs.error('Error loading recent searches', exception: e);
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    if (_authService.firebaseUser.value == null || query.isEmpty) return;

    DevLogs.debug('Saving recent search: $query');
    try {
      final userId = _authService.firebaseUser.value!.uid;

      // Add to local list first
      final searches = [...recentSearches];

      // Remove if already exists
      searches.remove(query);

      // Add to beginning
      searches.insert(0, query);

      // Keep only the most recent 10
      if (searches.length > 10) {
        searches.removeLast();
      }

      recentSearches.value = searches;

      // Save to Firestore
      await _firestore
          .collection(Constants.usersCollection)
          .doc(userId)
          .collection('app_data')
          .doc('searches')
          .set({
        'recent': searches,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      DevLogs.error('Error saving recent search', exception: e);
    }
  }

  Future<List<LocationModel>> searchPlaces(String query) async {
    if (query.isEmpty) {
      searchResults.clear();
      return [];
    }

    isSearching.value = true;
    DevLogs.debug('Searching places: $query');

    try {
      // Save search query
      await _saveRecentSearch(query);

      // Get current location for better results
      final location = currentLocation.value.latitude != 0 ? currentLocation.value : null;

      // Search places
      final results = await _locationService.searchPlaces(query, location);
      searchResults.value = results;

      DevLogs.debug('Found ${results.length} places');

      return results;
    } catch (e) {
      DevLogs.error('Error searching places', exception: e);
      Get.snackbar(
        'Error',
        'Failed to search places. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return [];
    } finally {
      isSearching.value = false;
    }
  }

  // Fetch nearby drivers for the rider to select from
  Future<void> fetchNearbyDrivers() async {
    if (pickupLocation.value == null) {
      Get.snackbar(
        'Error',
        'Please set a pickup location first',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoadingNearbyDrivers.value = true;
    DevLogs.debug('Fetching nearby drivers');

    try {
      // Get nearby drivers from Firestore
      final driversSnapshot = await _firestore
          .collection(Constants.driverLocationsCollection)
          .where('isOnline', isEqualTo: true)
          .where('isBusy', isEqualTo: false)
          .get();

      final List<Map<String, dynamic>> drivers = [];
      final Set<Marker> driverMarkers = {};

      for (var doc in driversSnapshot.docs) {
        final data = doc.data();
        final driverId = data['driverId'] as String;
        final location = data['location'] as GeoPoint;

        // Calculate distance to pickup
        final distance = _calculateDistance(
          pickupLocation.value!.latitude,
          pickupLocation.value!.longitude,
          location.latitude,
          location.longitude,
        );

        // Only include drivers within 10km
        if (distance <= 10.0) {
          // Get driver details
          final driverDoc = await _firestore.collection('drivers').doc(driverId).get();
          final userDoc = await _firestore.collection('users').doc(driverId).get();

          if (driverDoc.exists && userDoc.exists) {
            final driverData = driverDoc.data()!;
            final userData = userDoc.data()!;

            final driver = {
              'id': driverId,
              'distance': distance,
              'location': LatLng(location.latitude, location.longitude),
              'driver': DriverModel.fromJson(driverData),
              'user': UserModel.fromMap(userData, driverId),
            };

            drivers.add(driver);

            // Create marker for this driver
            try {
              final BitmapDescriptor icon = await _createCustomMarkerBitmap(
                'assets/images/car_marker.png',
                size: 120,
              );

              final marker = Marker(
                markerId: MarkerId('driver_$driverId'),
                position: LatLng(location.latitude, location.longitude),
                icon: icon,
                infoWindow: InfoWindow(
                  title: userData['fullName'] ?? 'Driver',
                  snippet: '${distance.toStringAsFixed(1)} km away',
                ),
              );

              driverMarkers.add(marker);
            } catch (e) {
              DevLogs.error('Error creating driver marker', exception: e);
              // Fallback to default marker
              final marker = Marker(
                markerId: MarkerId('driver_$driverId'),
                position: LatLng(location.latitude, location.longitude),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                infoWindow: InfoWindow(
                  title: userData['fullName'] ?? 'Driver',
                  snippet: '${distance.toStringAsFixed(1)} km away',
                ),
              );

              driverMarkers.add(marker);
            }
          }
        }
      }

      // Sort drivers by distance
      drivers.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

      // Update state
      nearbyDrivers.value = drivers;
      nearbyDriverMarkers.value = driverMarkers;

      // Add user marker to the map
      try {
        final BitmapDescriptor icon = await _createCustomMarkerBitmap(
          'assets/images/user_marker.png',
          size: 120,
        );

        final userMarker = Marker(
          markerId: const MarkerId('user_pickup_location'),
          position: LatLng(pickupLocation.value!.latitude, pickupLocation.value!.longitude),
          icon: icon,
          infoWindow: const InfoWindow(title: 'Your Pickup Location'),
        );

        nearbyDriverMarkers.add(userMarker);
      } catch (e) {
        DevLogs.error('Error creating user marker', exception: e);
        // Fallback to default marker
        final userMarker = Marker(
          markerId: const MarkerId('user_pickup_location'),
          position: LatLng(pickupLocation.value!.latitude, pickupLocation.value!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Your Pickup Location'),
        );

        nearbyDriverMarkers.add(userMarker);
      }

      DevLogs.debug('Found ${drivers.length} nearby drivers');

      // Fit map to show all drivers
      if (tempMapController.value != null && driverMarkers.isNotEmpty) {
        fitMapToDrivers();
      }
    } catch (e) {
      DevLogs.error('Error fetching nearby drivers', exception: e);
      Get.snackbar(
        'Error',
        'Failed to fetch nearby drivers. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingNearbyDrivers.value = false;
    }
  }

  void fitMapToDrivers() {
    if (tempMapController.value == null || nearbyDriverMarkers.isEmpty) return;

    try {
      // Get all marker positions
      final positions = nearbyDriverMarkers.map((m) => m.position).toList();

      if (positions.isEmpty) return;

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
        southwest: LatLng(minLat - 0.02, minLng - 0.02),
        northeast: LatLng(maxLat + 0.02, maxLng + 0.02),
      );

      tempMapController.value!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    } catch (e) {
      DevLogs.error('Error fitting map to drivers', exception: e);
    }
  }

  // Select a specific driver for the ride
  Future<void> selectDriver(Map<String, dynamic> driver) async {
    if (pickupLocation.value == null || dropoffLocation.value == null) {
      Get.snackbar(
        'Error',
        'Please set pickup and dropoff locations first',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    DevLogs.debug('Selecting driver: ${driver['id']}');

    try {
      // Create a ride request with the selected driver
      final userId = _authService.firebaseUser.value!.uid;
      final rideId = const Uuid().v4();

      // Calculate fare
      await calculateFare();

      // Create ride request
      final ride = RideModel(
        id: rideId,
        riderId: userId,
        driverId: driver['id'],
        pickup: pickupLocation.value!,
        dropoff: dropoffLocation.value!,
        rideType: selectedRideType.value,
        paymentMethod: selectedPaymentMethod.value,
        fare: fareEstimate.value!.totalFare,
        distance: distanceToDestination.value,
        duration: durationToDestination.value,
        status: Constants.pending,
        createdAt: DateTime.now(),
        polyline: polylineString,
      );

      // Save ride to Firestore
      await _firestore.collection(Constants.ridesCollection).doc(rideId).set(ride.toMap());

      // Create a ride request document
      await _firestore.collection('rideRequests').doc(rideId).set({
        'id': rideId,
        'riderId': userId,
        'driverId': driver['id'],
        'pickup': pickupLocation.value!.toMap(),
        'dropoff': dropoffLocation.value!.toMap(),
        'rideType': selectedRideType.value,
        'paymentMethod': selectedPaymentMethod.value,
        'fare': fareEstimate.value!.totalFare,
        'distance': distanceToDestination.value,
        'duration': durationToDestination.value,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'rideId': rideId,
      });

      // Start listening for ride updates
      _listenForRideUpdates(rideId);

      // Save recent location
      _saveRecentLocation(dropoffLocation.value!);

      // Send notification to the selected driver
      await _notificationService.sendNotificationToUser(
        driver['id'],
        'New Ride Request',
        'You have a new ride request',
        {
          'type': 'ride_request',
          'rideId': rideId,
        },
      );

      // Update UI state
      isRequestingRide.value = true;
      rideStatus.value = Constants.pending;
      currentRide.value = ride;

      // Navigate back to the main screen
      Get.back();

      // Show a snackbar
      Get.snackbar(
        'Ride Requested',
        'Waiting for driver to accept your request',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      DevLogs.info('Ride requested successfully with specific driver: $rideId');
    } catch (e) {
      DevLogs.error('Error requesting ride with specific driver', exception: e);
      Get.snackbar(
        'Error',
        'Failed to request ride. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> requestRide() async {
    if (pickupLocation.value == null || dropoffLocation.value == null) return;
    if (_authService.firebaseUser.value == null) return;

    // Navigate to nearby drivers view
    Get.to(
        ()=> NearbyDriversView()
    );

    // Fetch nearby drivers
    await fetchNearbyDrivers();
  }

  Future<void> cancelRide() async {
    if (currentRide.value == null) return;

    DevLogs.info('Cancelling ride: ${currentRide.value!.id}');
    try {
      await _firestore.collection(Constants.ridesCollection).doc(currentRide.value!.id).update({
        'status': Constants.cancelled,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': 'rider',
        'cancellationReason': 'Cancelled by rider',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also update the ride request if it exists
      try {
        await _firestore.collection('rideRequests').doc(currentRide.value!.id).update({
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancelledBy': 'rider',
        });
      } catch (e) {
        DevLogs.error('Error updating ride request on cancellation', exception: e);
      }

      // If driver was assigned, send cancellation notification
      if (currentRide.value!.driverId != null) {
        await _notificationService.sendNotificationToUser(
          currentRide.value!.driverId!,
          'Ride Cancelled',
          'The rider has cancelled the ride',
          {
            'type': NotificationService.rideCancelled,
            'rideId': currentRide.value!.id,
          },
        );
      }

      // Reset state
      _resetRideState();

      DevLogs.info('Ride cancelled successfully');
    } catch (e) {
      DevLogs.error('Error cancelling ride', exception: e);

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
    isWaitingForRideStart.value = false;
    hasRiderConfirmedStart.value = false;
    hasDriverConfirmedStart.value = false;

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

    DevLogs.debug('Ride state reset');
  }

  Future<void> _saveRecentLocation(LocationModel location) async {
    if (_authService.firebaseUser.value == null) return;

    DevLogs.debug('Saving recent location: ${location.name}');
    try {
      final userId = _authService.firebaseUser.value!.uid;

      // Check if location already exists
      final existingLocations = savedLocations.where((loc) {
        return loc.address == location.address;
      }).toList();

      if (existingLocations.isNotEmpty) {
        // Update existing location
        await _firestore
            .collection(Constants.usersCollection)
            .doc(userId)
            .collection(Constants.savedLocationsCollection)
            .doc(existingLocations.first.id)
            .update({
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Add new location
        final newLocation = SavedLocationModel(
          id: const Uuid().v4(),
          name: location.name,
          address: location.address,
          latitude: location.latitude,
          longitude: location.longitude,
          type: LocationType.recent,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection(Constants.usersCollection)
            .doc(userId)
            .collection(Constants.savedLocationsCollection)
            .doc(newLocation.id)
            .set(newLocation.toMap());
      }

      // Reload saved locations
      _loadSavedLocations();
    } catch (e) {
      DevLogs.error('Error saving recent location', exception: e);
    }
  }

  Future<void> saveLocation(Map<String, dynamic> locationData) async {
    if (_authService.firebaseUser.value == null) return;

    DevLogs.debug('Saving location: ${locationData['name']}');
    try {
      final userId = _authService.firebaseUser.value!.uid;

      // Create location model
      final location = SavedLocationModel(
        id: const Uuid().v4(),
        name: locationData['name'],
        address: locationData['address'],
        latitude: locationData['latitude'],
        longitude: locationData['longitude'],
        type: _getLocationType(locationData['type']),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(Constants.usersCollection)
          .doc(userId)
          .collection(Constants.savedLocationsCollection)
          .doc(location.id)
          .set(location.toMap());

      // Reload saved locations
      _loadSavedLocations();

      DevLogs.debug('Location saved successfully');
    } catch (e) {
      DevLogs.error('Error saving location', exception: e);
      throw e;
    }
  }

  LocationType _getLocationType(String type) {
    switch (type) {
      case 'home':
        return LocationType.home;
      case 'work':
        return LocationType.work;
      case 'favorite':
        return LocationType.favorite;
      case 'recent':
        return LocationType.recent;
      default:
        return LocationType.custom;
    }
  }

  Future<void> updateLocation(SavedLocationModel location) async {
    if (_authService.firebaseUser.value == null) return;

    DevLogs.debug('Updating location: ${location.id}');
    try {
      final userId = _authService.firebaseUser.value!.uid;

      await _firestore
          .collection(Constants.usersCollection)
          .doc(userId)
          .collection(Constants.savedLocationsCollection)
          .doc(location.id)
          .update(location.toMap());

      // Reload saved locations
      _loadSavedLocations();

      DevLogs.debug('Location updated successfully');
    } catch (e) {
      DevLogs.error('Error updating location', exception: e);
      throw e;
    }
  }

  Future<void> deleteLocation(String locationId) async {
    if (_authService.firebaseUser.value == null) return;

    DevLogs.debug('Deleting location: $locationId');
    try {
      final userId = _authService.firebaseUser.value!.uid;

      await _firestore
          .collection(Constants.usersCollection)
          .doc(userId)
          .collection(Constants.savedLocationsCollection)
          .doc(locationId)
          .delete();

      // Reload saved locations
      _loadSavedLocations();

      DevLogs.debug('Location deleted successfully');
    } catch (e) {
      DevLogs.error('Error deleting location', exception: e);
      throw e;
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
      final pickupLatLng = pickupLocation.value!.latLng;

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

      DevLogs.debug('ETA to pickup: ${distance.toStringAsFixed(2)} km, ${duration.toStringAsFixed(0)} min');
    } catch (e) {
      DevLogs.error('Error updating ETA to pickup', exception: e);
    }
  }

  Future<void> _updateETAToDestination() async {
    if (currentRide.value == null || currentLocation.value.latitude == 0) return;

    try {
      // Get dropoff location
      final dropoffLatLng = dropoffLocation.value!.latLng;

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

      DevLogs.debug('ETA to destination: ${distance.toStringAsFixed(2)} km, ${duration.toStringAsFixed(0)} min');
    } catch (e) {
      DevLogs.error('Error updating ETA to destination', exception: e);
    }
  }

  Future<RideModel?> getRideDetails(String rideId) async {
    DevLogs.debug('Getting ride details: $rideId');
    try {
      final doc = await _firestore.collection(Constants.ridesCollection).doc(rideId).get();

      if (doc.exists) {
        return RideModel.fromMap(doc.data()!, doc.id);
      }

      return null;
    } catch (e) {
      DevLogs.error('Error getting ride details', exception: e);
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDriverDetails(String driverId) async {
    DevLogs.debug('Getting driver details: $driverId');
    try {
      final userDoc = await _firestore.collection(Constants.usersCollection).doc(driverId).get();
      final driverDoc = await _firestore.collection(Constants.driversCollection).doc(driverId).get();

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
      DevLogs.error('Error getting driver details', exception: e);
      return null;
    }
  }

  Future<void> rateDriver(String rideId, double rating, String feedback) async {
    DevLogs.info('Rating driver for ride: $rideId');
    isLoading.value = true;

    try {
      await _firestore.collection(Constants.ridesCollection).doc(rideId).update({
        'driverRating': rating,
        'driverFeedback': feedback,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get driver ID from ride
      final rideDoc = await _firestore.collection(Constants.ridesCollection).doc(rideId).get();
      if (rideDoc.exists) {
        final rideData = rideDoc.data()!;
        final driverId = rideData['driverId'];

        if (driverId != null) {
          // Update driver's average rating
          await _updateDriverRating(driverId, rating);
        }
      }

      Get.snackbar(
        'Thank You',
        'Your rating has been submitted',
        snackPosition: SnackPosition.BOTTOM,
      );

      DevLogs.info('Driver rated successfully');
    } catch (e) {
      DevLogs.error('Error rating driver', exception: e);
      Get.snackbar(
        'Error',
        'Failed to submit rating',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _updateDriverRating(String driverId, double newRating) async {
    try {
      // Get driver document
      final driverDoc = await _firestore.collection(Constants.driversCollection).doc(driverId).get();

      if (driverDoc.exists) {
        final data = driverDoc.data()!;
        final currentRating = data['rating'] ?? 0.0;
        final ratingCount = data['ratingCount'] ?? 0;

        // Calculate new average rating
        final newAvgRating = ((currentRating * ratingCount) + newRating) / (ratingCount + 1);

        // Update driver document
        await _firestore.collection(Constants.driversCollection).doc(driverId).update({
          'rating': newAvgRating,
          'ratingCount': ratingCount + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        DevLogs.debug('Driver rating updated: $newAvgRating (${ratingCount + 1} ratings)');
      }
    } catch (e) {
      DevLogs.error('Error updating driver rating', exception: e);
    }
  }

  Future<void> reportDriver(String rideId, String issues, String details) async {
    DevLogs.info('Reporting driver for ride: $rideId');
    isLoading.value = true;

    try {
      final userId = _authService.firebaseUser.value!.uid;

      // Get ride details to get driver ID
      final rideDoc = await _firestore.collection(Constants.ridesCollection).doc(rideId).get();
      if (!rideDoc.exists) {
        throw Exception('Ride not found');
      }

      final rideData = rideDoc.data()!;
      final driverId = rideData['driverId'];

      if (driverId == null) {
        throw Exception('Driver ID not found in ride data');
      }

      // Create report
      final report = {
        'reporterId': userId,
        'reportedUserId': driverId,
        'rideId': rideId,
        'issues': issues,
        'details': details,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(Constants.reportsCollection).add(report);

      Get.snackbar(
        'Report Submitted',
        'Thank you for your report. We will review it shortly.',
        snackPosition: SnackPosition.BOTTOM,
      );

      DevLogs.info('Driver reported successfully');
    } catch (e) {
      DevLogs.error('Error reporting driver', exception: e);
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
    DevLogs.debug('Fetching ride history');

    try {
      final String userId = _authService.firebaseUser.value!.uid;

      final QuerySnapshot snapshot = await _firestore
          .collection(Constants.ridesCollection)
          .where('riderId', isEqualTo: userId)
          .where('status', whereIn: [Constants.completed, Constants.cancelled])
          .orderBy('createdAt', descending: true)
          .get();

      final List<RideModel> rides = snapshot.docs
          .map((doc) => RideModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      rideHistory.value = rides;
      DevLogs.debug('Fetched ${rides.length} rides');
      return rides;
    } catch (e) {
      DevLogs.error('Error fetching ride history', exception: e);
      return [];
    } finally {
      isLoadingRideHistory.value = false;
    }
  }

  void _updateRideMarkers() async {
    if (pickupLocation.value != null) {
      await _updateLocationMarker(
        'pickup_location',
        pickupLocation.value!.latLng,
        'assets/images/pickup_marker.png',
      );
    }

    if (dropoffLocation.value != null) {
      await _updateLocationMarker(
        'dropoff_location',
        dropoffLocation.value!.latLng,
        'assets/images/dropoff_marker.png',
      );
    }
  }

  void callDriver() {
    if (driverInfo.value == null) return;

    final phone = driverInfo.value!['user'].phoneNumber;
    if (phone != null && phone.isNotEmpty) {
      // Launch phone call
      _safetyService.makePhoneCall(phone);
      DevLogs.info('Calling driver: $phone');
    } else {
      Get.snackbar(
        'Error',
        'Driver phone number not available',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void messageDriver() {
    if (currentRide.value == null || driverInfo.value == null) return;

    // Navigate to chat screen
    Get.toNamed('/chat/${currentRide.value!.id}');
    DevLogs.info('Opening chat with driver');
  }

  void showReceipt() {
    if (currentRide.value == null) return;

    // Navigate to receipt screen
    Get.toNamed('/rider/receipt/${currentRide.value!.id}');
    DevLogs.info('Showing receipt for ride: ${currentRide.value!.id}');
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

    DevLogs.debug('Ride reset');
  }

  void setNavIndex(int index) {
    selectedNavIndex.value = index;
    DevLogs.debug('Navigation index set to: $index');
  }

  Future<void> getCurrentLocation() async {
    DevLogs.debug('Getting current location for pickup');
    try {
      if (currentLocation.value.latitude == 0) {
        // Wait for location to be available
        await Future.delayed(const Duration(seconds: 2));
      }

      if (currentLocation.value.latitude != 0) {
        // Reverse geocode to get address
        final location = await _locationService.reverseGeocode(currentLocation.value);

        // Set as pickup location
        await setPickupLocation(location);

        DevLogs.debug('Current location set as pickup: ${location.address}');
      } else {
        Get.snackbar(
          'Error',
          'Unable to get your current location. Please check your location settings.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      DevLogs.error('Error getting current location', exception: e);
      Get.snackbar(
        'Error',
        'Failed to get your current location. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void toggleThemeMode() {
    if (themeMode.value == ThemeMode.light) {
      themeMode.value = ThemeMode.dark;
    } else {
      themeMode.value = ThemeMode.light;
    }

    DevLogs.debug('Theme mode toggled to: ${themeMode.value}');
  }

  // Ride start confirmation methods
  Future<void> confirmRideStart() async {
    if (currentRide.value == null || !isWaitingForRideStart.value) return;

    try {
      hasRiderConfirmedStart.value = true;

      // Update ride in Firestore
      await _firestore.collection(Constants.ridesCollection).doc(currentRide.value!.id).update({
        'riderConfirmedStart': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If both rider and driver have confirmed, start the ride
      if (hasDriverConfirmedStart.value) {
        await _firestore.collection(Constants.ridesCollection).doc(currentRide.value!.id).update({
          'status': Constants.started,
          'startedAt': FieldValue.serverTimestamp(),
        });

        // Update local state
        isWaitingForRideStart.value = false;
        isRideInProgress.value = true;
        rideStatus.value = Constants.started;

        Get.snackbar(
          'Ride Started',
          'Your ride has started. Enjoy your trip!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Start Confirmed',
          'Waiting for driver to start the ride',
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      DevLogs.debug('Rider confirmed ride start');
    } catch (e) {
      DevLogs.error('Error confirming ride start', exception: e);
      Get.snackbar(
        'Error',
        'Failed to confirm ride start. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

extension RiderControllerExtension on RiderController {
  // Method to search places
  Future<List<LocationModel>> searchPlaces(String query) async {
    isSearching.value = true;
    searchQuery.value = query;

    try {
      // Get current location for better results
      final location = currentLocation.value.latitude != 0 ? currentLocation.value : null;

      // Search places using location service
      final results = await _locationService.searchPlaces(query, location);

      // Save search query to recent searches
      await _saveRecentSearch(query);

      DevLogs.debug('Found ${results.length} places for query: $query');
      return results;
    } catch (e) {
      DevLogs.error('Error searching places', exception: e);
      return [];
    } finally {
      isSearching.value = false;
    }
  }

  // Method to reverse geocode a location from map tap
  Future<LocationModel> reverseGeocode(LatLng position) async {
    try {
      final location = await _locationService.reverseGeocode(position);
      DevLogs.debug('Reverse geocoded location: ${location.name}');
      return location;
    } catch (e) {
      DevLogs.error('Error reverse geocoding', exception: e);
      throw Exception('Failed to get location details');
    }
  }

  // Method to update a saved location
  Future<void> updateLocation(Map<String, dynamic> location) async {
    try {
      // Check if location has an ID
      if (location['id'] == null) {
        throw Exception('Location ID is required for update');
      }

      // Find the location in the saved locations
      final index = savedLocations.indexWhere((loc) => loc.id == location['id']);
      if (index == -1) {
        throw Exception('Location not found');
      }

      // Create updated location model
      final updatedLocation = SavedLocationModel(
        id: location['id'],
        name: location['name'],
        address: location['address'],
        latitude: location['latitude'],
        longitude: location['longitude'],
        type: location['type'],
        updatedAt: DateTime.now(),
      );

      // Update in Firestore
      await _firestore
          .collection(Constants.usersCollection)
          .doc(_authService.firebaseUser.value!.uid)
          .collection(Constants.savedLocationsCollection)
          .doc(updatedLocation.id)
          .update(updatedLocation.toMap());

      // Update in local list
      savedLocations[index] = updatedLocation;
      savedLocations.refresh();

      DevLogs.debug('Location updated: ${updatedLocation.name}');
    } catch (e) {
      DevLogs.error('Error updating location', exception: e);
      throw Exception('Failed to update location: $e');
    }
  }

  // Method to load user profile
  Future<void> loadUserProfile() async {
    if (_authService.firebaseUser.value == null) return;

    try {
      final userId = _authService.firebaseUser.value!.uid;
      final doc = await _firestore.collection(Constants.usersCollection).doc(userId).get();

      if (doc.exists) {
        userProfile.value = UserModel.fromMap(doc.data()!, userId);
        DevLogs.debug('User profile loaded: ${userProfile.value?.fullName}');
      }
    } catch (e) {
      DevLogs.error('Error loading user profile', exception: e);
    }
  }
}
