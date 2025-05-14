// lib/domain/repositories/tenant_repository.dart

import '../models/tenant.dart';
import '../models/gym_config.dart';

/// Schnittstelle für Tenant-Kontext.
abstract class TenantRepository {
  /// Holt alle Gyms.
  Future<List<Tenant>> fetchAllTenants();

  /// Gibt die zuletzt ausgewählte Gym-ID zurück (oder null).
  Future<String?> getSavedGymId();

  /// Wechselt auf den neuen Tenant und lädt seine Config.
  Future<void> switchTenant(String gymId);

  /// Aktuell geladene Gym-Konfiguration (nach switchTenant).
  GymConfig? get config;

  /// Aktuell geladene Gym-ID (nach switchTenant oder init).
  String? get gymId;
}
