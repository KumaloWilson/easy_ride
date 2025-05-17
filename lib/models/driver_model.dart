import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_ride/models/user_model.dart';
import 'package:easy_ride/models/vehicle_model.dart';

import '../modules/driver/models/driver.dart';
import 'location_model.dart';

class DriverModel {
  final String id;
  final UserModel user;
  final String licenseNumber;
  final String licenseExpiry;
  final List<String> documents;
  final bool isVerified;
  final double rating;
  final int totalRides;
  final VehicleModel vehicle;
  final LocationModel currentLocation;
  final DriverStatus status;
  final DateTime lastStatusUpdate;
  final double totalEarnings;
  final String fcmToken;

  DriverModel({
    required this.id,
    required this.user,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.documents,
    required this.isVerified,
    required this.rating,
    required this.totalRides,
    required this.vehicle,
    required this.currentLocation,
    required this.status,
    required this.lastStatusUpdate,
    required this.totalEarnings,
    required this.fcmToken,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] as String,
      user: UserModel.fromMap(json['user'] as Map<String, dynamic>, json['id'] as String),
      licenseNumber: json['licenseNumber'] as String,
      licenseExpiry: json['licenseExpiry'] as String,
      documents: List<String>.from(json['documents'] as List),
      isVerified: json['isVerified'] as bool,
      rating: (json['rating'] as num).toDouble(),
      totalRides: json['totalRides'] as int,
      vehicle: VehicleModel.fromJson(json['vehicle'] as Map<String, dynamic>),
      currentLocation: LocationModel.fromJson(json['currentLocation'] as String),
      status: _parseDriverStatus(json['status'] as String),
      lastStatusUpdate: (json['lastStatusUpdate'] as Timestamp).toDate(),
      totalEarnings: (json['totalEarnings'] as num).toDouble(),
      fcmToken: json['fcmToken'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toMap(),
      'licenseNumber': licenseNumber,
      'licenseExpiry': licenseExpiry,
      'documents': documents,
      'isVerified': isVerified,
      'rating': rating,
      'totalRides': totalRides,
      'vehicle': vehicle.toJson(),
      'currentLocation': currentLocation.toJson(),
      'status': status.toString().split('.').last,
      'lastStatusUpdate': Timestamp.fromDate(lastStatusUpdate),
      'totalEarnings': totalEarnings,
      'fcmToken': fcmToken,
    };
  }

  DriverModel copyWith({
    String? id,
    UserModel? user,
    String? licenseNumber,
    String? licenseExpiry,
    List<String>? documents,
    bool? isVerified,
    double? rating,
    int? totalRides,
    VehicleModel? vehicle,
    LocationModel? currentLocation,
    DriverStatus? status,
    DateTime? lastStatusUpdate,
    double? totalEarnings,
    String? fcmToken,
  }) {
    return DriverModel(
      id: id ?? this.id,
      user: user ?? this.user,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      documents: documents ?? this.documents,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      vehicle: vehicle ?? this.vehicle,
      currentLocation: currentLocation ?? this.currentLocation,
      status: status ?? this.status,
      lastStatusUpdate: lastStatusUpdate ?? this.lastStatusUpdate,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  static DriverStatus _parseDriverStatus(String status) {
    switch (status) {
      case 'online':
        return DriverStatus.online;
      case 'offline':
        return DriverStatus.offline;
      case 'busy':
        return DriverStatus.busy;
      case 'onBreak':
        return DriverStatus.onBreak;
      default:
        return DriverStatus.offline;
    }
  }
}
