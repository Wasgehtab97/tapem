// lib/features/device/data/repositories/device_repository_impl.dart
import 'package:tapem/features/device/data/sources/firestore_device_source.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final FirestoreDeviceSource _source;
  DeviceRepositoryImpl(this._source);

  @override
  Future<List<Device>> getDevices(String gymId) async {
    final dtos = await _source.getDevicesForGym(gymId);
    return dtos
        .map((dto) => Device(
              id: dto.id,
              name: dto.name,
              description: dto.description,
            ))
        .toList();
  }
}
