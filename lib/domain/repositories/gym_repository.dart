// lib/domain/repositories/gym_repository.dart

import '../models/device_model.dart';

/// Schnittstelle zum Laden der Geräteübersicht im Gym.
abstract class GymRepository {
  /// Holt alle Geräte, optional gefiltert nach [nameQuery].
  Future<List<DeviceModel>> fetchDevices({String? nameQuery});
}
