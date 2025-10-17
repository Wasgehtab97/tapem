// lib/features/report/domain/repositories/report_repository.dart

import '../models/device_usage_stat.dart';

abstract class ReportRepository {
  /// Gibt aggregierte Nutzungsstatistiken für alle Geräte eines Gyms zurück.
  Future<List<DeviceUsageStat>> fetchDeviceUsageStats(
    String gymId, {
    DateTime? since,
  });

  /// Liefert alle Log-Timestamps (über alle Geräte) für den Heatmap.
  Future<List<DateTime>> fetchAllLogTimestamps(
    String gymId, {
    DateTime? since,
  });
}
