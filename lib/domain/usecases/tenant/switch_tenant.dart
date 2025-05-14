// lib/domain/usecases/tenant/switch_tenant.dart

import 'package:tapem/domain/repositories/tenant_repository.dart';

/// Use-Case: Wechselt den aktuellen Tenant auf [gymId]
/// und lädt gleichzeitig die zugehörige Konfiguration.
///
/// - [gymId]: ID des neuen Gyms.
/// - Speichert die Auswahl und initialisiert anschließend die Config im Repository.
class SwitchTenantUseCase {
  final TenantRepository _repository;

  SwitchTenantUseCase(this._repository);

  Future<void> call(String gymId) async {
    await _repository.switchTenant(gymId);
  }
}
