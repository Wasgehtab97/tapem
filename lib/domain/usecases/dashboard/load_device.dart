// lib/domain/usecases/dashboard/load_device.dart

import 'package:tapem/domain/models/dashboard_data.dart';
import 'package:tapem/domain/repositories/dashboard_repository.dart';

/// UseCase zum Laden des Gerätekontexts und zugehörigem Plan.
///
/// [deviceId]   – ID des Geräts  
/// [secretCode] – Optionaler Geheimcode für den Zugriff
class LoadDeviceUseCase {
  final DashboardRepository _repository;

  LoadDeviceUseCase(this._repository);

  Future<DashboardData> call({
    required String deviceId,
    String? secretCode,
  }) async {
    return await _repository.loadDevice(
      deviceId,
      secretCode: secretCode,
    );
  }
}
