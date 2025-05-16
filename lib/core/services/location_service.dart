import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_ride/core/services/auth_service.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import '../values/constants.dart';

class LocationService extends GetxService {
  final Location _location = Location();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = Get.find<AuthService>();
  final Dio _dio = Dio();

  // Base URLs for Google APIs
  final String _placesApiBaseUrl = 'https://maps.googleapis.com/maps/api/place';
  final String _directionsApiBaseUrl = 'https://maps.googleapis.com/maps/api/directions';

  // Add location stream controller for external components to listen to
  final _locationStreamController = StreamController<LocationData>.broadcast();
  Stream<LocationData> get locationStream => _locationStreamController.stream;

  Rx<LocationData?> currentLocation = Rx<LocationData?>(null);
  StreamSubscription<LocationData>? _locationSubscription;

  Future<LocationService> init() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Configure Dio
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.contentType = Headers.jsonContentType;
    _dio.options.responseType = ResponseType.json;

    // Check if location service is enabled
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return this;
      }
    }

    // Check if permission is granted
    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return this;
      }
    }

    // Configure location settings
    _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 5000, // 5 seconds
      distanceFilter: 5, // 5 meters
    );

    // Get initial location
    try {
      currentLocation.value = await _location.getLocation();
      _locationStreamController.add(currentLocation.value!);
    } catch (e) {
      print('Error getting initial location: $e');
    }

    return this;
  }

  Future<void> startLocationUpdates() async {
    if (_locationSubscription != null) {
      await _locationSubscription!.cancel();
    }

    _locationSubscription = _location.onLocationChanged.listen((LocationData locationData) {
      currentLocation.value = locationData;

      // Add to the stream for external components
      _locationStreamController.add(locationData);

      // If user is a driver and logged in, update location in Firestore
      if (_authService.isDriver && _authService.isLoggedIn) {
        updateDriverLocation(locationData);
      }
    });
  }

  Future<void> stopLocationUpdates() async {
    if (_locationSubscription != null) {
      await _locationSubscription!.cancel();
      _locationSubscription = null;
    }
  }

  Future<void> updateDriverLocation(LocationData locationData) async {
    if (_authService.firebaseUser.value != null) {
      String driverId = _authService.firebaseUser.value!.uid;

      await _firestore.collection('driver_locations').doc(driverId).set({
        'location': GeoPoint(locationData.latitude!, locationData.longitude!),
        'heading': locationData.heading,
        'speed': locationData.speed,
        'accuracy': locationData.accuracy,
        'lastUpdated': FieldValue.serverTimestamp(),
        'isOnline': true,
        'driverId': driverId,
      }, SetOptions(merge: true));
    }
  }

  Future<void> setDriverOffline() async {
    if (_authService.firebaseUser.value != null) {
      String driverId = _authService.firebaseUser.value!.uid;

      await _firestore.collection('driver_locations').doc(driverId).update({
        'isOnline': false,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> getNearbyDrivers(LatLng location, double radiusInKm) async {
    // Convert radius to degrees (approximate)
    double radiusInDegrees = radiusInKm / 111.32;

    // Calculate bounds
    double minLat = location.latitude - radiusInDegrees;
    double maxLat = location.latitude + radiusInDegrees;
    double minLng = location.longitude - radiusInDegrees;
    double maxLng = location.longitude + radiusInDegrees;

    // Query for drivers within bounds
    QuerySnapshot snapshot = await _firestore.collection('driver_locations')
        .where('isOnline', isEqualTo: true)
        .get();

    List<Map<String, dynamic>> nearbyDrivers = [];

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      GeoPoint driverLocation = data['location'] as GeoPoint;

      // Check if driver is within bounds
      if (driverLocation.latitude >= minLat &&
          driverLocation.latitude <= maxLat &&
          driverLocation.longitude >= minLng &&
          driverLocation.longitude <= maxLng) {

        // Calculate actual distance
        double distance = calculateDistance(
          location.latitude,
          location.longitude,
          driverLocation.latitude,
          driverLocation.longitude,
        );

        if (distance <= radiusInKm) {
          data['distance'] = distance;
          nearbyDrivers.add(data);
        }
      }
    }

    // Sort by distance
    nearbyDrivers.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

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

  // Get place details using Dio and Google Places API
  Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    try {
      final response = await _dio.get(
        '$_placesApiBaseUrl/details/json',
        queryParameters: {
          'place_id': placeId,
          'fields': 'name,formatted_address,geometry',
          'key': Constants.googleMapsApiKey
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final place = response.data['result'];
        return {
          'placeId': placeId,
          'name': place['name'],
          'address': place['formatted_address'] ?? '',
          'location': {
            'lat': place['geometry']['location']['lat'] ?? 0.0,
            'lng': place['geometry']['location']['lng'] ?? 0.0,
          }
        };
      } else {
        print('Error getting place details: ${response.data['status']}');
        throw Exception('Failed to get place details: ${response.data['status']}');
      }
    } catch (e) {
      print('Exception getting place details: $e');
      throw Exception('Failed to get place details: $e');
    }
  }

  // Search places using Dio and Google Places API
  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    try {
      Map<String, dynamic> queryParams = {
        'input': query,
        'key': Constants.googleMapsApiKey
      };

      // Add location bias if available
      if (currentLocation.value != null) {
        queryParams['location'] = '${currentLocation.value!.latitude},${currentLocation.value!.longitude}';
        queryParams['radius'] = '50000'; // 50km radius
        queryParams['strictbounds'] = 'true';
      }

      final response = await _dio.get(
        '$_placesApiBaseUrl/autocomplete/json',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        List<dynamic> predictions = response.data['predictions'];
        return predictions.map<Map<String, dynamic>>((prediction) {
          String mainText = '';
          String secondaryText = '';

          if (prediction['structured_formatting'] != null) {
            mainText = prediction['structured_formatting']['main_text'] ?? '';
            secondaryText = prediction['structured_formatting']['secondary_text'] ?? '';
          }

          return {
            'placeId': prediction['place_id'],
            'name': mainText.isNotEmpty ? mainText : prediction['description'],
            'address': secondaryText,
          };
        }).toList();
      } else {
        print('Error searching places: ${response.data['status']}');
        throw Exception('Failed to search places: ${response.data['status']}');
      }
    } catch (e) {
      print('Exception searching places: $e');
      throw Exception('Failed to search places: $e');
    }
  }

  // Get directions using Dio and Google Directions API
  Future<Map<String, dynamic>> getDirections(LatLng origin, LatLng destination) async {
    try {
      final response = await _dio.get(
        '$_directionsApiBaseUrl/json',
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'mode': 'driving',
          'key': Constants.googleMapsApiKey
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'OK' && response.data['routes'].isNotEmpty) {
        final route = response.data['routes'][0];
        final leg = route['legs'][0];

        // Decode polyline
        final polylinePoints = PolylinePoints();
        final points = polylinePoints.decodePolyline(route['overview_polyline']['points']);

        return {
          'distance': {
            'text': leg['distance']['text'],
            'value': leg['distance']['value'],
          },
          'duration': {
            'text': leg['duration']['text'],
            'value': leg['duration']['value'],
          },
          'polyline': route['overview_polyline']['points'],
          'points': points.map((point) => LatLng(point.latitude, point.longitude)).toList(),
          'startAddress': leg['start_address'],
          'endAddress': leg['end_address'],
          'steps': leg['steps'].map<Map<String, dynamic>>((step) => {
            'distance': step['distance']['text'],
            'duration': step['duration']['text'],
            'instructions': step['html_instructions'],
          }).toList(),
        };
      } else {
        print('Error getting directions: ${response.data['status']}');
        throw Exception('Failed to get directions: ${response.data['status']}');
      }
    } catch (e) {
      print('Exception getting directions: $e');
      throw Exception('Failed to get directions: $e');
    }
  }

  // Calculate ETA to destination
  Future<Map<String, dynamic>> calculateETA(LatLng origin, LatLng destination) async {
    try {
      final directions = await getDirections(origin, destination);
      return {
        'duration': directions['duration'],
        'distance': directions['distance'],
      };
    } catch (e) {
      print('Exception calculating ETA: $e');
      return {
        'duration': {'text': 'Unknown', 'value': 0},
        'distance': {'text': 'Unknown', 'value': 0},
      };
    }
  }

  @override
  void onClose() {
    stopLocationUpdates();
    _locationStreamController.close();
    super.onClose();
  }
}