// lib/features/report/domain/models/device_usage_range.dart

/// Auswahl an Zeiträumen für die Gerätestatistiken im Report.
enum DeviceUsageRange { last7Days, last30Days, last90Days, last365Days, all }

extension DeviceUsageRangeX on DeviceUsageRange {
  /// Liefert das Startdatum für die entsprechende Filterung.
  DateTime? resolveSince(DateTime now) {
    switch (this) {
      case DeviceUsageRange.last7Days:
        return now.subtract(const Duration(days: 7));
      case DeviceUsageRange.last30Days:
        return now.subtract(const Duration(days: 30));
      case DeviceUsageRange.last90Days:
        return now.subtract(const Duration(days: 90));
      case DeviceUsageRange.last365Days:
        return now.subtract(const Duration(days: 365));
      case DeviceUsageRange.all:
        return null;
    }
  }

  /// Key, der in aggregierten Statistik-Dokumenten verwendet werden kann.
  String get storageKey {
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
