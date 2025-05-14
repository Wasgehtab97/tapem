// lib/domain/usecases/tenant/fetch_all_tenants.dart

import 'package:tapem/domain/models/tenant.dart';
import 'package:tapem/domain/repositories/tenant_repository.dart';

/// Use-Case: Holt alle verfügbaren Tenants (Gyms).
///
/// Liefert eine Liste von [Tenant], z. B. um beim Login oder Tenant-Wechsel
/// eine Auswahl anzuzeigen.
class FetchAllTenantsUseCase {
  final TenantRepository _repository;

  FetchAllTenantsUseCase(this._repository);

  Future<List<Tenant>> call() async {
    return await _repository.fetchAllTenants();
  }
}
