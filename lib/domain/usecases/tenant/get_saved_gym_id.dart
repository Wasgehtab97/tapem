// lib/domain/usecases/tenant/get_saved_gym_id.dart

import 'package:tapem/domain/repositories/tenant_repository.dart';

/// Use-Case: Liest die zuletzt ausgewählte oder gespeicherte Gym-ID.
///
/// Wird z. B. beim App-Start verwendet, um automatisch den letzten Tenant
/// wiederherzustellen.
class GetSavedGymIdUseCase {
  final TenantRepository _repository;

  GetSavedGymIdUseCase(this._repository);

  Future<String?> call() async {
    return await _repository.getSavedGymId();
  }
}
