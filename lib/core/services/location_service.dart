import 'dart:async';
import 'package:easy_ride/core/values/constants.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_ride/core/services/auth_service.dart';
import 'package:easy_ride/models/location_model.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:math' show pi, sqrt, atan2, sin, cos;
import 'package:easy_ride/core/utils/logs.dart';
import 'package:easy_ride/core/services/api_service.dart';

class LocationService extends GetxService {
  final Location _location = Location();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = Get.find<AuthService>();
  late final ApiService _apiService;

  Rx<LocationData?> currentLocation = Rx<LocationData?>(null);
  StreamSubscription<LocationData>? _locationSubscription;

  // Stream for location updates
  Stream<LocationData> get locationStream => _location.onLocationChanged;

  // Add this map to store location sharing subscriptions
  final Map<String, StreamSubscription<LocationData>> _locationSharingSubscriptions = {};

// Update the init method to ensure location is obtained before returning
  Future<LocationService> init() async {
    _apiService = Get.find<ApiService>();

    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Check if location service is enabled
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        DevLogs.warning('Location services are disabled');
        return this;
      }
    }

    // Check if permission is granted
    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        DevLogs.warning('Location permissions are denied');
        return this;
      }
    }

    // Configure location settings for higher accuracy and more frequent updates
    _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 5000, // 5 seconds
      distanceFilter: 5, // 5 meters
    );

    // Get initial location - wait for it with a timeout
    try {
      DevLogs.info('Getting initial location...');
      currentLocation.value = await _location.getLocation().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          DevLogs.warning('Timeout getting initial location');
          return LocationData.fromMap({
            'latitude': 0.0,
            'longitude': 0.0,
            'accuracy': 0.0,
            'altitude': 0.0,
            'speed': 0.0,
            'speed_accuracy': 0.0,
            'heading': 0.0,
            'time': 0.0,
          });
        },
      );

      if (currentLocation.value?.latitude != null && currentLocation.value?.longitude != null) {
        DevLogs.info('Initial location obtained: ${currentLocation.value?.latitude}, ${currentLocation.value?.longitude}');
      } else {
        DevLogs.warning('Initial location is null or has null coordinates');
      }
    } catch (e) {
      DevLogs.error('Error getting initial location', exception: e);
    }

    // Start location updates immediately
    await startLocationUpdates();

    return this;
  }

