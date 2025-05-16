import 'dart:math';

import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:easy_ride/core/services/auth_service.dart';
import 'package:easy_ride/core/services/location_service.dart';
import 'package:easy_ride/core/services/firebase_service.dart';
import 'package:easy_ride/models/ride_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_ride/routes/app_pages.dart';

class DriverController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final LocationService _locationService = Get.find<LocationService>();
  final FirebaseService firebaseService = Get.find<FirebaseService>();
  
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
  
  // Ride related
  final Rx<RideModel?> currentRide = Rx<RideModel?>(null);
  final RxList<RideModel> rideRequests = <RideModel>[].obs;
  final RxList<RideModel> rideHistory = <RideModel>[].obs;
  
  // Earnings
  final RxDouble todayEarnings = 0.0.obs;
  final RxDouble weeklyEarnings = 0.0.obs;
  final RxDouble totalEarnings = 0.0.obs;
  final RxInt completedRides = 0.obs;
  
  @override
  void onInit() {
    super.onInit();
    _initializeLocation();
    _listenToRideRequests();
    _listenToCurrentRide();
    _fetchRideHistory();
    _calculateEarnings();
  }
  
  @override
  void onClose() {
    mapController.value?.dispose();
    super.onClose();
  }
  
  Future<void> _initializeLocation() async {
    await _locationService.init();
    
    // Set initial camera position to current location
    ever(_locationService.currentLocation, (locationData) {
      if (locationData != null && mapController.value != null) {
        final LatLng currentLatLng = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );
        
        initialCameraPosition.value = CameraPosition(
          target: currentLatLng,
          zoom: 15,
        );
        
        mapController.value!.animateCamera(
          CameraUpdate.newCameraPosition(initialCameraPosition.value),
        );
        
        // Add marker for current location
        _updateCurrentLocationMarker(currentLatLng);
      }
    });
  }
  
  void _updateCurrentLocationMarker(LatLng position) {
    markers.removeWhere((marker) => marker.markerId.value == 'current_location');
    
    markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );
  }
  
  Future<void> toggleOnlineStatus() async {
    isLoading.value = true;
    
    try {
      isOnline.value = !isOnline.value;
      
      if (isOnline.value) {
        // Go online
        await _locationService.startLocationUpdates();
      } else {
        // Go offline
        await _locationService.setDriverOffline();
        await _locationService.stopLocationUpdates();
      }
    } catch (e) {
      print('Error toggling online status: $e');
      error.value = 'Failed to update status';
    } finally {
      isLoading.value = false;
    }
  }
  
  void _listenToRideRequests() {
    if (_authService.firebaseUser.value == null) return;
    
    // Listen for pending ride requests
    firebaseService.collectionStream<RideModel>(
      path: 'rides',
      queryBuilder: (query) => query
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true),
      builder: (data, documentId) => RideModel.fromMap(data, documentId),
    ).listen((rides) {
      rideRequests.value = rides;
    });
  }
  
  void _listenToCurrentRide() {
    if (_authService.firebaseUser.value == null) return;
    
    final String driverId = _authService.firebaseUser.value!.uid;
    
    // Listen for active rides assigned to this driver
    firebaseService.collectionStream<RideModel>(
      path: 'rides',
      queryBuilder: (query) => query
          .where('driverId', isEqualTo: driverId)
          .where('status', whereIn: ['accepted', 'arrived', 'started'])
          .orderBy('createdAt', descending: true)
          .limit(1),
      builder: (data, documentId) => RideModel.fromMap(data, documentId),
    ).listen((rides) {
      if (rides.isNotEmpty) {
        currentRide.value = rides.first;
        _updateRideMapView(rides.first);
      } else {
        currentRide.value = null;
      }
    });
  }
  
  Future<void> _fetchRideHistory() async {
    if (_authService.firebaseUser.value == null) return;
    
    final String driverId = _authService.firebaseUser.value!.uid;
    
    try {
      final QuerySnapshot snapshot = await firebaseService.collection('rides')
          .where('driverId', isEqualTo: driverId)
          .where('status', whereIn: ['completed', 'cancelled'])
          .orderBy('createdAt', descending: true)
          .get();
      
      final List<RideModel> rides = snapshot.docs
          .map((doc) => RideModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      rideHistory.value = rides;
    } catch (e) {
      print('Error fetching ride history: $e');
    }
  }
  
  Future<void> _calculateEarnings() async {
    if (_authService.firebaseUser.value == null) return;
    
    final String driverId = _authService.firebaseUser.value!.uid;
    
    try {
      // Get completed rides
      final QuerySnapshot snapshot = await firebaseService.collection('rides')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'completed')
          .get();
      
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
    } catch (e) {
      print('Error calculating earnings: $e');
    }
  }
  
  void _updateRideMapView(RideModel ride) {
    if (ride.pickup.isEmpty || ride.dropoff.isEmpty) return;
    
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
    final LatLng pickupLatLng = LatLng(
      ride.pickup['location']['lat'],
      ride.pickup['location']['lng'],
    );
    
    markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: pickupLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Pickup', snippet: ride.pickup['name']),
      ),
    );
    
    // Add dropoff marker
    final LatLng dropoffLatLng = LatLng(
      ride.dropoff['location']['lat'],
      ride.dropoff['location']['lng'],
    );
    
    markers.add(
      Marker(
        markerId: const MarkerId('dropoff'),
        position: dropoffLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(title: 'Dropoff', snippet: ride.dropoff['name']),
      ),
    );
    
    // Add polyline
    polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: [pickupLatLng, dropoffLatLng],
        color: Colors.blue,
        width: 5,
      ),
    );
    
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
  }
  
  Future<void> acceptRide(String rideId) async {
    isLoading.value = true;
    
    try {
      final String driverId = _authService.firebaseUser.value!.uid;
      
      await firebaseService.updateData(
        path: 'rides/$rideId',
        data: {
          'driverId': driverId,
          'status': 'accepted',
          'acceptedAt': FieldValue.serverTimestamp(),
        },
      );
      
      Get.offAllNamed(Routes.driverRideDetails, arguments: rideId);
    } catch (e) {
      print('Error accepting ride: $e');
      error.value = 'Failed to accept ride';
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> updateRideStatus(String rideId, String status) async {
    isLoading.value = true;
    
    try {
      Map<String, dynamic> updateData = {
        'status': status,
      };
      
      switch (status) {
        case 'arrived':
          updateData['arrivedAt'] = FieldValue.serverTimestamp();
          break;
        case 'started':
          updateData['startedAt'] = FieldValue.serverTimestamp();
          break;
        case 'completed':
          updateData['completedAt'] = FieldValue.serverTimestamp();
          updateData['isPaid'] = true; // Assuming cash payment is completed
          break;
      }
      
      await firebaseService.updateData(
        path: 'rides/$rideId',
        data: updateData,
      );
      
      if (status == 'completed') {
        await _calculateEarnings();
        Get.offAllNamed(Routes.driverHome);
      }
    } catch (e) {
      print('Error updating ride status: $e');
      error.value = 'Failed to update ride status';
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> rateRider(String rideId, double rating, String feedback) async {
    isLoading.value = true;
    
    try {
      await firebaseService.updateData(
        path: 'rides/$rideId',
        data: {
          'riderRating': rating,
          'riderFeedback': feedback,
        },
      );
      
      Get.back();
      Get.snackbar(
        'Thank You',
        'Your rating has been submitted',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error rating rider: $e');
      error.value = 'Failed to submit rating';
    } finally {
      isLoading.value = false;
    }
  }
}
