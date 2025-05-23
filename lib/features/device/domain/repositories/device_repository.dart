// lib/features/device/domain/repositories/device_repository.dart
import '../models/device.dart';

abstract class DeviceRepository {
  Future<List<Device>> getDevicesForGym(String gymId);
  Future<void> createDevice(String gymId, Device device);
  Future<Device?> getDeviceByNfcCode(String gymId, String nfcCode);
}
