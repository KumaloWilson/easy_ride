import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum LocationType {
  home,
  work,
  favorite,
  recent,
  custom,
}

class LocationModel {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? placeId;
  final double? distance;
  final LocationType? type;

  LocationModel({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.placeId,
    this.distance,
    this.type,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  bool get isEmpty => latitude == 0 && longitude == 0 && name.isEmpty && address.isEmpty;

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    if (map.isEmpty) {
      return LocationModel(
        name: '',
        address: '',
        latitude: 0,
        longitude: 0,
      );
    }

    // Handle different location formats
    double lat = 0;
    double lng = 0;

    if (map['location'] != null) {
      if (map['location'] is GeoPoint) {
        final GeoPoint geoPoint = map['location'] as GeoPoint;
        lat = geoPoint.latitude;
        lng = geoPoint.longitude;
      } else if (map['location'] is Map) {
        lat = (map['location']['lat'] ?? 0).toDouble();
        lng = (map['location']['lng'] ?? 0).toDouble();
      }
    } else {
      lat = (map['latitude'] ?? 0).toDouble();
      lng = (map['longitude'] ?? 0).toDouble();
    }

    // Parse location type
    LocationType? locationType;
    if (map['type'] != null) {
      switch (map['type']) {
        case 'home':
          locationType = LocationType.home;
          break;
        case 'work':
          locationType = LocationType.work;
          break;
        case 'favorite':
          locationType = LocationType.favorite;
          break;
        case 'recent':
          locationType = LocationType.recent;
          break;
        default:
          locationType = LocationType.custom;
      }
    }

    return LocationModel(
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      latitude: lat,
      longitude: lng,
      placeId: map['placeId'],
      distance: map['distance']?.toDouble(),
      type: locationType,
    );
  }

  factory LocationModel.fromJson(String source) => LocationModel.fromMap(json.decode(source));

  Map<String, dynamic> toMap() {
    String? typeString;
    if (type != null) {
      switch (type) {
        case LocationType.home:
          typeString = 'home';
          break;
        case LocationType.work:
          typeString = 'work';
          break;
        case LocationType.favorite:
          typeString = 'favorite';
          break;
        case LocationType.recent:
          typeString = 'recent';
          break;
        case LocationType.custom:
          typeString = 'custom';
          break;
        default:
          typeString = null;
      }
    }

    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'placeId': placeId,
      'distance': distance,
      'type': typeString,
      'location': {
        'lat': latitude,
        'lng': longitude,
      },
    };
  }

  String toJson() => json.encode(toMap());

  LocationModel copyWith({
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? placeId,
    double? distance,
    LocationType? type,
  }) {
    return LocationModel(
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeId: placeId ?? this.placeId,
      distance: distance ?? this.distance,
      type: type ?? this.type,
    );
  }

  // Convert to GeoPoint for Firestore
  GeoPoint toGeoPoint() {
    return GeoPoint(latitude, longitude);
  }

  // Create a location from current position
  static Future<LocationModel> fromCurrentPosition(double lat, double lng, String address) async {
    return LocationModel(
      name: 'Current Location',
      address: address,
      latitude: lat,
      longitude: lng,
      type: LocationType.custom,
    );
  }
}
