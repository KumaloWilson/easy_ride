import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:easy_ride/models/location_model.dart';

class RideModel {
  final String id;
  final String riderId;
  final String? driverId;
  final String status; // 'pending', 'accepted', 'arrived', 'started', 'completed', 'cancelled'
  final String rideType; // 'Standard', 'Premium', 'XL'
  final LocationModel? pickup;
  final LocationModel? dropoff;
  final double distance; // in km
  final double duration; // in minutes
  final double fare;
  final String paymentMethod; // 'cash', 'card', etc.
  final bool isPaid;
  final double? riderRating;
  final double? driverRating;
  final String? riderFeedback;
  final String? driverFeedback;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? arrivedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? polyline;
  
  RideModel({
    required this.id,
    required this.riderId,
    this.driverId,
    required this.status,
    required this.rideType,
     this.pickup,
     this.dropoff,
    required this.distance,
    required this.duration,
    required this.fare,
    required this.paymentMethod,
    this.isPaid = false,
    this.riderRating,
    this.driverRating,
    this.riderFeedback,
    this.driverFeedback,
    required this.createdAt,
    this.acceptedAt,
    this.arrivedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.polyline,
  });
  
  factory RideModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return RideModel(
      id: id ?? map['id'] ?? '',
      riderId: map['riderId'] ?? '',
      driverId: map['driverId'],
      status: map['status'] ?? 'pending',
      rideType: map['rideType'] ?? 'Standard',
      pickup: map['pickup'] is LocationModel 
          ? map['pickup'] 
          : LocationModel.fromMap(map['pickup'] ?? {}),
      dropoff: map['dropoff'] is LocationModel 
          ? map['dropoff'] 
          : LocationModel.fromMap(map['dropoff'] ?? {}),
      distance: map['distance']?.toDouble() ?? 0.0,
      duration: map['duration']?.toDouble() ?? 0.0,
      fare: map['fare']?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] ?? 'cash',
      isPaid: map['isPaid'] ?? false,
      riderRating: map['riderRating']?.toDouble(),
      driverRating: map['driverRating']?.toDouble(),
      riderFeedback: map['riderFeedback'],
      driverFeedback: map['driverFeedback'],
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] is Timestamp 
              ? (map['createdAt'] as Timestamp).toDate() 
              : DateTime.parse(map['createdAt'].toString()))
          : DateTime.now(),
      acceptedAt: map['acceptedAt'] != null 
          ? (map['acceptedAt'] is Timestamp 
              ? (map['acceptedAt'] as Timestamp).toDate() 
              : DateTime.parse(map['acceptedAt'].toString()))
          : null,
      arrivedAt: map['arrivedAt'] != null 
          ? (map['arrivedAt'] is Timestamp 
              ? (map['arrivedAt'] as Timestamp).toDate() 
              : DateTime.parse(map['arrivedAt'].toString()))
          : null,
      startedAt: map['startedAt'] != null 
          ? (map['startedAt'] is Timestamp 
              ? (map['startedAt'] as Timestamp).toDate() 
              : DateTime.parse(map['startedAt'].toString()))
          : null,
      completedAt: map['completedAt'] != null 
          ? (map['completedAt'] is Timestamp 
              ? (map['completedAt'] as Timestamp).toDate() 
              : DateTime.parse(map['completedAt'].toString()))
          : null,
      cancelledAt: map['cancelledAt'] != null 
          ? (map['cancelledAt'] is Timestamp 
              ? (map['cancelledAt'] as Timestamp).toDate() 
              : DateTime.parse(map['cancelledAt'].toString()))
          : null,
      polyline: map['polyline'],
    );
  }
  
  factory RideModel.fromJson(String source) => RideModel.fromMap(json.decode(source));
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'riderId': riderId,
      'driverId': driverId,
      'status': status,
      'rideType': rideType,
      'pickup': pickup!.toMap(),
      'dropoff': dropoff!.toMap(),
      'distance': distance,
      'duration': duration,
      'fare': fare,
      'paymentMethod': paymentMethod,
      'isPaid': isPaid,
      'riderRating': riderRating,
      'driverRating': driverRating,
      'riderFeedback': riderFeedback,
      'driverFeedback': driverFeedback,
      'createdAt': createdAt is DateTime ? Timestamp.fromDate(createdAt) : createdAt,
      'acceptedAt': acceptedAt != null ? (acceptedAt is DateTime ? Timestamp.fromDate(acceptedAt!) : acceptedAt) : null,
      'arrivedAt': arrivedAt != null ? (arrivedAt is DateTime ? Timestamp.fromDate(arrivedAt!) : arrivedAt) : null,
      'startedAt': startedAt != null ? (startedAt is DateTime ? Timestamp.fromDate(startedAt!) : startedAt) : null,
      'completedAt': completedAt != null ? (completedAt is DateTime ? Timestamp.fromDate(completedAt!) : completedAt) : null,
      'cancelledAt': cancelledAt != null ? (cancelledAt is DateTime ? Timestamp.fromDate(cancelledAt!) : cancelledAt) : null,
      'polyline': polyline,
    };
  }
  
  String toJson() => json.encode(toMap());
  
  RideModel copyWith({
    String? id,
    String? riderId,
    String? driverId,
    String? status,
    String? rideType,
    LocationModel? pickup,
    LocationModel? dropoff,
    double? distance,
    double? duration,
    double? fare,
    String? paymentMethod,
    bool? isPaid,
    double? riderRating,
    double? driverRating,
    String? riderFeedback,
    String? driverFeedback,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? arrivedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? polyline,
  }) {
    return RideModel(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      driverId: driverId ?? this.driverId,
      status: status ?? this.status,
      rideType: rideType ?? this.rideType,
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      fare: fare ?? this.fare,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isPaid: isPaid ?? this.isPaid,
      riderRating: riderRating ?? this.riderRating,
      driverRating: driverRating ?? this.driverRating,
      riderFeedback: riderFeedback ?? this.riderFeedback,
      driverFeedback: driverFeedback ?? this.driverFeedback,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      polyline: polyline ?? this.polyline,
    );
  }
}
