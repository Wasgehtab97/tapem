import 'package:tapem/domain/models/device_model.dart';
import 'package:tapem/domain/repositories/device_repository.dart';
import 'package:tapem/data/sources/device/firestore_device_source.dart';

/// Firestore-Implementierung von [DeviceRepository].
class DeviceRepositoryImpl implements DeviceRepository {
  final FirestoreDeviceSource _source;
  DeviceRepositoryImpl({FirestoreDeviceSource? source})
      : _source = source ?? FirestoreDeviceSource();

  @override
  Future<String> registerDevice({
    required String name,
    required String exerciseMode,
  }) {
    return _source.createDevice(name: name, exerciseMode: exerciseMode);
  }

  @override
  Future<void> updateDevice({
    required String documentId,
    required String name,
    required String exerciseMode,
    required String secretCode,
  }) {
    return _source.updateDevice(
      documentId: documentId,
      name: name,
      exerciseMode: exerciseMode,
      secretCode: secretCode,
    );
  }

  @override
  Future<List<DeviceModel>> loadAllDevices() {
    return _source.getAllDevices();
  }
}
