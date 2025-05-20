import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_ride/models/ride_status.dart';

import 'location_model.dart';

class RideRequest {
  final String id;
  final String riderId;
  final String? driverId;
  final LocationModel pickupLocation;
  final LocationModel dropoffLocation;
  final DateTime requestTime;
  final RideStatus status;
  final double estimatedFare;
  final double? distance;
  final String vehicleType;
  final String rideType;
  final String paymentMethod;
  final String? notes;
  final DateTime? acceptedTime;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isScheduled;
  final DateTime? scheduledTime;

  RideRequest({
    required this.id,
    required this.riderId,
    this.driverId,
    this.distance,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.requestTime,
    required this.status,
    required this.estimatedFare,
    required this.vehicleType,
    required this.rideType,
    required this.paymentMethod,
    this.notes,
    this.acceptedTime,
    this.startTime,
    this.endTime,
    required this.isScheduled,
    this.scheduledTime,
  });

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      id: json['id'] as String,
      riderId: json['riderId'] as String,
      driverId: json['driverId'] as String?,
      pickupLocation: LocationModel.fromJson(json['pickupLocation'] as String),
      dropoffLocation: LocationModel.fromJson(json['dropoffLocation'] as String),
      requestTime: (json['requestTime'] as Timestamp).toDate(),
      status: RideStatus.values.firstWhere(
            (e) => e.toString().split('.').last == json['status'],
        orElse: () => RideStatus.requested,
      ),
      estimatedFare: (json['estimatedFare'] as num).toDouble(),
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
      vehicleType: json['vehicleType'] as String,
      rideType: json['rideType'] as String,
      paymentMethod: json['paymentMethod'] as String,
      notes: json['notes'] as String?,
      acceptedTime: json['acceptedTime'] != null ? (json['acceptedTime'] as Timestamp).toDate() : null,
      startTime: json['startTime'] != null ? (json['startTime'] as Timestamp).toDate() : null,
      endTime: json['endTime'] != null ? (json['endTime'] as Timestamp).toDate() : null,
      isScheduled: json['isScheduled'] as bool? ?? false,
      scheduledTime: json['scheduledTime'] != null ? (json['scheduledTime'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'riderId': riderId,
      'driverId': driverId,
      'pickupLocation': pickupLocation.toJson(),
      'dropoffLocation': dropoffLocation.toJson(),
      'requestTime': Timestamp.fromDate(requestTime),
      'status': status.toString().split('.').last,
      'estimatedFare': estimatedFare,
      'vehicleType': vehicleType,
      'distance': distance,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'acceptedTime': acceptedTime != null ? Timestamp.fromDate(acceptedTime!) : null,
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'isScheduled': isScheduled,
      'scheduledTime': scheduledTime != null ? Timestamp.fromDate(scheduledTime!) : null,
    };
  }

  RideRequest copyWith({
    String? id,
    String? riderId,
    String? driverId,
    LocationModel? pickupLocation,
    LocationModel? dropoffLocation,
    DateTime? requestTime,
    RideStatus? status,
    double? estimatedFare,
    double? distance,
    String? vehicleType,
    String? rideType,
    String? paymentMethod,
    String? notes,
    DateTime? acceptedTime,
    DateTime? startTime,
    DateTime? endTime,
    bool? isScheduled,
    DateTime? scheduledTime,
  }) {
    return RideRequest(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      driverId: driverId ?? this.driverId,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      requestTime: requestTime ?? this.requestTime,
      status: status ?? this.status,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      distance: distance ?? this.distance,
      vehicleType: vehicleType ?? this.vehicleType,
      rideType: rideType ?? this.rideType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      acceptedTime: acceptedTime ?? this.acceptedTime,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isScheduled: isScheduled ?? this.isScheduled,
      scheduledTime: scheduledTime ?? this.scheduledTime,
    );
  }
}
