// lib/domain/usecases/report/fetch_report_devices.dart

import 'package:tapem/domain/models/device_info.dart';
import 'package:tapem/domain/repositories/report_repository.dart';

/// Use-Case: Holt alle Geräte für einen bestimmten Gym.
/// 
/// - [gymId]: ID des Gyms, für das die Geräte geladen werden.
/// - Rückgabe: Liste von [DeviceInfo].
class FetchReportDevicesUseCase {
  final ReportRepository _repository;

  FetchReportDevicesUseCase(this._repository);

  Future<List<DeviceInfo>> call(String gymId) async {
    return await _repository.fetchDevices(gymId);
  }
}
