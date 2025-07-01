import '../models/device.dart';
import '../repositories/device_repository.dart';

class GetDeviceByNfcCode {
  final DeviceRepository _repo;
  GetDeviceByNfcCode(this._repo);

  Future<Device?> execute(String gymId, String nfcCode) =>
    _repo.getDeviceByNfcCode(gymId, nfcCode);
}
