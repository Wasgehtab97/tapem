// lib/features/device/data/repositories/device_repository_impl.dart

import '../dtos/device_dto.dart';
import '../sources/firestore_device_source.dart';
import '../../domain/models/device.dart';
import '../../domain/repositories/device_repository.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final FirestoreDeviceSource _source;
  DeviceRepositoryImpl(this._source);

  @override
  Future<List<Device>> getDevicesForGym(String gymId) async {
    final dtos = await _source.getDevicesForGym(gymId);
    return dtos.map((dto) => dto.toModel()).toList();
  }

  @override
  Future<void> createDevice(String gymId, Device device) {
    return _source.createDevice(gymId, device);
  }

  @override
  Future<Device?> getDeviceByNfcCode(String gymId, String nfcCode) async {
    final all = await getDevicesForGym(gymId);
    try {
      return all.firstWhere((d) => d.nfcCode == nfcCode);
    } catch (_) {
      return null;
    }
  }

  // Neu: Gerät löschen
  @override
  Future<void> deleteDevice(String gymId, String deviceId) {
    return _source.deleteDevice(gymId, deviceId);
  }
}
