// lib/features/report/domain/models/device_usage_stat.dart

/// Aggregated usage information for a single device on the report screen.
class DeviceUsageStat {
  final String id;
  final String name;
  final String description;
  final int sessions;

  const DeviceUsageStat({
    required this.id,
    required this.name,
    this.description = '',
    required this.sessions,
  });
}
