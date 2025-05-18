import 'dart:async';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:easy_ride/core/services/location_service.dart';
import 'package:easy_ride/core/services/auth_service.dart';
import 'package:easy_ride/core/services/notification_service.dart';
import 'package:easy_ride/core/services/firebase_service.dart';
import 'package:easy_ride/core/utils/logs.dart';
import 'package:easy_ride/core/values/constants.dart';
import 'package:easy_ride/models/location_model.dart';
import 'package:easy_ride/models/hire_vehicle_model.dart';
import 'package:easy_ride/models/vehicle_hire_model.dart';

class VehicleHireController extends GetxController {
  final LocationService _locationService = Get.find<LocationService>();
  final AuthService _authService = Get.find<AuthService>();
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final NotificationService _notificationService = Get.find<NotificationService>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Map controller
  Rx<GoogleMapController?> mapController = Rx<GoogleMapController?>(null);

  // User location
  final Rx<LatLng> currentLocation = Rx<LatLng>(const LatLng(0, 0));

  // Map state
  final RxDouble mapZoom = 15.0.obs;
  final RxBool isMapLoading = true.obs;

  // Available vehicles
  final RxList<HireVehicleModel> availableVehicles = <HireVehicleModel>[].obs;
  final RxBool isLoadingVehicles = false.obs;
  final Rx<HireVehicleModel?> selectedVehicle = Rx<HireVehicleModel?>(null);

  // Hire request state
  final RxBool isRequestingHire = false.obs;
  final Rx<VehicleHireModel?> currentHire = Rx<VehicleHireModel?>(null);
  final RxBool isHireActive = false.obs;

  // Pickup and stops locations
  final Rx<LocationModel?> pickupLocation = Rx<LocationModel?>(null);
  final RxList<LocationModel> stops = <LocationModel>[].obs;
  final RxBool returnToOrigin = false.obs;

  // Hire options
  final Rx<HireVehicleType> selectedVehicleType = HireVehicleType.car.obs;
  final Rx<HireDurationType> selectedDurationType = HireDurationType.hourly.obs;
  final Rx<HirePurpose> selectedPurpose = HirePurpose.errands.obs;
  final RxString purposeDescription = ''.obs;
  final RxString selectedPaymentMethod = 'card'.obs;
  final RxBool selfDriveSelected = false.obs;

