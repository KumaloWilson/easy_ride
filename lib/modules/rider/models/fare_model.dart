import 'package:easy_ride/core/values/constants.dart';

class FareModel {
  final double baseFare;
  final double distanceFare;
  final double timeFare;
  final double surgeFactor;
  final double discount;
  final double tax;
  final double totalFare;
  final String rideType;
  final double distance; // in km
  final double duration; // in minutes

  FareModel({
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    required this.surgeFactor,
    required this.discount,
    required this.tax,
    required this.totalFare,
    required this.rideType,
    required this.distance,
    required this.duration,
  });

  factory FareModel.calculate({
    required String rideType,
    required double distance,
    required double duration,
    double surgeFactor = 1.0,
    double discount = 0.0,
    double taxRate = 0.1, // 10% tax
  }) {
    // Get ride type multiplier
    final rideTypeMultiplier = Constants.rideTypes[rideType] ?? 1.0;
    
    // Calculate base components
    final baseFare = Constants.baseFare * rideTypeMultiplier;
    final distanceFare = distance * Constants.perKmRate * rideTypeMultiplier;
    final timeFare = duration * Constants.perMinuteRate * rideTypeMultiplier;
    
    // Apply surge pricing
    final fareBeforeSurge = baseFare + distanceFare + timeFare;
    final fareWithSurge = fareBeforeSurge * surgeFactor;
    
    // Apply discount
    final fareAfterDiscount = fareWithSurge - discount;
    
    // Apply tax
    final taxAmount = fareAfterDiscount * taxRate;
    final totalFare = fareAfterDiscount + taxAmount;
    
    return FareModel(
      baseFare: baseFare,
      distanceFare: distanceFare,
      timeFare: timeFare,
      surgeFactor: surgeFactor,
      discount: discount,
      tax: taxAmount,
      totalFare: totalFare,
      rideType: rideType,
      distance: distance,
      duration: duration,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'baseFare': baseFare,
      'distanceFare': distanceFare,
      'timeFare': timeFare,
      'surgeFactor': surgeFactor,
      'discount': discount,
      'tax': tax,
      'totalFare': totalFare,
      'rideType': rideType,
      'distance': distance,
      'duration': duration,
    };
  }

  factory FareModel.fromMap(Map<String, dynamic> map) {
    return FareModel(
      baseFare: map['baseFare']?.toDouble() ?? 0.0,
      distanceFare: map['distanceFare']?.toDouble() ?? 0.0,
      timeFare: map['timeFare']?.toDouble() ?? 0.0,
      surgeFactor: map['surgeFactor']?.toDouble() ?? 1.0,
      discount: map['discount']?.toDouble() ?? 0.0,
      tax: map['tax']?.toDouble() ?? 0.0,
      totalFare: map['totalFare']?.toDouble() ?? 0.0,
      rideType: map['rideType'] ?? 'Standard',
      distance: map['distance']?.toDouble() ?? 0.0,
      duration: map['duration']?.toDouble() ?? 0.0,
    );
  }
}
