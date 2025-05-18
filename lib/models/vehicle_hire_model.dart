import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_ride/models/location_model.dart';

enum HireStatus {
  pending,
  approved,
  rejected,
  active,
  completed,
  cancelled
}

enum HireDurationType {
  hourly,
  daily
}

enum HirePurpose {
  errands,
  delivery,
  chauffeur,
  moving,
  other
}

class VehicleHireModel {
  final String id;
  final String riderId;
  final String vehicleId;
  final String? driverId;
  final HireStatus status;
  final HireDurationType durationType;
  final HirePurpose purpose;
  final String purposeDescription;
  final DateTime startTime;
  final DateTime endTime;
  final LocationModel pickupLocation;
  final List<LocationModel> stops;
  final bool returnToOrigin;
  final bool selfDrive;
  final double totalCost;
  final String paymentMethod;
  final bool isPaid;
  final double? rating;
  final String? feedback;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? adminNotes;
  final bool isRecurring;
  final String? recurringPattern; // e.g., "WEEKLY:2" for every Tuesday
  final int? recurringCount;
  final DateTime? recurringEndDate;
  
  VehicleHireModel({
    required this.id,
    required this.riderId,
    required this.vehicleId,
    this.driverId,
    required this.status,
    required this.durationType,
    required this.purpose,
    required this.purposeDescription,
    required this.startTime,
    required this.endTime,
    required this.pickupLocation,
    required this.stops,
    this.returnToOrigin = false,
    this.selfDrive = false,
    required this.totalCost,
    required this.paymentMethod,
    this.isPaid = false,
    this.rating,
    this.feedback,
    required this.createdAt,
    this.approvedAt,
    this.rejectedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.adminNotes,
    this.isRecurring = false,
    this.recurringPattern,
    this.recurringCount,
    this.recurringEndDate,
  });
  
