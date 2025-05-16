import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedbackType {
  general,
  app,
  driver,
  rider,
  safety,
  payment,
  other,
}

enum FeedbackStatus {
  pending,
  inProgress,
  resolved,
  closed,
}

class FeedbackModel {
  final String id;
  final String userId;
  final String? rideId;
  final String? relatedUserId;
  final FeedbackType type;
  final String title;
  final String description;
  final int rating;
  final List<String>? attachments;
  final FeedbackStatus status;
  final String? adminResponse;
  final String? adminId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  FeedbackModel({
    required this.id,
    required this.userId,
    this.rideId,
    this.relatedUserId,
    required this.type,
    required this.title,
    required this.description,
    required this.rating,
    this.attachments,
    required this.status,
    this.adminResponse,
    this.adminId,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
  });

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedbackModel(
      id: id,
      userId: map['userId'] ?? '',
      rideId: map['rideId'],
      relatedUserId: map['relatedUserId'],
      type: _stringToFeedbackType(map['type'] ?? 'general'),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      rating: map['rating'] ?? 0,
      attachments: map['attachments'] != null ? List<String>.from(map['attachments']) : null,
      status: _stringToFeedbackStatus(map['status'] ?? 'pending'),
      adminResponse: map['adminResponse'],
      adminId: map['adminId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
      resolvedAt: map['resolvedAt'] != null ? (map['resolvedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'rideId': rideId,
      'relatedUserId': relatedUserId,
      'type': _feedbackTypeToString(type),
      'title': title,
      'description': description,
      'rating': rating,
      'attachments': attachments,
      'status': _feedbackStatusToString(status),
      'adminResponse': adminResponse,
      'adminId': adminId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }

  static FeedbackType _stringToFeedbackType(String type) {
    switch (type) {
      case 'general':
        return FeedbackType.general;
      case 'app':
        return FeedbackType.app;
      case 'driver':
        return FeedbackType.driver;
      case 'rider':
        return FeedbackType.rider;
      case 'safety':
        return FeedbackType.safety;
      case 'payment':
        return FeedbackType.payment;
      case 'other':
        return FeedbackType.other;
      default:
        return FeedbackType.general;
    }
  }

  static String _feedbackTypeToString(FeedbackType type) {
    switch (type) {
      case FeedbackType.general:
        return 'general';
      case FeedbackType.app:
        return 'app';
      case FeedbackType.driver:
        return 'driver';
      case FeedbackType.rider:
        return 'rider';
      case FeedbackType.safety:
        return 'safety';
      case FeedbackType.payment:
        return 'payment';
      case FeedbackType.other:
        return 'other';
    }
  }

  static FeedbackStatus _stringToFeedbackStatus(String status) {
    switch (status) {
      case 'pending':
        return FeedbackStatus.pending;
      case 'inProgress':
        return FeedbackStatus.inProgress;
      case 'resolved':
        return FeedbackStatus.resolved;
      case 'closed':
        return FeedbackStatus.closed;
      default:
        return FeedbackStatus.pending;
    }
  }

  static String _feedbackStatusToString(FeedbackStatus status) {
    switch (status) {
      case FeedbackStatus.pending:
        return 'pending';
      case FeedbackStatus.inProgress:
        return 'inProgress';
      case FeedbackStatus.resolved:
        return 'resolved';
      case FeedbackStatus.closed:
        return 'closed';
    }
  }
}
