import '../models/device.dart';

abstract class DeviceRepository {
  Future<List<Device>> getDevicesForGym(String gymId);
  Future<void> createDevice(String gymId, Device device);

  /// Suche ein einzelnes Gerät per NFC-Code
  Future<Device?> getDeviceByNfcCode(String gymId, String nfcCode);
}
