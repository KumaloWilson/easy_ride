import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String? phoneNumber;
  final String? fullName;
  final String? profileImageUrl;
  final String userType; // 'rider' or 'driver'
  final bool isVerified;
  final List<String>? fcmTokens;
  final Map<String, dynamic>? driverDetails;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  UserModel({
    required this.id,
    required this.email,
    this.phoneNumber,
    this.fullName,
    this.profileImageUrl,
    required this.userType,
    this.isVerified = false,
    this.fcmTokens,
    this.driverDetails,
    required this.createdAt,
    this.updatedAt,
  });
  
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      fullName: map['fullName'],
      profileImageUrl: map['profileImageUrl'],
      userType: map['userType'] ?? 'rider',
      isVerified: map['isVerified'] ?? false,
      fcmTokens: map['fcmTokens'] != null ? List<String>.from(map['fcmTokens']) : null,
      driverDetails: map['driverDetails'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'phoneNumber': phoneNumber,
      'fullName': fullName,
      'profileImageUrl': profileImageUrl,
      'userType': userType,
      'isVerified': isVerified,
      'fcmTokens': fcmTokens,
      'driverDetails': driverDetails,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
  
  UserModel copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    String? fullName,
    String? profileImageUrl,
    String? userType,
    bool? isVerified,
    List<String>? fcmTokens,
    Map<String, dynamic>? driverDetails,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullName: fullName ?? this.fullName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      userType: userType ?? this.userType,
      isVerified: isVerified ?? this.isVerified,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      driverDetails: driverDetails ?? this.driverDetails,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
