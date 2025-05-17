class FareModel {
  final String rideType;
  final double distance;
  final double duration;
  final double baseFare;
  final double distanceFare;
  final double timeFare;
  final double surgeFactor;
  final double discount;
  final double tax;
  final double totalFare;

  FareModel({
    required this.rideType,
    required this.distance,
    required this.duration,
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    required this.surgeFactor,
    required this.discount,
    required this.tax,
    required this.totalFare,
  });

  factory FareModel.fromMap(Map<String, dynamic> map) {
    return FareModel(
      rideType: map['rideType'] ?? 'Standard',
      distance: (map['distance'] ?? 0.0).toDouble(),
      duration: (map['duration'] ?? 0.0).toDouble(),
      baseFare: (map['baseFare'] ?? 0.0).toDouble(),
      distanceFare: (map['distanceFare'] ?? 0.0).toDouble(),
      timeFare: (map['timeFare'] ?? 0.0).toDouble(),
      surgeFactor: (map['surgeFactor'] ?? 1.0).toDouble(),
      discount: (map['discount'] ?? 0.0).toDouble(),
      tax: (map['tax'] ?? 0.0).toDouble(),
      totalFare: (map['totalFare'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rideType': rideType,
      'distance': distance,
      'duration': duration,
      'baseFare': baseFare,
      'distanceFare': distanceFare,
      'timeFare': timeFare,
      'surgeFactor': surgeFactor,
      'discount': discount,
      'tax': tax,
      'totalFare': totalFare,
    };
  }

  static FareModel calculate({
    required String rideType,
    required double distance,
    required double duration,
    double surgeFactor = 1.0,
    double discount = 0.0,
  }) {
    // Base fare based on ride type
    double baseFare;
    double perKmRate;
    double perMinuteRate;

    switch (rideType) {
      case 'Premium':
        baseFare = 5.0;
        perKmRate = 2.0;
        perMinuteRate = 0.5;
        break;
      case 'XL':
        baseFare = 7.0;
        perKmRate = 2.5;
        perMinuteRate = 0.6;
        break;
      case 'Standard':
      default:
        baseFare = 2.5;
        perKmRate = 1.2;
        perMinuteRate = 0.25;
        break;
    }

    // Calculate fare components
    final distanceFare = distance * perKmRate;
    final timeFare = duration * perMinuteRate;

    // Apply surge pricing
    final subtotal = (baseFare + distanceFare + timeFare) * surgeFactor;

    // Apply discount
    final afterDiscount = subtotal - discount;

    // Calculate tax (assuming 10% tax)
    final tax = afterDiscount * 0.1;

    // Calculate total
    final totalFare = afterDiscount + tax;

    return FareModel(
      rideType: rideType,
      distance: distance,
      duration: duration,
      baseFare: baseFare,
      distanceFare: distanceFare,
      timeFare: timeFare,
      surgeFactor: surgeFactor,
      discount: discount,
      tax: tax,
      totalFare: totalFare,
    );
  }
}
