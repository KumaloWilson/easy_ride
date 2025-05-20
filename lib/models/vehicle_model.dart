class VehicleModel {
  final String id;
  final String make;
  final String model;
  final String year;
  final String color;
  final String licensePlate;
  final String vehicleType; // sedan, suv, etc.
  final int capacity;
  final List<String> features; // AC, wheelchair accessible, etc.
  final List<String>  photos;

  VehicleModel({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.licensePlate,
    required this.vehicleType,
    required this.capacity,
    required this.features,
    required this.photos,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String,
      make: json['make'] as String,
      model: json['model'] as String,
      year: json['year'] as String,
      color: json['color'] as String,
      licensePlate: json['licensePlate'] as String,
      vehicleType: json['vehicleType'] as String,
      capacity: json['capacity'] as int,
      features: List<String>.from(json['features'] as List),
      photos: List<String>.from(json['photos'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'licensePlate': licensePlate,
      'vehicleType': vehicleType,
      'capacity': capacity,
      'features': features,
      'photos': photos,
    };
  }
}
