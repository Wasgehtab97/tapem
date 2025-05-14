// lib/domain/usecases/device/load_devices.dart

import 'package:tapem/domain/models/device_model.dart';
import 'package:tapem/domain/repositories/device_repository.dart';

/// Lädt alle Geräte.
/// Rückgabe: Liste von [DeviceModel].
class LoadDevicesUseCase {
  final DeviceRepository _repository;

  LoadDevicesUseCase(this._repository);

  Future<List<DeviceModel>> call() async {
    return await _repository.loadAllDevices();
  }
}