  factory VehicleHireModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return VehicleHireModel(
      id: id ?? map['id'] ?? '',
      riderId: map['riderId'] ?? '',
      vehicleId: map['vehicleId'] ?? '',
      driverId: map['driverId'],
      status: HireStatus.values.firstWhere(
        (e) => e.toString() == 'HireStatus.${map['status']}',
        orElse: () => HireStatus.pending,
      ),
      durationType: HireDurationType.values.firstWhere(
        (e) => e.toString() == 'HireDurationType.${map['durationType']}',
        orElse: () => HireDurationType.hourly,
      ),
      purpose: HirePurpose.values.firstWhere(
        (e) => e.toString() == 'HirePurpose.${map['purpose']}',
        orElse: () => HirePurpose.other,
      ),
      purposeDescription: map['purposeDescription'] ?? '',
      startTime: map['startTime'] != null 
          ? (map['startTime'] is Timestamp 
              ? (map['startTime'] as Timestamp).toDate() 
              : DateTime.parse(map['startTime'].toString()))
          : DateTime.now(),
      endTime: map['endTime'] != null 
          ? (map['endTime'] is Timestamp 
              ? (map['endTime'] as Timestamp).toDate() 
              : DateTime.parse(map['endTime'].toString()))
          : DateTime.now().add(const Duration(hours: 1)),
      pickupLocation: map['pickupLocation'] is LocationModel 
          ? map['pickupLocation'] 
          : LocationModel.fromMap(map['pickupLocation'] ?? {}),
      stops: (map['stops'] as List<dynamic>?)?.map((stop) => 
          stop is LocationModel 
              ? stop 
              : LocationModel.fromMap(stop)
      ).toList() ?? [],
      returnToOrigin: map['returnToOrigin'] ?? false,
      selfDrive: map['selfDrive'] ?? false,
      totalCost: (map['totalCost'] ?? 0.0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? 'card',
      isPaid: map['isPaid'] ?? false,
      rating: map['rating']?.toDouble(),
      feedback: map['feedback'],
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] is Timestamp 
              ? (map['createdAt'] as Timestamp).toDate() 
              : DateTime.parse(map['createdAt'].toString()))
          : DateTime.now(),
      approvedAt: map['approvedAt'] != null 
          ? (map['approvedAt'] is Timestamp 
              ? (map['approvedAt'] as Timestamp).toDate() 
              : DateTime.parse(map['approvedAt'].toString()))
          : null,
      rejectedAt: map['rejectedAt'] != null 
          ? (map['rejectedAt'] is Timestamp 
              ? (map['rejectedAt'] as Timestamp).toDate() 
              : DateTime.parse(map['rejectedAt'].toString()))
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
      cancellationReason: map['cancellationReason'],
      adminNotes: map['adminNotes'],
      isRecurring: map['isRecurring'] ?? false,
      recurringPattern: map['recurringPattern'],
      recurringCount: map['recurringCount'],
      recurringEndDate: map['recurringEndDate'] != null 
          ? (map['recurringEndDate'] is Timestamp 
              ? (map['recurringEndDate'] as Timestamp).toDate() 
              : DateTime.parse(map['recurringEndDate'].toString()))
          : null,
    );
  }
  
  factory VehicleHireModel.fromJson(String source) => VehicleHireModel.fromMap(json.decode(source));
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'riderId': riderId,
      'vehicleId': vehicleId,
      'driverId': driverId,
      'status': status.toString().split('.').last,
      'durationType': durationType.toString().split('.').last,
      'purpose': purpose.toString().split('.').last,
      'purposeDescription': purposeDescription,
      'startTime': startTime is DateTime ? Timestamp.fromDate(startTime) : startTime,
      'endTime': endTime is DateTime ? Timestamp.fromDate(endTime) : endTime,
      'pickupLocation': pickupLocation.toMap(),
      'stops': stops.map((stop) => stop.toMap()).toList(),
      'returnToOrigin': returnToOrigin,
      'selfDrive': selfDrive,
      'totalCost': totalCost,
      'paymentMethod': paymentMethod,
      'isPaid': isPaid,
      'rating': rating,
      'feedback': feedback,
      'createdAt': createdAt is DateTime ? Timestamp.fromDate(createdAt) : createdAt,
      'approvedAt': approvedAt != null ? (approvedAt is DateTime ? Timestamp.fromDate(approvedAt!) : approvedAt) : null,
      'rejectedAt': rejectedAt != null ? (rejectedAt is DateTime ? Timestamp.fromDate(rejectedAt!) : rejectedAt) : null,
      'startedAt': startedAt != null ? (startedAt is DateTime ? Timestamp.fromDate(startedAt!) : startedAt) : null,
      'completedAt': completedAt != null ? (completedAt is DateTime ? Timestamp.fromDate(completedAt!) : completedAt) : null,
      'cancelledAt': cancelledAt != null ? (cancelledAt is DateTime ? Timestamp.fromDate(cancelledAt!) : cancelledAt) : null,
      'cancellationReason': cancellationReason,
      'adminNotes': adminNotes,
      'isRecurring': isRecurring,
      'recurringPattern': recurringPattern,
      'recurringCount': recurringCount,
      'recurringEndDate': recurringEndDate != null ? (recurringEndDate is DateTime ? Timestamp.fromDate(recurringEndDate!) : recurringEndDate) : null,
    };
  }
  
  String toJson() => json.encode(toMap());
  
  VehicleHireModel copyWith({
    String? id,
    String? riderId,
    String? vehicleId,
    String? driverId,
    HireStatus? status,
    HireDurationType? durationType,
    HirePurpose? purpose,
    String? purposeDescription,
    DateTime? startTime,
    DateTime? endTime,
    LocationModel? pickupLocation,
    List<LocationModel>? stops,
    bool? returnToOrigin,
    bool? selfDrive,
    double? totalCost,
    String? paymentMethod,
    bool? isPaid,
    double? rating,
    String? feedback,
    DateTime? createdAt,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    String? adminNotes,
    bool? isRecurring,
    String? recurringPattern,
    int? recurringCount,
    DateTime? recurringEndDate,
  }) {
    return VehicleHireModel(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      vehicleId: vehicleId ?? this.vehicleId,
      driverId: driverId ?? this.driverId,
      status: status ?? this.status,
      durationType: durationType ?? this.durationType,
      purpose: purpose ?? this.purpose,
      purposeDescription: purposeDescription ?? this.purposeDescription,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      stops: stops ?? this.stops,
      returnToOrigin: returnToOrigin ?? this.returnToOrigin,
      selfDrive: selfDrive ?? this.selfDrive,
      totalCost: totalCost ?? this.totalCost,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isPaid: isPaid ?? this.isPaid,
      rating: rating ?? this.rating,
      feedback: feedback ?? this.feedback,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      adminNotes: adminNotes ?? this.adminNotes,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      recurringCount: recurringCount ?? this.recurringCount,
      recurringEndDate: recurringEndDate ?? this.recurringEndDate,
    );
  }

  // Calculate duration in hours
  double get durationInHours {
    return endTime.difference(startTime).inMinutes / 60;
  }

  // Calculate duration in days
  int get durationInDays {
    return endTime.difference(startTime).inDays + 1; // Including partial days
  }

  // Check if hire is active now
  bool get isActiveNow {
    final now = DateTime.now();
    return status == HireStatus.active && 
           now.isAfter(startTime) && 
           now.isBefore(endTime);
  }

  // Check if hire is scheduled for future
  bool get isScheduled {
    final now = DateTime.now();
    return status == HireStatus.approved && 
           now.isBefore(startTime);
  }

  // Get formatted duration string
  String get formattedDuration {
    if (durationType == HireDurationType.hourly) {
      final hours = durationInHours;
      return hours == 1 ? '1 hour' : '${hours.toStringAsFixed(1)} hours';
    } else {
      final days = durationInDays;
      return days == 1 ? '1 day' : '$days days';
    }
  }

  // Get formatted status string
  String get formattedStatus {
    switch (status) {
      case HireStatus.pending:
        return 'Pending Approval';
      case HireStatus.approved:
        return 'Approved';
      case HireStatus.rejected:
        return 'Rejected';
      case HireStatus.active:
        return 'Active';
      case HireStatus.completed:
        return 'Completed';
      case HireStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  // Get formatted purpose string
  String get formattedPurpose {
    switch (purpose) {
      case HirePurpose.errands:
        return 'Errands';
      case HirePurpose.delivery:
        return 'Delivery';
      case HirePurpose.chauffeur:
        return 'Personal Chauffeur';
      case HirePurpose.moving:
        return 'Moving';
      case HirePurpose.other:
        return 'Other';
      default:
        return 'Unknown';
    }
  }
}
