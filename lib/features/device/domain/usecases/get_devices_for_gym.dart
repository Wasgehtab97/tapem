// lib/features/device/domain/usecases/get_devices_for_gym.dart

import '../models/device.dart';
import '../repositories/device_repository.dart';

/// UseCase zum Laden aller Geräte einer Gym.
class GetDevicesForGym {
  final DeviceRepository _repo;
  GetDevicesForGym(this._repo);

  Future<List<Device>> execute(String gymId) {
    return _repo.getDevicesForGym(gymId);
  }
}