  // Date and time selection
  final Rx<DateTime> selectedStartDate = DateTime.now().obs;
  final Rx<TimeOfDay> selectedStartTime = TimeOfDay.now().obs;
  final Rx<DateTime> selectedEndDate = DateTime.now().add(const Duration(hours: 3)).obs;
  final Rx<TimeOfDay> selectedEndTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 3))).obs;

  // Recurring options
  final RxBool isRecurring = false.obs;
  final RxString recurringPattern = ''.obs;
  final RxInt recurringCount = 0.obs;
  final Rx<DateTime?> recurringEndDate = Rx<DateTime?>(null);

  // Cost calculation
  final RxDouble estimatedCost = 0.0.obs;
  final RxBool isCalculatingCost = false.obs;

  // Map markers and polylines
  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxSet<Polyline> polylines = <Polyline>{}.obs;

  // Vehicle tracking
  final Rx<LatLng?> vehicleLocation = Rx<LatLng?>(null);
  StreamSubscription? _vehicleLocationSubscription;

  // Hire history
  final RxList<VehicleHireModel> hireHistory = <VehicleHireModel>[].obs;
  final RxBool isLoadingHireHistory = false.obs;

  // UI state
  final RxInt currentStep = 0.obs;
  final RxBool showVehicleDetails = false.obs;
  final RxBool showHireDetails = false.obs;

  // Streams
  StreamSubscription? _locationSubscription;
  StreamSubscription? _hireSubscription;

  // Loading
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    DevLogs.info('VehicleHireController initialized');
    _initLocationTracking();
    _checkForActiveHire();
  }

  @override
  void onClose() {
    _locationSubscription?.cancel();
    _hireSubscription?.cancel();
    _vehicleLocationSubscription?.cancel();
    mapController.value?.dispose();
    DevLogs.info('VehicleHireController disposed');
    super.onClose();
  }

  void _initLocationTracking() {
    DevLogs.debug('Initializing location tracking in VehicleHireController');

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
        DevLogs.debug('Location updated in VehicleHireController: ${position.latitude}, ${position.longitude}');
      }
    });
  }

  void onMapCreated(GoogleMapController controller) {
    mapController.value = controller;
    isMapLoading.value = false;

    // Center map on user location if available
    if (currentLocation.value.latitude != 0) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation.value, mapZoom.value),
      );
      DevLogs.info('Map centered on user location during creation');
    }
  }

  Future<void> _checkForActiveHire() async {
    if (_authService.firebaseUser.value == null) return;

    DevLogs.debug('Checking for active hire');
    try {
      final userId = _authService.firebaseUser.value!.uid;
      final snapshot = await _firestore
          .collection('vehicleHires')
          .where('riderId', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'approved', 'active'])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final hireData = snapshot.docs.first.data();
        final hire = VehicleHireModel.fromMap(hireData, snapshot.docs.first.id);

        currentHire.value = hire;
        isHireActive.value = hire.status == HireStatus.active;

        // Start listening for hire updates
        _listenForHireUpdates(hire.id);

        // If hire is active, start tracking the vehicle
        if (hire.status == HireStatus.active) {
          _startVehicleTracking(hire.vehicleId);
        }

        DevLogs.info('Active hire found: ${hire.id}');
      } else {
        DevLogs.debug('No active hire found');
      }
    } catch (e) {
      DevLogs.error('Error checking for active hire', exception: e);
    }
  }

  void _listenForHireUpdates(String hireId) {
    _hireSubscription?.cancel();

    DevLogs.debug('Starting to listen for hire updates: $hireId');
    _hireSubscription = _firestore
        .collection('vehicleHires')
        .doc(hireId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final hireData = snapshot.data()!;
        final hire = VehicleHireModel.fromMap(hireData, snapshot.id);

        currentHire.value = hire;
        isHireActive.value = hire.status == HireStatus.active;

        // If hire becomes active, start tracking the vehicle
        if (hire.status == HireStatus.active && vehicleLocation.value == null) {
          _startVehicleTracking(hire.vehicleId);
        }

        // If hire is completed or cancelled, stop tracking
        if (hire.status == HireStatus.completed || hire.status == HireStatus.cancelled) {
          _stopVehicleTracking();
          _hireSubscription?.cancel();
        }

        DevLogs.debug('Hire update received: ${hire.status}');
      }
    });
  }

  void _startVehicleTracking(String vehicleId) {
    _vehicleLocationSubscription?.cancel();

    DevLogs.debug('Starting to track vehicle: $vehicleId');
    _vehicleLocationSubscription = _database
        .ref('vehicleLocations/$vehicleId')
        .onValue
        .listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        
        if (data['latitude'] != null && data['longitude'] != null) {
          final lat = (data['latitude'] as num).toDouble();
          final lng = (data['longitude'] as num).toDouble();
          vehicleLocation.value = LatLng(lat, lng);
          
          // Update vehicle marker on map
          _updateVehicleMarker();
          
          DevLogs.debug('Vehicle location updated: $lat, $lng');
        }
      }
    });
  }

  void _stopVehicleTracking() {
    _vehicleLocationSubscription?.cancel();
    vehicleLocation.value = null;
    DevLogs.debug('Vehicle tracking stopped');
  }

  Future<void> _updateVehicleMarker() async {
    if (vehicleLocation.value == null) return;

    try {
      final marker = Marker(
        markerId: const MarkerId('hired_vehicle'),
        position: vehicleLocation.value!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Hired Vehicle'),
        zIndex: 2,
      );

      final updatedMarkers = {...markers};
      updatedMarkers.removeWhere((m) => m.markerId.value == 'hired_vehicle');
      updatedMarkers.add(marker);
      markers.value = updatedMarkers;

      // Center map on vehicle if tracking is active
      if (mapController.value != null && isHireActive.value) {
        mapController.value!.animateCamera(
          CameraUpdate.newLatLng(vehicleLocation.value!),
        );
      }
    } catch (e) {
      DevLogs.error('Error updating vehicle marker', exception: e);
    }
  }

  Future<void> fetchAvailableVehicles() async {
    isLoadingVehicles.value = true;
    DevLogs.debug('Fetching available vehicles');

    try {
      final snapshot = await _firestore
          .collection('hireVehicles')
          .where('status', isEqualTo: 'available')
          .get();

      final vehicles = snapshot.docs
          .map((doc) => HireVehicleModel.fromJson(doc.data()))
          .toList();

      // Filter by selected vehicle type if specified
      if (selectedVehicleType.value != HireVehicleType.car) {
        vehicles.removeWhere((v) => v.hireType != selectedVehicleType.value);
      }

      availableVehicles.value = vehicles;
      DevLogs.debug('Fetched ${vehicles.length} available vehicles');
    } catch (e) {
      DevLogs.error('Error fetching available vehicles', exception: e);
      Get.snackbar(
        'Error',
        'Failed to load available vehicles. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingVehicles.value = false;
    }
  }

  void selectVehicle(HireVehicleModel vehicle) {
    selectedVehicle.value = vehicle;
    showVehicleDetails.value = true;
    calculateEstimatedCost();
    DevLogs.debug('Vehicle selected: ${vehicle.id}');
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
        setPickupLocation(location);

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

  void setPickupLocation(LocationModel location) {
    pickupLocation.value = location;
    _updateLocationMarker('pickup_location', location.latLng);
    DevLogs.debug('Pickup location set: ${location.name}');
  }

  void addStop(LocationModel location) {
    stops.add(location);
    _updateLocationMarker('stop_${stops.length}', location.latLng);
    DevLogs.debug('Stop added: ${location.name}');
  }

  void removeStop(int index) {
    if (index >= 0 && index < stops.length) {
      final removedStop = stops.removeAt(index);
      
      // Remove marker
      final markerId = 'stop_${index + 1}';
      final updatedMarkers = {...markers};
      updatedMarkers.removeWhere((m) => m.markerId.value == markerId);
      markers.value = updatedMarkers;
      
      // Renumber remaining stop markers
      for (int i = index; i < stops.length; i++) {
        final oldMarkerId = 'stop_${i + 2}';
        final newMarkerId = 'stop_${i + 1}';
        
        final marker = updatedMarkers.firstWhere(
          (m) => m.markerId.value == oldMarkerId,
          orElse: () => Marker(markerId: const MarkerId('not_found')),
        );
        
        if (marker.markerId.value != 'not_found') {
          updatedMarkers.remove(marker);
          updatedMarkers.add(Marker(
            markerId: MarkerId(newMarkerId),
            position: marker.position,
            icon: marker.icon,
            infoWindow: InfoWindow(title: 'Stop ${i + 1}'),
          ));
        }
      }
      
      markers.value = updatedMarkers;
      DevLogs.debug('Stop removed: ${removedStop.name}');
    }
  }

  void _updateLocationMarker(String id, LatLng position) {
    try {
      final marker = Marker(
        markerId: MarkerId(id),
        position: position,
        icon: id == 'pickup_location'
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: id == 'pickup_location' ? 'Pickup Location' : 'Stop ${id.split('_').last}',
        ),
      );

      final updatedMarkers = {...markers};
      updatedMarkers.removeWhere((m) => m.markerId.value == id);
      updatedMarkers.add(marker);
      markers.value = updatedMarkers;

      // Center map to show all markers
      _fitMapToMarkers();
    } catch (e) {
      DevLogs.error('Error updating location marker', exception: e);
    }
  }

  void _fitMapToMarkers() {
    if (mapController.value == null) return;

    // Get all marker positions
    final positions = markers.map((m) => m.position).toList();

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

  void setVehicleType(HireVehicleType type) {
    selectedVehicleType.value = type;
    // Refresh available vehicles based on new type
    fetchAvailableVehicles();
    DevLogs.debug('Vehicle type set: $type');
  }

  void setDurationType(HireDurationType type) {
    selectedDurationType.value = type;
    calculateEstimatedCost();
    DevLogs.debug('Duration type set: $type');
  }

  void setPurpose(HirePurpose purpose) {
    selectedPurpose.value = purpose;
    DevLogs.debug('Purpose set: $purpose');
  }

  void setSelfDrive(bool value) {
    selfDriveSelected.value = value;
    DevLogs.debug('Self drive set: $value');
  }

  void setReturnToOrigin(bool value) {
    returnToOrigin.value = value;
    DevLogs.debug('Return to origin set: $value');
  }

  void setStartDateTime(DateTime date, TimeOfDay time) {
    final newDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    
    selectedStartDate.value = date;
    selectedStartTime.value = time;
    
    // Ensure end time is after start time
    if (getEndDateTime().isBefore(newDateTime)) {
      // Set end time to 3 hours after start time for hourly, or 1 day for daily
      if (selectedDurationType.value == HireDurationType.hourly) {
        final newEndTime = newDateTime.add(const Duration(hours: 3));
        selectedEndDate.value = newEndTime;
        selectedEndTime.value = TimeOfDay.fromDateTime(newEndTime);
      } else {
        final newEndTime = newDateTime.add(const Duration(days: 1));
        selectedEndDate.value = newEndTime;
        selectedEndTime.value = TimeOfDay.fromDateTime(newEndTime);
      }
    }
    
    calculateEstimatedCost();
    DevLogs.debug('Start date/time set: ${getStartDateTime()}');
  }

  void setEndDateTime(DateTime date, TimeOfDay time) {
    selectedEndDate.value = date;
    selectedEndTime.value = time;
    calculateEstimatedCost();
    DevLogs.debug('End date/time set: ${getEndDateTime()}');
  }

  DateTime getStartDateTime() {
    return DateTime(
      selectedStartDate.value.year,
      selectedStartDate.value.month,
      selectedStartDate.value.day,
      selectedStartTime.value.hour,
      selectedStartTime.value.minute,
    );
  }

  DateTime getEndDateTime() {
    return DateTime(
      selectedEndDate.value.year,
      selectedEndDate.value.month,
      selectedEndDate.value.day,
      selectedEndTime.value.hour,
      selectedEndTime.value.minute,
    );
  }

  void setRecurring(bool value) {
    isRecurring.value = value;
    DevLogs.debug('Recurring set: $value');
  }

  void setRecurringPattern(String pattern) {
    recurringPattern.value = pattern;
    DevLogs.debug('Recurring pattern set: $pattern');
  }

  void setRecurringCount(int count) {
    recurringCount.value = count;
    DevLogs.debug('Recurring count set: $count');
  }

  void setRecurringEndDate(DateTime? date) {
    recurringEndDate.value = date;
    DevLogs.debug('Recurring end date set: $date');
  }

  void calculateEstimatedCost() {
    if (selectedVehicle.value == null) return;

    isCalculatingCost.value = true;
    DevLogs.debug('Calculating estimated cost');

    try {
      final vehicle = selectedVehicle.value!;
      final startTime = getStartDateTime();
      final endTime = getEndDateTime();
      
      double cost = 0.0;
      
      if (selectedDurationType.value == HireDurationType.hourly) {
        // Calculate hours (rounded up to nearest 0.5)
        final durationHours = endTime.difference(startTime).inMinutes / 60;
        final roundedHours = (durationHours * 2).ceil() / 2; // Round up to nearest 0.5
        cost = roundedHours * vehicle.hourlyRate;
      } else {
        // Calculate days (including partial days)
        final durationDays = endTime.difference(startTime).inHours / 24;
        final roundedDays = durationDays.ceil(); // Round up to full days
        cost = roundedDays * vehicle.dailyRate;
      }
      
      // Add extra for stops
      cost += stops.length * 5.0; // $5 per additional stop
      
      // Add extra for return to origin
      if (returnToOrigin.value) {
        cost += 10.0; // $10 for return to origin
      }
      
      estimatedCost.value = cost;
      DevLogs.debug('Estimated cost: \$${cost.toStringAsFixed(2)}');
    } catch (e) {
      DevLogs.error('Error calculating estimated cost', exception: e);
    } finally {
      isCalculatingCost.value = false;
    }
  }

  Future<void> requestHire() async {
    if (selectedVehicle.value == null || pickupLocation.value == null) {
      Get.snackbar(
        'Error',
        'Please select a vehicle and pickup location',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_authService.firebaseUser.value == null) {
      Get.snackbar(
        'Error',
        'You need to be logged in to request a hire',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isRequestingHire.value = true;
    DevLogs.info('Requesting vehicle hire');

    try {
      final userId = _authService.firebaseUser.value!.uid;
      final hireId = const Uuid().v4();
      
      // Create hire request
      final hire = VehicleHireModel(
        id: hireId,
        riderId: userId,
        vehicleId: selectedVehicle.value!.id,
        status: HireStatus.pending,
        durationType: selectedDurationType.value,
        purpose: selectedPurpose.value,
        purposeDescription: purposeDescription.value,
        startTime: getStartDateTime(),
        endTime: getEndDateTime(),
        pickupLocation: pickupLocation.value!,
        stops: stops,
        returnToOrigin: returnToOrigin.value,
        selfDrive: selfDriveSelected.value,
        totalCost: estimatedCost.value,
        paymentMethod: selectedPaymentMethod.value,
        createdAt: DateTime.now(),
        isRecurring: isRecurring.value,
        recurringPattern: isRecurring.value ? recurringPattern.value : null,
        recurringCount: isRecurring.value ? recurringCount.value : null,
        recurringEndDate: isRecurring.value ? recurringEndDate.value : null,
      );
      
      // Save to Firestore
      await _firestore.collection('vehicleHires').doc(hireId).set(hire.toMap());
      
      // Update current hire
      currentHire.value = hire;
      
      // Start listening for updates
      _listenForHireUpdates(hireId);
      
      // Send notification to admin
      await _notificationService.sendPushNotification(
        'admins',
        'New Vehicle Hire Request',
        'A new vehicle hire request has been submitted',
        {
          'type': 'vehicle_hire_request',
          'hireId': hireId,
        },
      );
      
      Get.snackbar(
        'Request Submitted',
        'Your vehicle hire request has been submitted and is pending approval',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      
      // Navigate to hire details screen
      Get.toNamed('/vehicle-hire-details/$hireId');
      
      DevLogs.info('Vehicle hire requested successfully: $hireId');
    } catch (e) {
      DevLogs.error('Error requesting vehicle hire', exception: e);
      Get.snackbar(
        'Error',
        'Failed to submit hire request. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isRequestingHire.value = false;
    }
  }

  Future<void> cancelHire() async {
    if (currentHire.value == null) return;

    DevLogs.info('Cancelling hire: ${currentHire.value!.id}');
    try {
      await _firestore.collection('vehicleHires').doc(currentHire.value!.id).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancellationReason': 'Cancelled by rider',
      });

      // Stop tracking if active
      if (isHireActive.value) {
        _stopVehicleTracking();
      }

      // Reset state
      currentHire.value = null;
      isHireActive.value = false;

      Get.snackbar(
        'Hire Cancelled',
        'Your vehicle hire has been cancelled',
        snackPosition: SnackPosition.BOTTOM,
      );

      DevLogs.info('Hire cancelled successfully');
    } catch (e) {
      DevLogs.error('Error cancelling hire', exception: e);
      Get.snackbar(
        'Error',
        'Failed to cancel hire. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> rateHire(String hireId, double rating, String feedback) async {
    DevLogs.info('Rating hire: $hireId');
    isLoading.value = true;

    try {
      await _firestore.collection('vehicleHires').doc(hireId).update({
        'rating': rating,
        'feedback': feedback,
        'ratedAt': FieldValue.serverTimestamp(),
      });

      // Update vehicle rating
      final hire = await _firestore.collection('vehicleHires').doc(hireId).get();
      if (hire.exists) {
        final vehicleId = hire.data()?['vehicleId'];
        if (vehicleId != null) {
          await _updateVehicleRating(vehicleId, rating);
        }
      }

      Get.snackbar(
        'Rating Submitted',
        'Thank you for your feedback',
        snackPosition: SnackPosition.BOTTOM,
      );

      DevLogs.info('Hire rated successfully');
    } catch (e) {
      DevLogs.error('Error rating hire', exception: e);
      Get.snackbar(
        'Error',
        'Failed to submit rating. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _updateVehicleRating(String vehicleId, double newRating) async {
    try {
      // Get vehicle document
      final vehicleDoc = await _firestore.collection('hireVehicles').doc(vehicleId).get();

      if (vehicleDoc.exists) {
        final data = vehicleDoc.data()!;
        final currentRating = data['rating'] ?? 0.0;
        final ratingCount = data['ratingCount'] ?? 0;

        // Calculate new average rating
        final newAvgRating = ((currentRating * ratingCount) + newRating) / (ratingCount + 1);

        // Update vehicle document
        await _firestore.collection('hireVehicles').doc(vehicleId).update({
          'rating': newAvgRating,
          'ratingCount': ratingCount + 1,
        });

        DevLogs.debug('Vehicle rating updated: $newAvgRating (${ratingCount + 1} ratings)');
      }
    } catch (e) {
      DevLogs.error('Error updating vehicle rating', exception: e);
    }
  }

  Future<void> fetchHireHistory() async {
    if (_authService.firebaseUser.value == null) return;

    isLoadingHireHistory.value = true;
    DevLogs.debug('Fetching hire history');

    try {
      final String userId = _authService.firebaseUser.value!.uid;

      final QuerySnapshot snapshot = await _firestore
          .collection('vehicleHires')
          .where('riderId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final List<VehicleHireModel> hires = snapshot.docs
          .map((doc) => VehicleHireModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      hireHistory.value = hires;
      DevLogs.debug('Fetched ${hires.length} hires');
    } catch (e) {
      DevLogs.error('Error fetching hire history', exception: e);
      Get.snackbar(
        'Error',
        'Failed to load hire history. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingHireHistory.value = false;
    }
  }

  Future<VehicleHireModel?> getHireDetails(String hireId) async {
    DevLogs.debug('Getting hire details: $hireId');
    try {
      final doc = await _firestore.collection('vehicleHires').doc(hireId).get();

      if (doc.exists) {
        return VehicleHireModel.fromMap(doc.data()!, doc.id);
      }

      return null;
    } catch (e) {
      DevLogs.error('Error getting hire details', exception: e);
      return null;
    }
  }

  Future<HireVehicleModel?> getVehicleDetails(String vehicleId) async {
    DevLogs.debug('Getting vehicle details: $vehicleId');
    try {
      final doc = await _firestore.collection('hireVehicles').doc(vehicleId).get();

      if (doc.exists) {
        return HireVehicleModel.fromJson(doc.data()!);
      }

      return null;
    } catch (e) {
      DevLogs.error('Error getting vehicle details', exception: e);
      return null;
    }
  }

  void resetHire() {
    // Reset all hire-related state
    selectedVehicle.value = null;
    pickupLocation.value = null;
    stops.clear();
    returnToOrigin.value = false;
    selfDriveSelected.value = false;
    purposeDescription.value = '';
    selectedStartDate.value = DateTime.now();
    selectedStartTime.value = TimeOfDay.now();
    selectedEndDate.value = DateTime.now().add(const Duration(hours: 3));
    selectedEndTime.value = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 3)));
    isRecurring.value = false;
    recurringPattern.value = '';
    recurringCount.value = 0;
    recurringEndDate.value = null;
    estimatedCost.value = 0.0;
    
    // Reset UI state
    currentStep.value = 0;
    showVehicleDetails.value = false;
    showHireDetails.value = false;
    
    // Clear map
    markers.clear();
    polylines.clear();
    
    DevLogs.debug('Hire state reset');
  }
}
