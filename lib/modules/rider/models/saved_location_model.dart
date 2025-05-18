import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/location_model.dart';

class SavedLocationModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final LocationType type;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SavedLocationModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.createdAt,
    this.updatedAt,
  });

  factory SavedLocationModel.fromMap(Map<String, dynamic> map, String id) {
    return SavedLocationModel(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      type: _parseLocationType(map['type'] ?? 'favorite'),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'type': type.toString().split('.').last,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static LocationType _parseLocationType(String type) {
    switch (type) {
      case 'home':
        return LocationType.home;
      case 'work':
        return LocationType.work;
      case 'recent':
        return LocationType.recent;
      case 'favorite':
      default:
        return LocationType.favorite;
    }
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate(); // handles Firestore Timestamp
    try {
      return DateTime.parse(value.toString()); // fallback
    } catch (e) {
      return null;
    }
  }


}
