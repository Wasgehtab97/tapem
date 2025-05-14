import 'package:tapem/domain/models/dashboard_data.dart';

/// Schnittstelle für das Dashboard-Feature.
abstract class DashboardRepository {
  /// Lädt Gerätekontext und Plan für Dashboard.
  Future<DashboardData> loadDevice(String deviceId, {String? secretCode});

  /// Fügt einen neuen Datensatz hinzu (z. B. Gewicht/Reps).
  Future<void> addSet({
    required String deviceId,
    required String exercise,
    required int sets,
    required double weight,
    required int reps,
  });

  /// Beendet die aktuelle Session.
  Future<void> finishSession({
    required String deviceId,
    required String exercise,
  });
}
