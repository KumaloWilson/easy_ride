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
  final String ownerId;
  final HireVehicleStatus status;
  final HireVehicleType hireType;
  final double hourlyRate;
  final double dailyRate;
  final bool selfDriveAvailable;
  final List<String> features;
  final double rating;
  final int ratingCount;
  final String? currentHireId;
  final DateTime lastMaintenance;
  final int totalHires;
  final String? assignedDriverId;
  final String licensePlate;
  final String registrationNumber;
  final DateTime registrationExpiry;
  final String insuranceNumber;
  final DateTime insuranceExpiry;
  final List<String> imageUrls;
  final String description;
  final int passengerCapacity;
  final int luggageCapacity;
  final bool airConditioned;
  final String fuelType;
  final String transmissionType;

  HireVehicleModel({
    required String id,
    required String make,
    required String model,
    required String year,
    required String color,
    required this.licensePlate,
    required String vehicleType,
    required int capacity,
    required List<String> vehicleFeatures,
    required String photoUrl,
    required this.ownerId,
    required this.status,
    required this.hireType,
    required this.hourlyRate,
    required this.dailyRate,
    this.selfDriveAvailable = false,
    required this.features,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.currentHireId,
    required this.lastMaintenance,
    this.totalHires = 0,
    this.assignedDriverId,
    required this.registrationNumber,
    required this.registrationExpiry,
    required this.insuranceNumber,
    required this.insuranceExpiry,
    required this.imageUrls,
    required this.description,
    required this.passengerCapacity,
    required this.luggageCapacity,
    required this.airConditioned,
    required this.fuelType,
    required this.transmissionType,
  }) : super(
          id: id,
          make: make,
          model: model,
          year: year,
          color: color,
          licensePlate: licensePlate,
          vehicleType: vehicleType,
          capacity: capacity,
          features: vehicleFeatures,
          photoUrl: photoUrl,
        );

  factory HireVehicleModel.fromJson(Map<String, dynamic> json) {
    return HireVehicleModel(
      id: json['id'] as String,
      make: json['make'] as String,
      model: json['model'] as String,
      year: json['year'] as String,
      color: json['color'] as String,
      licensePlate: json['licensePlate'] as String,
      vehicleType: json['vehicleType'] as String,
      capacity: json['capacity'] as int,
      vehicleFeatures: List<String>.from(json['features'] as List),
      photoUrl: json['photoUrl'] as String,
      ownerId: json['ownerId'] as String,
      status: HireVehicleStatus.values.firstWhere(
        (e) => e.toString() == 'HireVehicleStatus.${json['status']}',
        orElse: () => HireVehicleStatus.offline,
      ),
      hireType: HireVehicleType.values.firstWhere(
        (e) => e.toString() == 'HireVehicleType.${json['hireType']}',
        orElse: () => HireVehicleType.car,
      ),
      hourlyRate: (json['hourlyRate'] as num).toDouble(),
      dailyRate: (json['dailyRate'] as num).toDouble(),
      selfDriveAvailable: json['selfDriveAvailable'] as bool? ?? false,
      features: List<String>.from(json['hireFeatures'] as List? ?? []),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['ratingCount'] as int? ?? 0,
      currentHireId: json['currentHireId'] as String?,
      lastMaintenance: (json['lastMaintenance'] as Timestamp).toDate(),
      totalHires: json['totalHires'] as int? ?? 0,
      assignedDriverId: json['assignedDriverId'] as String?,
      registrationNumber: json['registrationNumber'] as String,
      registrationExpiry: (json['registrationExpiry'] as Timestamp).toDate(),
      insuranceNumber: json['insuranceNumber'] as String,
      insuranceExpiry: (json['insuranceExpiry'] as Timestamp).toDate(),
      imageUrls: List<String>.from(json['imageUrls'] as List? ?? []),
      description: json['description'] as String? ?? '',
      passengerCapacity: json['passengerCapacity'] as int? ?? 4,
      luggageCapacity: json['luggageCapacity'] as int? ?? 2,
      airConditioned: json['airConditioned'] as bool? ?? true,
      fuelType: json['fuelType'] as String? ?? 'Petrol',
      transmissionType: json['transmissionType'] as String? ?? 'Automatic',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'ownerId': ownerId,
      'status': status.toString().split('.').last,
      'hireType': hireType.toString().split('.').last,
      'hourlyRate': hourlyRate,
      'dailyRate': dailyRate,
      'selfDriveAvailable': selfDriveAvailable,
      'hireFeatures': features,
      'rating': rating,
      'ratingCount': ratingCount,
      'currentHireId': currentHireId,
      'lastMaintenance': Timestamp.fromDate(lastMaintenance),
      'totalHires': totalHires,
      'assignedDriverId': assignedDriverId,
      'registrationNumber': registrationNumber,
      'registrationExpiry': Timestamp.fromDate(registrationExpiry),
      'insuranceNumber': insuranceNumber,
      'insuranceExpiry': Timestamp.fromDate(insuranceExpiry),
      'imageUrls': imageUrls,
      'description': description,
      'passengerCapacity': passengerCapacity,
      'luggageCapacity': luggageCapacity,
      'airConditioned': airConditioned,
      'fuelType': fuelType,
      'transmissionType': transmissionType,
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
      vehicleFeatures: vehicleFeatures ?? this.features,
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
}
