// lib/domain/usecases/tenant/get_config.dart

import 'package:tapem/domain/models/gym_config.dart';
import 'package:tapem/domain/repositories/tenant_repository.dart';

/// Use-Case: Liest die aktuell geladene Gym-Konfiguration aus.
///
/// Greift auf die im [TenantRepository] gespeicherte Konfiguration zu.
/// Gibt `null` zurück, falls noch keine Config geladen wurde.
class GetGymConfigUseCase {
  final TenantRepository _repository;

  GetGymConfigUseCase(this._repository);

  GymConfig? call() {
    return _repository.config;
  }
}
