import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_ride/models/vehicle_model.dart';

enum HireVehicleStatus {
  available,
  hired,
  maintenance,
  offline
}

enum HireVehicleType {
  car,
  van,
  luxury,
  suv
}

class HireVehicleModel extends VehicleModel {
  final String? ownerId;
  final HireVehicleStatus? status;
  final HireVehicleType? hireType;
  final double? hourlyRate;
  final double? dailyRate;
  final bool? selfDriveAvailable;
  final List<String> features;
  final double? rating;
  final int? ratingCount;
  final String? currentHireId;
  final DateTime? lastMaintenance;
  final int? totalHires;
  final String? assignedDriverId;
  final String licensePlate;
  final String? registrationNumber;
  final DateTime? registrationExpiry;
  final String? insuranceNumber;
  final DateTime? insuranceExpiry;
  final List<String>? imageUrls;
  final String? description;
  final int? passengerCapacity;
  final int? luggageCapacity;
  final bool? airConditioned;
  final String? fuelType;
  final String? transmissionType;

  HireVehicleModel({
    required super.id,
    required super.make,
    required super.model,
    required super.year,
    required super.color,
    required this.licensePlate,  // Must be required since it's non-nullable
    required super.vehicleType,
    required super.capacity,
    required List<String> vehicleFeatures,  // Must be required since it's non-nullable
    required super.photoUrl,
    this.ownerId,
    this.status,
    this.hireType,
    this.hourlyRate,
    this.dailyRate,
    this.selfDriveAvailable,
    required this.features,  // Must be required since it's non-nullable
    this.rating,
    this.ratingCount,
    this.currentHireId,
    this.lastMaintenance,
    this.totalHires,
    this.assignedDriverId,
    this.registrationNumber,
    this.registrationExpiry,
    this.insuranceNumber,
    this.insuranceExpiry,
    this.imageUrls,
    this.description,
    this.passengerCapacity,
    this.luggageCapacity,
    this.airConditioned,
    this.fuelType,
    this.transmissionType,
  }) : super(
    licensePlate: licensePlate,
    features: vehicleFeatures,
  );

