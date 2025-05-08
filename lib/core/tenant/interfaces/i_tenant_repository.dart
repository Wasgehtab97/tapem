// lib/core/tenant/interfaces/i_tenant_repository.dart

import '../models/gym_config.dart';

/// Abstraktes Interface zum Laden und Speichern von Tenant-Daten.
abstract class ITenantRepository {
  Future<GymConfig> getConfig(String gymId);
  Future<void> saveConfig(GymConfig config);
}
