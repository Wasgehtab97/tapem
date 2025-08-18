// lib/features/report/domain/repositories/report_repository.dart

abstract class ReportRepository {
  /// Gibt pro Geräte-ID die Anzahl aller Logs zurück.
  Future<Map<String, int>> fetchUsageCountPerMachine(String gymId, String userId);

  /// Liefert alle Log-Timestamps (über alle Geräte) für den Heatmap.
  Future<List<DateTime>> fetchAllLogTimestamps(String gymId, String userId);
}
