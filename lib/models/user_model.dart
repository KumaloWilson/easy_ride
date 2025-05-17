import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? profileImageUrl;
  final bool isVerified;
  final bool emailVerified;
  final bool isVerificationPending;
  final double rating;
  final int ratingCount;
  final Map<String, dynamic>? driverDetails;
  final Map<String, dynamic>? riderDetails;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userType; // 'driver' or 'rider'

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.profileImageUrl,
    this.isVerified = false,
    this.emailVerified = false,
    this.isVerificationPending = false,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.driverDetails,
    this.riderDetails,
    required this.createdAt,
    required this.updatedAt,
    required this.userType,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'],
      profileImageUrl: data['profileImageUrl'],
      isVerified: data['isVerified'] ?? false,
      emailVerified: data['emailVerified'] ?? false,
      isVerificationPending: data['isVerificationPending'] ?? false,
      rating: (data['rating'] ?? 0.0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
      driverDetails: data['driverDetails'],
      riderDetails: data['riderDetails'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      userType: data['userType'] ?? 'rider',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'isVerified': isVerified,
      'emailVerified': emailVerified,
      'isVerificationPending': isVerificationPending,
      'rating': rating,
      'ratingCount': ratingCount,
      'driverDetails': driverDetails,
      'riderDetails': riderDetails,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'userType': userType,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
    bool? isVerified,
    bool? emailVerified,
    bool? isVerificationPending,
    double? rating,
    int? ratingCount,
    Map<String, dynamic>? driverDetails,
    Map<String, dynamic>? riderDetails,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userType,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isVerified: isVerified ?? this.isVerified,
      emailVerified: emailVerified ?? this.emailVerified,
      isVerificationPending: isVerificationPending ?? this.isVerificationPending,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      driverDetails: driverDetails ?? this.driverDetails,
      riderDetails: riderDetails ?? this.riderDetails,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userType: userType ?? this.userType,
    );
  }
}
