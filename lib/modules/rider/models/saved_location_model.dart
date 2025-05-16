import 'package:flutter/foundation.dart';

enum LocationType { home, work, favorite }

class SavedLocationModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final LocationType type;

  SavedLocationModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
  });

  factory SavedLocationModel.fromMap(Map<String, dynamic> map) {
    try {
      return SavedLocationModel(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        address: map['address'] ?? '',
        latitude: (map['latitude'] is double)
            ? map['latitude']
            : (map['latitude'] != null)
            ? double.tryParse(map['latitude'].toString()) ?? 0.0
            : 0.0,
        longitude: (map['longitude'] is double)
            ? map['longitude']
            : (map['longitude'] != null)
            ? double.tryParse(map['longitude'].toString()) ?? 0.0
            : 0.0,
        type: _parseLocationType(map['type']),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing SavedLocationModel: $e');
      }
      return SavedLocationModel(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        address: map['address'] ?? '',
        latitude: 0.0,
        longitude: 0.0,
        type: LocationType.favorite,
      );
    }
  }

  static LocationType _parseLocationType(dynamic type) {
    if (type is int) {
      return LocationType.values[type];
    } else if (type is String) {
      try {
        return LocationType.values.firstWhere(
              (e) => e.toString().split('.').last.toLowerCase() == type.toLowerCase(),
          orElse: () => LocationType.favorite,
        );
      } catch (_) {
        return LocationType.favorite;
      }
    }
    return LocationType.favorite;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'type': type.toString().split('.').last,
    };
  }

  SavedLocationModel copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    LocationType? type,
  }) {
    return SavedLocationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
    );
  }

  @override
  String toString() {
    return 'SavedLocationModel(id: $id, name: $name, address: $address, latitude: $latitude, longitude: $longitude, type: $type)';
  }
}
