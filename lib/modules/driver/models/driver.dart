enum DriverStatus {
  offline,
  online,
  busy,
  onBreak
}

extension DriverStatusExtension on DriverStatus {
  String get displayName {
    switch (this) {
      case DriverStatus.offline:
        return 'Offline';
      case DriverStatus.online:
        return 'Online';
      case DriverStatus.busy:
        return 'Busy';
      case DriverStatus.onBreak:
        return 'On Break';
      default:
        return 'Unknown';
    }
  }

  bool get isAvailable {
    return this == DriverStatus.online;
  }
}
