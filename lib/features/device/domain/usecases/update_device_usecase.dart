import '../models/device.dart';
import '../repositories/device_repository.dart';

class UpdateDeviceUseCase {
  final DeviceRepository _repository;

  UpdateDeviceUseCase(this._repository);

  Future<void> execute({
    required String gymId,
    required Device device,
  }) async {
    return _repository.updateDevice(gymId, device);
  }
}
