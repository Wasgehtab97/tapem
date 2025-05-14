// lib/domain/usecases/dashboard/finish_session.dart

import 'package:tapem/domain/repositories/dashboard_repository.dart';

/// UseCase zum Beenden einer Session für ein Gerät.
///
/// [deviceId] – ID des Geräts  
/// [exercise] – Name der Übung
class FinishSessionUseCase {
  final DashboardRepository _repository;

  FinishSessionUseCase(this._repository);

  Future<void> call({
    required String deviceId,
    required String exercise,
  }) async {
    await _repository.finishSession(
      deviceId: deviceId,
      exercise: exercise,
    );
  }
}
