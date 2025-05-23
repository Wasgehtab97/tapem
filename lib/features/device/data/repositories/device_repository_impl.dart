import '../sources/firestore_device_source.dart';
import '../../domain/models/device.dart';
import '../../domain/repositories/device_repository.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final FirestoreDeviceSource _source;
  DeviceRepositoryImpl(this._source);

  @override
  Future<List<Device>> getDevicesForGym(String gymId) =>
      _source.getDevicesForGym(gymId);

  @override
  Future<void> createDevice(String gymId, Device device) =>
      _source.createDevice(gymId, device);

  @override
  Future<Device?> getDeviceByNfcCode(String gymId, String nfcCode) async {
    final devices = await getDevicesForGym(gymId);
    try {
      return devices.firstWhere((d) => d.nfcCode == nfcCode);
    } catch (_) {
      return null;
    }
  }
}
