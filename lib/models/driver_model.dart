import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../modules/driver/controllers/driver_controller.dart';

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
  final String? addressProofUrl;
  final String? selfieWithDocumentsUrl;
  final bool isVerified;
  final bool isOnline;
  final double? rating;
  final int completedRides;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, VerificationStatus> documentStatus;
  
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
    this.addressProofUrl,
    this.selfieWithDocumentsUrl,
    this.isVerified = false,
    this.isOnline = false,
    this.rating,
    this.completedRides = 0,
    required this.createdAt,
    this.updatedAt,
    Map<String, VerificationStatus>? documentStatus,
  }) : this.documentStatus = documentStatus ?? {
         'driverLicense': VerificationStatus.pending,
         'vehicleRegistration': VerificationStatus.pending,
         'insurance': VerificationStatus.pending,
         'addressProof': VerificationStatus.pending,
         'selfieWithDocuments': VerificationStatus.pending,
       };
  
  factory DriverModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return DriverModel(
      id: id ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      vehicleType: map['vehicleType'] ?? '',
      vehicleModel: map['vehicleModel'] ?? '',
      vehicleColor: map['vehicleColor'] ?? '',
      licensePlate: map['licensePlate'] ?? '',
      driverLicenseUrl: map['driverLicenseUrl'],
      vehicleRegistrationUrl: map['vehicleRegistrationUrl'],
      insuranceDocumentUrl: map['insuranceDocumentUrl'],
      addressProofUrl: map['addressProofUrl'],
      selfieWithDocumentsUrl: map['selfieWithDocumentsUrl'],
      isVerified: map['isVerified'] ?? false,
      isOnline: map['isOnline'] ?? false,
      rating: map['rating']?.toDouble(),
      completedRides: map['completedRides'] ?? 0,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] is Timestamp 
              ? (map['createdAt'] as Timestamp).toDate() 
              : DateTime.parse(map['createdAt'].toString()))
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] is Timestamp 
              ? (map['updatedAt'] as Timestamp).toDate() 
              : DateTime.parse(map['updatedAt'].toString()))
          : null,
      documentStatus: map['documentStatus'] != null 
          ? (map['documentStatus'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, _parseVerificationStatus(value)),
            )
          : null,
    );
  }
  
  static VerificationStatus _parseVerificationStatus(dynamic value) {
    if (value is int) {
      return VerificationStatus.values[value];
    } else if (value is String) {
      return VerificationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == value,
        orElse: () => VerificationStatus.pending,
      );
    }
    return VerificationStatus.pending;
  }
  
  factory DriverModel.fromJson(String source) => DriverModel.fromMap(json.decode(source));
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'vehicleType': vehicleType,
      'vehicleModel': vehicleModel,
      'vehicleColor': vehicleColor,
      'licensePlate': licensePlate,
      'driverLicenseUrl': driverLicenseUrl,
      'vehicleRegistrationUrl': vehicleRegistrationUrl,
      'insuranceDocumentUrl': insuranceDocumentUrl,
      'addressProofUrl': addressProofUrl,
      'selfieWithDocumentsUrl': selfieWithDocumentsUrl,
      'isVerified': isVerified,
      'isOnline': isOnline,
      'rating': rating,
      'completedRides': completedRides,
      'createdAt': createdAt is DateTime ? Timestamp.fromDate(createdAt) : createdAt,
      'updatedAt': updatedAt != null ? (updatedAt is DateTime ? Timestamp.fromDate(updatedAt!) : updatedAt) : null,
      'documentStatus': documentStatus.map((key, value) => MapEntry(key, value.index)),
    };
  }
  
  String toJson() => json.encode(toMap());
  
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
    String? addressProofUrl,
    String? selfieWithDocumentsUrl,
    bool? isVerified,
    bool? isOnline,
    double? rating,
    int? completedRides,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, VerificationStatus>? documentStatus,
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
      addressProofUrl: addressProofUrl ?? this.addressProofUrl,
      selfieWithDocumentsUrl: selfieWithDocumentsUrl ?? this.selfieWithDocumentsUrl,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      rating: rating ?? this.rating,
      completedRides: completedRides ?? this.completedRides,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      documentStatus: documentStatus ?? this.documentStatus,
    );
  }
}
