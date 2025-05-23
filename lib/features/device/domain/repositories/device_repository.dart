// lib/features/device/domain/repositories/device_repository.dart

import '../models/device.dart';

/// Abstraktion über die Firestore-Source
abstract class DeviceRepository {
  /// Alle Geräte zu einem Gym laden
  Future<List<Device>> getDevicesForGym(String gymId);

  /// Neues Gerät anlegen (inkl. nfcCode)
  Future<void> createDevice(String gymId, Device device);

  /// Ein Gerät per nfcCode suchen
  Future<Device?> getDeviceByNfcCode(String gymId, String nfcCode);
}
