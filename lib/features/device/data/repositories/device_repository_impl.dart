import 'package:tapem/features/device/data/dtos/device_dto.dart';
import 'package:tapem/features/device/data/sources/firestore_device_source.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final FirestoreDeviceSource _source;
  DeviceRepositoryImpl(this._source);

  @override
  Future<List<Device>> getDevicesForGym(String gymId) async {
    final dtos = await _source.getDevicesForGym(gymId);
    return dtos.map((dto) => Device(
      id: dto.id,
      name: dto.name,
      description: dto.description,
      nfcCode: dto.nfcCode,
    )).toList();
  }

  @override
  Future<void> createDevice(String gymId, Device device) async {
    final dto = DeviceDto(
      id: device.id,
      name: device.name,
      description: device.description,
      nfcCode: device.nfcCode,
    );
    await _source.createDevice(gymId, dto);
  }

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
