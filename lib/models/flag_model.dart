import 'package:cloud_firestore/cloud_firestore.dart';

enum FlagType {
  fraud,
  safety,
  inappropriate,
  spam,
  conduct,
  other,
}

enum FlagStatus {
  pending,
  inProgress,
  resolved,
  dismissed,
}

class FlagModel {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final String? rideId;
  final FlagType type;
  final String reason;
  final List<String>? evidence;
  final FlagStatus status;
  final String? adminResponse;
  final String? adminId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  FlagModel({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    this.rideId,
    required this.type,
    required this.reason,
    this.evidence,
    required this.status,
    this.adminResponse,
    this.adminId,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
  });

  factory FlagModel.fromMap(Map<String, dynamic> map, String id) {
    return FlagModel(
      id: id,
      reporterId: map['reporterId'] ?? '',
      reportedUserId: map['reportedUserId'] ?? '',
      rideId: map['rideId'],
      type: _stringToFlagType(map['type'] ?? 'other'),
      reason: map['reason'] ?? '',
      evidence: map['evidence'] != null ? List<String>.from(map['evidence']) : null,
      status: _stringToFlagStatus(map['status'] ?? 'pending'),
      adminResponse: map['adminResponse'],
      adminId: map['adminId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
      resolvedAt: map['resolvedAt'] != null ? (map['resolvedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'rideId': rideId,
      'type': _flagTypeToString(type),
      'reason': reason,
      'evidence': evidence,
      'status': _flagStatusToString(status),
      'adminResponse': adminResponse,
      'adminId': adminId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }

  static FlagType _stringToFlagType(String type) {
    switch (type) {
      case 'fraud':
        return FlagType.fraud;
      case 'safety':
        return FlagType.safety;
      case 'inappropriate':
        return FlagType.inappropriate;
      case 'spam':
        return FlagType.spam;
      case 'other':
        return FlagType.other;
      default:
        return FlagType.other;
    }
  }

  static String _flagTypeToString(FlagType type) {
    switch (type) {
      case FlagType.fraud:
        return 'fraud';
      case FlagType.safety:
        return 'safety';
      case FlagType.inappropriate:
        return 'inappropriate';
      case FlagType.spam:
        return 'spam';
      case FlagType.conduct:
        return 'conduct';
      case FlagType.other:
        return 'other';
    }
  }

  static FlagStatus _stringToFlagStatus(String status) {
    switch (status) {
      case 'pending':
        return FlagStatus.pending;
      case 'inProgress':
        return FlagStatus.inProgress;
      case 'resolved':
        return FlagStatus.resolved;
      case 'dismissed':
        return FlagStatus.dismissed;
      default:
        return FlagStatus.pending;
    }
  }

  static String _flagStatusToString(FlagStatus status) {
    switch (status) {
      case FlagStatus.pending:
        return 'pending';
      case FlagStatus.inProgress:
        return 'inProgress';
      case FlagStatus.resolved:
        return 'resolved';
      case FlagStatus.dismissed:
        return 'dismissed';
    }
  }
}
