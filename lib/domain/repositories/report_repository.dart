// lib/domain/repositories/report_repository.dart

import '../models/device_info.dart';
import '../models/report_entry.dart';

/// Schnittstelle für Reporting-Feature.
abstract class ReportRepository {
  /// Holt alle Geräte im Gym [gymId].
  Future<List<DeviceInfo>> fetchDevices(String gymId);

  /// Holt den Feedback-Status je Gerät.
  Future<Map<String, String>> fetchFeedbackStatus(String gymId);

  /// Holt Report-Daten im Zeitraum.
  Future<List<ReportEntry>> fetchReportData({
    required String gymId,
    String? deviceId,
    DateTime? start,
    DateTime? end,
  });
}
