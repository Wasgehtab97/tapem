// lib/features/device/domain/usecases/delete_device_usecase.dart

import '../repositories/device_repository.dart';

class DeleteDeviceUseCase {
  final DeviceRepository _repo;

  DeleteDeviceUseCase(this._repo);

  /// Löscht ein Gerät in Firestore
  Future<void> execute({required String gymId, required String deviceId}) {
    return _repo.deleteDevice(gymId, deviceId);
  }
}
