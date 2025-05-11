import '../../models/dto/gym_config_dto.dart';

/// Abstrakte Schnittstelle zum Laden der Gym-Konfiguration.
abstract class TenantRepository {
  /// Lädt die Konfiguration für das gegebene Gym.
  Future<GymConfigDto> fetchConfig(String gymId);
}
