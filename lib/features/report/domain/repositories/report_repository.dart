// lib/features/report/domain/repositories/report_repository.dart

import '../models/device_usage_stat.dart';
import '../models/device_usage_range.dart';

abstract class ReportRepository {
  /// Gibt aggregierte Nutzungsstatistiken für alle Geräte eines Gyms zurück.
  Future<List<DeviceUsageStat>> fetchDeviceUsageStats(
    String gymId,
    DeviceUsageRange range, {
    bool forceRefresh = false,
  });

  /// Liefert alle Log-Timestamps (über alle Geräte) für den Heatmap.
  Future<List<DateTime>> fetchRecentLogTimestamps(
    String gymId, {
    bool forceRefresh = false,
  });
}
