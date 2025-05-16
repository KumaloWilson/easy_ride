import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideModel {
  final String id;
  final String riderId;
  final String? driverId;
  final String status; // 'pending', 'accepted', 'arrived', 'started', 'completed', 'cancelled'
  final String rideType; // 'Standard', 'Premium', 'XL'
  final Map<String, dynamic> pickup;
  final Map<String, dynamic> dropoff;
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
  
  RideModel({
    required this.id,
    required this.riderId,
    this.driverId,
    required this.status,
    required this.rideType,
    required this.pickup,
    required this.dropoff,
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
  });
  
  factory RideModel.fromMap(Map<String, dynamic> map, String id) {
    return RideModel(
      id: id,
      riderId: map['riderId'] ?? '',
      driverId: map['driverId'],
      status: map['status'] ?? 'pending',
      rideType: map['rideType'] ?? 'Standard',
      pickup: map['pickup'] ?? {},
      dropoff: map['dropoff'] ?? {},
      distance: map['distance']?.toDouble() ?? 0.0,
      duration: map['duration']?.toDouble() ?? 0.0,
      fare: map['fare']?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] ?? 'cash',
      isPaid: map['isPaid'] ?? false,
      riderRating: map['riderRating']?.toDouble(),
      driverRating: map['driverRating']?.toDouble(),
      riderFeedback: map['riderFeedback'],
      driverFeedback: map['driverFeedback'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      acceptedAt: map['acceptedAt'] != null ? (map['acceptedAt'] as Timestamp).toDate() : null,
      arrivedAt: map['arrivedAt'] != null ? (map['arrivedAt'] as Timestamp).toDate() : null,
      startedAt: map['startedAt'] != null ? (map['startedAt'] as Timestamp).toDate() : null,
      completedAt: map['completedAt'] != null ? (map['completedAt'] as Timestamp).toDate() : null,
      cancelledAt: map['cancelledAt'] != null ? (map['cancelledAt'] as Timestamp).toDate() : null,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'riderId': riderId,
      'driverId': driverId,
      'status': status,
      'rideType': rideType,
      'pickup': pickup,
      'dropoff': dropoff,
      'distance': distance,
      'duration': duration,
      'fare': fare,
      'paymentMethod': paymentMethod,
      'isPaid': isPaid,
      'riderRating': riderRating,
      'driverRating': driverRating,
      'riderFeedback': riderFeedback,
      'driverFeedback': driverFeedback,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'arrivedAt': arrivedAt != null ? Timestamp.fromDate(arrivedAt!) : null,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
    };
  }
  
  RideModel copyWith({
    String? id,
    String? riderId,
    String? driverId,
    String? status,
    String? rideType,
    Map<String, dynamic>? pickup,
    Map<String, dynamic>? dropoff,
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
    );
  }
}
