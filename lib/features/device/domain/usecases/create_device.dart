import '../models/device.dart';
import '../repositories/device_repository.dart';

class CreateDeviceUseCase {
  final DeviceRepository _repo;
  CreateDeviceUseCase(this._repo);

  Future<void> execute(String gymId, Device device) =>
    _repo.createDevice(gymId, device);
}
