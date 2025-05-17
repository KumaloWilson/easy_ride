import 'package:flutter/material.dart';

enum RideStatus {
  pending,
  requested,
  accepted,
  arrived,
  inProgress,
  completed,
  cancelled
}

extension RideStatusExtension on RideStatus {
  String get displayName {
    switch (this) {
      case RideStatus.pending:
        return 'Pending';
      case RideStatus.requested:
        return 'Requested';
      case RideStatus.accepted:
        return 'Accepted';
      case RideStatus.arrived:
        return 'Driver Arrived';
      case RideStatus.inProgress:
        return 'In Progress';
      case RideStatus.completed:
        return 'Completed';
      case RideStatus.cancelled:
        return 'Cancelled';
    }
  }
  
  Color get color {
    switch (this) {
      case RideStatus.pending:
      case RideStatus.requested:
        return Colors.orange;
      case RideStatus.accepted:
        return Colors.blue;
      case RideStatus.arrived:
        return Colors.teal;
      case RideStatus.inProgress:
        return Colors.purple;
      case RideStatus.completed:
        return Colors.green;
      case RideStatus.cancelled:
        return Colors.red;
    }
  }
}
