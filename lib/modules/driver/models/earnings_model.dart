import 'package:cloud_firestore/cloud_firestore.dart';

class EarningsModel {
  final String id;
  final String driverId;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final int totalRides;
  final double totalHours;
  final double totalDistance;
  final bool isPaid;
  final DateTime? paidDate;
  final String? paymentMethod;
  final String? transactionId;
  final DateTime createdAt;

  EarningsModel({
    required this.id,
    required this.driverId,
    required this.amount,
    required this.startDate,
    required this.endDate,
    required this.totalRides,
    required this.totalHours,
    required this.totalDistance,
    required this.isPaid,
    this.paidDate,
    this.paymentMethod,
    this.transactionId,
    required this.createdAt,
  });

  factory EarningsModel.fromMap(Map<String, dynamic> map, String id) {
    return EarningsModel(
      id: id,
      driverId: map['driverId'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      totalRides: map['totalRides'] ?? 0,
      totalHours: map['totalHours']?.toDouble() ?? 0.0,
      totalDistance: map['totalDistance']?.toDouble() ?? 0.0,
      isPaid: map['isPaid'] ?? false,
      paidDate: map['paidDate'] != null ? (map['paidDate'] as Timestamp).toDate() : null,
      paymentMethod: map['paymentMethod'],
      transactionId: map['transactionId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'amount': amount,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalRides': totalRides,
      'totalHours': totalHours,
      'totalDistance': totalDistance,
      'isPaid': isPaid,
      'paidDate': paidDate != null ? Timestamp.fromDate(paidDate!) : null,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class PayoutRequestModel {
  final String id;
  final String driverId;
  final double amount;
  final String status; // 'pending', 'approved', 'rejected', 'completed'
  final String paymentMethod; // 'bank', 'paypal', 'upi', etc.
  final Map<String, dynamic> paymentDetails;
  final String? notes;
  final DateTime requestDate;
  final DateTime? processedDate;
  final String? adminId;

  PayoutRequestModel({
    required this.id,
    required this.driverId,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.paymentDetails,
    this.notes,
    required this.requestDate,
    this.processedDate,
    this.adminId,
  });

  factory PayoutRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return PayoutRequestModel(
      id: id,
      driverId: map['driverId'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending',
      paymentMethod: map['paymentMethod'] ?? '',
      paymentDetails: map['paymentDetails'] ?? {},
      notes: map['notes'],
      requestDate: (map['requestDate'] as Timestamp).toDate(),
      processedDate: map['processedDate'] != null ? (map['processedDate'] as Timestamp).toDate() : null,
      adminId: map['adminId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'amount': amount,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentDetails': paymentDetails,
      'notes': notes,
      'requestDate': Timestamp.fromDate(requestDate),
      'processedDate': processedDate != null ? Timestamp.fromDate(processedDate!) : null,
      'adminId': adminId,
    };
  }
}
