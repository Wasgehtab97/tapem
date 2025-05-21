// lib/features/device/domain/repositories/device_repository.dart
import '../models/device.dart';

/// Liefert alle Geräte eines Gyms
abstract class DeviceRepository {
  Future<List<Device>> getDevices(String gymId);
}
