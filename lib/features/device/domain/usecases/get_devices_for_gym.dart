// lib/features/device/domain/usecases/get_devices_for_gym.dart
import '../models/device.dart';
import '../repositories/device_repository.dart';

class GetDevicesForGym {
  final DeviceRepository _repository;
  GetDevicesForGym(this._repository);

  Future<List<Device>> execute(String gymId) async {
    return await _repository.getDevices(gymId);
  }
}