// Update startLocationUpdates to be more robust
  Future<void> startLocationUpdates() async {
    if (_locationSubscription != null) {
      await _locationSubscription!.cancel();
    }

    _locationSubscription = _location.onLocationChanged.listen((LocationData locationData) {
      if (locationData.latitude == null || locationData.longitude == null) {
        DevLogs.warning('Received location update with null coordinates');
        return;
      }

      currentLocation.value = locationData;
      DevLogs.debug('Location updated: ${locationData.latitude}, ${locationData.longitude}');

      // If user is a driver and logged in, update location in Firestore
      if (_authService.isDriver && _authService.isLoggedIn) {
        updateDriverLocation(locationData);
      }
    });

    DevLogs.info('Location updates started');
  }

  Future<void> stopLocationUpdates() async {
    if (_locationSubscription != null) {
      await _locationSubscription!.cancel();
      _locationSubscription = null;
      DevLogs.info('Location updates stopped');
    }
  }

  Future<void> updateDriverLocation(LocationData locationData) async {
    if (_authService.firebaseUser.value != null) {
      String driverId = _authService.firebaseUser.value!.uid;

      await _firestore.collection(Constants.driverLocationsCollection).doc(driverId).set({
        'location': GeoPoint(locationData.latitude!, locationData.longitude!),
        'heading': locationData.heading,
        'speed': locationData.speed,
        'accuracy': locationData.accuracy,
        'lastUpdated': FieldValue.serverTimestamp(),
        'isOnline': true,
        'driverId': driverId,
      }, SetOptions(merge: true));

      DevLogs.debug('Driver location updated in Firestore');
    }
  }

  Future<void> setDriverOffline() async {
    if (_authService.firebaseUser.value != null) {
      String driverId = _authService.firebaseUser.value!.uid;

      await _firestore.collection(Constants.driverLocationsCollection).doc(driverId).update({
        'isOnline': false,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      DevLogs.info('Driver set to offline');
    }
  }

  Future<List<LocationModel>> getNearbyDrivers(LatLng location, double radiusInKm) async {
    DevLogs.info('Searching for nearby drivers within $radiusInKm km');

    // Get all online drivers
    QuerySnapshot snapshot = await _firestore.collection(Constants.driverLocationsCollection)
        .where('isOnline', isEqualTo: true)
        .get();

    List<LocationModel> nearbyDrivers = [];

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      GeoPoint driverLocation = data['location'] as GeoPoint;

      // Calculate distance
      double distance = calculateDistance(
        location.latitude,
        location.longitude,
        driverLocation.latitude,
        driverLocation.longitude,
      );

      // Check if driver is within radius
      if (distance <= radiusInKm) {
        // Get driver details
        DocumentSnapshot driverDoc = await _firestore.collection('users').doc(data['driverId']).get();
        String driverName = "Driver";

        if (driverDoc.exists) {
          Map<String, dynamic> driverData = driverDoc.data() as Map<String, dynamic>;
          driverName = driverData['fullName'] ?? "Driver";
        }

        LocationModel driverLocationModel = LocationModel(
          name: driverName,
          address: "Online Driver",
          latitude: driverLocation.latitude,
          longitude: driverLocation.longitude,
          placeId: data['driverId'],
          distance: distance,
        );

        nearbyDrivers.add(driverLocationModel);
      }
    }

    // Sort by distance
    nearbyDrivers.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));

    DevLogs.info('Found ${nearbyDrivers.length} nearby drivers');
    return nearbyDrivers;
  }

  // Haversine formula to calculate distance between two points
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // in kilometers
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = (
        sin(dLat / 2) * sin(dLat / 2) +
            cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
                sin(dLon / 2) * sin(dLon / 2)
    );

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  Future<LocationModel> getPlaceDetails(String placeId) async {
    try {
      final placeDetails = await _apiService.getPlaceDetails(placeId);

      return LocationModel(
        name: placeDetails['name'] ?? '',
        address: placeDetails['formatted_address'] ?? '',
        latitude: placeDetails['geometry']['location']['lat'] ?? 0.0,
        longitude: placeDetails['geometry']['location']['lng'] ?? 0.0,
        placeId: placeId,
      );
    } catch (e) {
      DevLogs.error('Error getting place details', exception: e);
      throw Exception('Failed to get place details: $e');
    }
  }

  Future<List<LocationModel>> searchPlaces(String query, [LatLng? location]) async {
    try {
      final results = await _apiService.searchPlaces(
        query,
        lat: location?.latitude,
        lng: location?.longitude,
      );

      return results.map((place) {
        return LocationModel(
          name: place['name'] ?? '',
          address: place['formatted_address'] ?? '',
          latitude: place['geometry']['location']['lat'] ?? 0.0,
          longitude: place['geometry']['location']['lng'] ?? 0.0,
          placeId: place['place_id'],
        );
      }).toList();
    } catch (e) {
      DevLogs.error('Error searching places', exception: e);
      throw Exception('Failed to search places: $e');
    }
  }

  Future<Map<String, dynamic>> getDirections(LatLng origin, LatLng destination) async {
    try {
      final route = await _apiService.getDirections(
        origin.latitude,
        origin.longitude,
        destination.latitude,
        destination.longitude,
      );

      final leg = route['legs'][0];

      // Extract polyline
      final polylinePoints = PolylinePoints();
      final points = polylinePoints.decodePolyline(route['overview_polyline']['points']);

      final List<LatLng> polylineCoordinates = points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      return {
        'distance': {
          'text': leg['distance']['text'],
          'value': leg['distance']['value'],
        },
        'duration': {
          'text': leg['duration']['text'],
          'value': leg['duration']['value'],
        },
        'polylinePoints': polylineCoordinates,
        'polyline': route['overview_polyline']['points'],
        'bounds': {
          'northeast': {
            'lat': route['bounds']['northeast']['lat'],
            'lng': route['bounds']['northeast']['lng'],
          },
          'southwest': {
            'lat': route['bounds']['southwest']['lat'],
            'lng': route['bounds']['southwest']['lng'],
          },
        },
      };
    } catch (e) {
      DevLogs.error('Error getting directions', exception: e);
      throw Exception('Failed to get directions: $e');
    }
  }

  Future<LocationModel> reverseGeocode(LatLng location) async {
    try {
      final result = await _apiService.reverseGeocode(
        location.latitude,
        location.longitude,
      );

      return LocationModel(
        name: result['address_components'][0]['long_name'] ?? 'Current Location',
        address: result['formatted_address'] ?? '',
        latitude: location.latitude,
        longitude: location.longitude,
        placeId: result['place_id'],
      );
    } catch (e) {
      DevLogs.error('Error reverse geocoding', exception: e);

      // Fallback to a basic location model
      return LocationModel(
        name: 'Current Location',
        address: 'Unknown Address',
        latitude: location.latitude,
        longitude: location.longitude,
      );
    }
  }

  // Add this method to share driver location in real-time
  Future<void> shareDriverLocationInRealTime(String rideId, String driverId) async {
    if (_locationSubscription == null) {
      DevLogs.error('Location subscription is null');
      return;
    }

    DevLogs.debug('Starting real-time location sharing for ride: $rideId');

    // Create a new subscription specifically for sharing location
    final locationSharingSubscription = _location.onLocationChanged.listen((LocationData locationData) async {
      if (locationData.latitude == null || locationData.longitude == null) return;

      try {
        // Update location in the ride document
        await _firestore.collection('rides').doc(rideId).update({
          'driverLocation': GeoPoint(locationData.latitude!, locationData.longitude!),
          'driverHeading': locationData.heading,
          'driverSpeed': locationData.speed,
          'driverLocationUpdatedAt': FieldValue.serverTimestamp(),
        });

        // Also update in a separate collection for better performance
        await _firestore.collection('rideLocations').doc(rideId).set({
          'driverId': driverId,
          'location': GeoPoint(locationData.latitude!, locationData.longitude!),
          'heading': locationData.heading,
          'speed': locationData.speed,
          'accuracy': locationData.accuracy,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        DevLogs.debug('Driver location updated for ride: $rideId');
      } catch (e) {
        DevLogs.error('Error updating driver location for ride', exception: e);
      }
    });

    // Store the subscription in a map to be able to cancel it later
    _locationSharingSubscriptions[rideId] = locationSharingSubscription;
  }

  // Add this method to stop sharing location
  Future<void> stopSharingDriverLocation(String rideId) async {
    final subscription = _locationSharingSubscriptions[rideId];
    if (subscription != null) {
      await subscription.cancel();
      _locationSharingSubscriptions.remove(rideId);
      DevLogs.debug('Stopped sharing driver location for ride: $rideId');
    }
  }

  // Add this method to listen for driver location updates
  Stream<LatLng> listenForDriverLocation(String rideId) {
    return _firestore
        .collection('rideLocations')
        .doc(rideId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        if (data['location'] != null) {
          final GeoPoint location = data['location'];
          return LatLng(location.latitude, location.longitude);
        }
      }
      throw Exception('Driver location not available');
    });
  }
}
