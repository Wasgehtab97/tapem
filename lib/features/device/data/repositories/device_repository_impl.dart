// lib/features/device/data/repositories/device_repository_impl.dart

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
    // Wir holen alle Geräte und geben das erste mit passendem Code zurück,
    // oder null, wenn kein Match gefunden wurde.
    final devices = await getDevicesForGym(gymId);
    for (final d in devices) {
      if (d.nfcCode == nfcCode) return d;
    }
    return null;
  }
}
