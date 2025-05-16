import 'package:cloud_firestore/cloud_firestore.dart';

class DriverModel {
  final String id;
  final String userId;
  final String vehicleType;
  final String vehicleModel;
  final String vehicleColor;
  final String licensePlate;
  final String? driverLicenseUrl;
  final String? vehicleRegistrationUrl;
  final String? insuranceDocumentUrl;
  final bool isVerified;
  final bool isOnline;
  final double? rating;
  final int completedRides;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  DriverModel({
    required this.id,
    required this.userId,
    required this.vehicleType,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.licensePlate,
    this.driverLicenseUrl,
    this.vehicleRegistrationUrl,
    this.insuranceDocumentUrl,
    this.isVerified = false,
    this.isOnline = false,
    this.rating,
    this.completedRides = 0,
    required this.createdAt,
    this.updatedAt,
  });
  
  factory DriverModel.fromMap(Map<String, dynamic> map, String id) {
    return DriverModel(
      id: id,
      userId: map['userId'] ?? '',
      vehicleType: map['vehicleType'] ?? '',
      vehicleModel: map['vehicleModel'] ?? '',
      vehicleColor: map['vehicleColor'] ?? '',
      licensePlate: map['licensePlate'] ?? '',
      driverLicenseUrl: map['driverLicenseUrl'],
      vehicleRegistrationUrl: map['vehicleRegistrationUrl'],
      insuranceDocumentUrl: map['insuranceDocumentUrl'],
      isVerified: map['isVerified'] ?? false,
      isOnline: map['isOnline'] ?? false,
      rating: map['rating']?.toDouble(),
      completedRides: map['completedRides'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'vehicleType': vehicleType,
      'vehicleModel': vehicleModel,
      'vehicleColor': vehicleColor,
      'licensePlate': licensePlate,
      'driverLicenseUrl': driverLicenseUrl,
      'vehicleRegistrationUrl': vehicleRegistrationUrl,
      'insuranceDocumentUrl': insuranceDocumentUrl,
      'isVerified': isVerified,
      'isOnline': isOnline,
      'rating': rating,
      'completedRides': completedRides,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
  
  DriverModel copyWith({
    String? id,
    String? userId,
    String? vehicleType,
    String? vehicleModel,
    String? vehicleColor,
    String? licensePlate,
    String? driverLicenseUrl,
    String? vehicleRegistrationUrl,
    String? insuranceDocumentUrl,
    bool? isVerified,
    bool? isOnline,
    double? rating,
    int? completedRides,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DriverModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      licensePlate: licensePlate ?? this.licensePlate,
      driverLicenseUrl: driverLicenseUrl ?? this.driverLicenseUrl,
      vehicleRegistrationUrl: vehicleRegistrationUrl ?? this.vehicleRegistrationUrl,
      insuranceDocumentUrl: insuranceDocumentUrl ?? this.insuranceDocumentUrl,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      rating: rating ?? this.rating,
      completedRides: completedRides ?? this.completedRides,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
