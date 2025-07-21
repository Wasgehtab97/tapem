// lib/features/device/domain/repositories/device_repository.dart

import '../models/device.dart';

abstract class DeviceRepository {
  Future<List<Device>> getDevicesForGym(String gymId);
  Future<void> createDevice(String gymId, Device device);
  Future<Device?> getDeviceByNfcCode(String gymId, String nfcCode);

  // Neu: Gerät löschen
  Future<void> deleteDevice(String gymId, String deviceId);

  Future<void> updateMuscleGroups(
    String gymId,
    String deviceId,
    List<String> primaryGroups,
    List<String> secondaryGroups,
  );
}
