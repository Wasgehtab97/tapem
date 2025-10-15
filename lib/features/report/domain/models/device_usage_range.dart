enum DeviceUsageRange { last7Days, last30Days, last90Days, last365Days, all }

extension DeviceUsageRangeX on DeviceUsageRange {
  String get rangeKey {
    switch (this) {
      case DeviceUsageRange.last7Days:
        return 'last7Days';
      case DeviceUsageRange.last30Days:
        return 'last30Days';
      case DeviceUsageRange.last90Days:
        return 'last90Days';
      case DeviceUsageRange.last365Days:
        return 'last365Days';
      case DeviceUsageRange.all:
        return 'all';
    }
  }
}
