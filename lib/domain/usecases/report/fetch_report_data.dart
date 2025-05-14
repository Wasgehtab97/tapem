// lib/domain/usecases/report/fetch_report_data.dart

import 'package:tapem/domain/models/report_entry.dart';
import 'package:tapem/domain/repositories/report_repository.dart';

/// Use-Case: Holt Report-Daten für ein Gym (optional gefiltert nach Gerät und Zeitraum).
/// 
/// - [gymId]: ID des Gyms.
/// - [deviceId]: Optional: nur für dieses Gerät.
/// - [start]: Optionaler Start-Zeitpunkt.
/// - [end]: Optionales Ende.
/// - Rückgabe: Liste von [ReportEntry].
class FetchReportDataUseCase {
  final ReportRepository _repository;

  FetchReportDataUseCase(this._repository);

  Future<List<ReportEntry>> call({
    required String gymId,
    String? deviceId,
    DateTime? start,
    DateTime? end,
  }) async {
    return await _repository.fetchReportData(
      gymId: gymId,
      deviceId: deviceId,
      start: start,
      end: end,
    );
  }
}