  factory HireVehicleModel.fromJson(Map<String, dynamic> json) {
    return HireVehicleModel(
      id: json['id'] as String? ?? '',
      make: json['make'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: json['year'] as String? ?? '',
      color: json['color'] as String? ?? '',
      licensePlate: json['licensePlate'] as String? ?? '',  // Provide default for non-nullable property
      vehicleType: json['vehicleType'] as String? ?? '',
      capacity: json['capacity'] as int? ?? 0,
      vehicleFeatures: json['features'] != null
          ? List<String>.from(json['features'] as List)
          : [],  // Default empty list for non-nullable property
      photoUrl: json['photoUrl'] as String? ?? '',
      ownerId: json['ownerId'] as String?,
      status: json['status'] != null
          ? HireVehicleStatus.values.firstWhere(
            (e) => e.toString() == 'HireVehicleStatus.${json['status']}',
        orElse: () => HireVehicleStatus.offline,
      )
          : HireVehicleStatus.offline,
      hireType: json['hireType'] != null
          ? HireVehicleType.values.firstWhere(
            (e) => e.toString() == 'HireVehicleType.${json['hireType']}',
        orElse: () => HireVehicleType.car,
      )
          : HireVehicleType.car,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      dailyRate: (json['dailyRate'] as num?)?.toDouble() ?? 0.0,
      selfDriveAvailable: json['selfDriveAvailable'] as bool?,
      features: json['hireFeatures'] != null
          ? List<String>.from(json['hireFeatures'] as List)
          : [],  // Default empty list for non-nullable property
      rating: (json['rating'] as num?)?.toDouble(),
      ratingCount: json['ratingCount'] as int?,
      currentHireId: json['currentHireId'] as String?,
      lastMaintenance: json['lastMaintenance'] != null
          ? (json['lastMaintenance'] as Timestamp).toDate()
          : DateTime.now(),
      totalHires: json['totalHires'] as int?,
      assignedDriverId: json['assignedDriverId'] as String?,
      registrationNumber: json['registrationNumber'] as String?,
      registrationExpiry: json['registrationExpiry'] != null
          ? (json['registrationExpiry'] as Timestamp).toDate()
          : DateTime.now(),
      insuranceNumber: json['insuranceNumber'] as String?,
      insuranceExpiry: json['insuranceExpiry'] != null
          ? (json['insuranceExpiry'] as Timestamp).toDate()
          : DateTime.now(),
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'] as List)
          : [],
      description: json['description'] as String?,
      passengerCapacity: json['passengerCapacity'] as int?,
      luggageCapacity: json['luggageCapacity'] as int?,
      airConditioned: json['airConditioned'] as bool?,
      fuelType: json['fuelType'] as String?,
      transmissionType: json['transmissionType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'ownerId': ownerId ?? '',
      'status': status?.toString().split('.').last ?? HireVehicleStatus.offline.toString().split('.').last,
      'hireType': hireType?.toString().split('.').last ?? HireVehicleType.car.toString().split('.').last,
      'hourlyRate': hourlyRate ?? 0.0,
      'dailyRate': dailyRate ?? 0.0,
      'selfDriveAvailable': selfDriveAvailable ?? false,
      'hireFeatures': features ?? [],
      'rating': rating ?? 0.0,
      'ratingCount': ratingCount ?? 0,
      'currentHireId': currentHireId,
      'lastMaintenance': lastMaintenance != null
          ? Timestamp.fromDate(lastMaintenance!)
          : Timestamp.fromDate(DateTime.now()),
      'totalHires': totalHires ?? 0,
      'assignedDriverId': assignedDriverId,
      'registrationNumber': registrationNumber ?? '',
      'registrationExpiry': registrationExpiry != null
          ? Timestamp.fromDate(registrationExpiry!)
          : Timestamp.fromDate(DateTime.now()),
      'insuranceNumber': insuranceNumber ?? '',
      'insuranceExpiry': insuranceExpiry != null
          ? Timestamp.fromDate(insuranceExpiry!)
          : Timestamp.fromDate(DateTime.now()),
      'imageUrls': imageUrls ?? [],
      'description': description ?? '',
      'passengerCapacity': passengerCapacity ?? 4,
      'luggageCapacity': luggageCapacity ?? 2,
      'airConditioned': airConditioned ?? true,
      'fuelType': fuelType ?? 'Petrol',
      'transmissionType': transmissionType ?? 'Automatic',
    };
  }

  HireVehicleModel copyWith({
    String? id,
    String? make,
    String? model,
    String? year,
    String? color,
    String? licensePlate,
    String? vehicleType,
    int? capacity,
    List<String>? vehicleFeatures,
    String? photoUrl,
    String? ownerId,
    HireVehicleStatus? status,
    HireVehicleType? hireType,
    double? hourlyRate,
    double? dailyRate,
    bool? selfDriveAvailable,
    List<String>? features,
    double? rating,
    int? ratingCount,
    String? currentHireId,
    DateTime? lastMaintenance,
    int? totalHires,
    String? assignedDriverId,
    String? registrationNumber,
    DateTime? registrationExpiry,
    String? insuranceNumber,
    DateTime? insuranceExpiry,
    List<String>? imageUrls,
    String? description,
    int? passengerCapacity,
    int? luggageCapacity,
    bool? airConditioned,
    String? fuelType,
    String? transmissionType,
  }) {
    return HireVehicleModel(
      id: id ?? this.id,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      licensePlate: licensePlate ?? this.licensePlate,
      vehicleType: vehicleType ?? this.vehicleType,
      capacity: capacity ?? this.capacity,
      vehicleFeatures: vehicleFeatures ?? this.features,  // Use features here
      photoUrl: photoUrl ?? this.photoUrl,
      ownerId: ownerId ?? this.ownerId,
      status: status ?? this.status,
      hireType: hireType ?? this.hireType,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      dailyRate: dailyRate ?? this.dailyRate,
      selfDriveAvailable: selfDriveAvailable ?? this.selfDriveAvailable,
      features: features ?? this.features,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      currentHireId: currentHireId ?? this.currentHireId,
      lastMaintenance: lastMaintenance ?? this.lastMaintenance,
      totalHires: totalHires ?? this.totalHires,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      registrationExpiry: registrationExpiry ?? this.registrationExpiry,
      insuranceNumber: insuranceNumber ?? this.insuranceNumber,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      imageUrls: imageUrls ?? this.imageUrls,
      description: description ?? this.description,
      passengerCapacity: passengerCapacity ?? this.passengerCapacity,
      luggageCapacity: luggageCapacity ?? this.luggageCapacity,
      airConditioned: airConditioned ?? this.airConditioned,
      fuelType: fuelType ?? this.fuelType,
      transmissionType: transmissionType ?? this.transmissionType,
    );
  }

  // Getter methods with default values for all nullable properties
  String get getOwnerId => ownerId ?? '';
  HireVehicleStatus get getStatus => status ?? HireVehicleStatus.offline;
  HireVehicleType get getHireType => hireType ?? HireVehicleType.car;
  double get getHourlyRate => hourlyRate ?? 0.0;
  double get getDailyRate => dailyRate ?? 0.0;
  bool get getSelfDriveAvailable => selfDriveAvailable ?? false;
  List<String> get getFeatures => features ?? [];
  double get getRating => rating ?? 0.0;
  int get getRatingCount => ratingCount ?? 0;
  String get getCurrentHireId => currentHireId ?? '';
  DateTime get getLastMaintenance => lastMaintenance ?? DateTime.now();
  int get getTotalHires => totalHires ?? 0;
  String get getAssignedDriverId => assignedDriverId ?? '';
  String get getLicensePlate => licensePlate ?? '';
  String get getRegistrationNumber => registrationNumber ?? '';
  DateTime get getRegistrationExpiry => registrationExpiry ?? DateTime.now();
  String get getInsuranceNumber => insuranceNumber ?? '';
  DateTime get getInsuranceExpiry => insuranceExpiry ?? DateTime.now();
  List<String> get getImageUrls => imageUrls ?? [];
  String get getDescription => description ?? '';
  int get getPassengerCapacity => passengerCapacity ?? 4;
  int get getLuggageCapacity => luggageCapacity ?? 2;
  bool get getAirConditioned => airConditioned ?? true;
  String get getFuelType => fuelType ?? 'Petrol';
  String get getTransmissionType => transmissionType ?? 'Automatic';
}