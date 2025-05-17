enum RideStatus {
  requested,
  searching,
  accepted,
  driverArrived,
  inProgress,
  completed,
  cancelled,
  noDriverFound
}

extension RideStatusExtension on RideStatus {
  String get displayName {
    switch (this) {
      case RideStatus.requested:
        return 'Requested';
      case RideStatus.searching:
        return 'Finding Driver';
      case RideStatus.accepted:
        return 'Driver Accepted';
      case RideStatus.driverArrived:
        return 'Driver Arrived';
      case RideStatus.inProgress:
        return 'In Progress';
      case RideStatus.completed:
        return 'Completed';
      case RideStatus.cancelled:
        return 'Cancelled';
      case RideStatus.noDriverFound:
        return 'No Driver Found';
      default:
        return 'Unknown';
    }
  }

  bool get isActive {
    return this == RideStatus.requested ||
        this == RideStatus.searching ||
        this == RideStatus.accepted ||
        this == RideStatus.driverArrived ||
        this == RideStatus.inProgress;
  }

  bool get isCompleted {
    return this == RideStatus.completed;
  }

  bool get isCancelled {
    return this == RideStatus.cancelled || this == RideStatus.noDriverFound;
  }
}
