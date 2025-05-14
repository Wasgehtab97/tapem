// lib/domain/usecases/admin/fetch_devices.dart

import 'package:tapem/domain/models/device_model.dart';
import 'package:tapem/domain/repositories/admin_repository.dart';

/// UseCase zum Laden aller Geräte (Admin).
class FetchDevicesUseCase {
  final AdminRepository _repository;

  FetchDevicesUseCase(this._repository);

  /// Holt und liefert die Liste aller [DeviceModel].
  Future<List<DeviceModel>> call() async {
    return await _repository.fetchDevices();
  }
}
