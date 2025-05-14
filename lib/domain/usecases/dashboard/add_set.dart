// lib/domain/usecases/dashboard/add_set.dart

import 'package:tapem/domain/repositories/dashboard_repository.dart';

/// UseCase zum Hinzufügen eines Satzes für ein Gerät.
///
/// [deviceId] – ID des Geräts  
/// [exercise] – Name der Übung  
/// [sets] – Anzahl der Sätze  
/// [reps] – Wiederholungen pro Satz  
/// [weight] – Gewicht in kg
class AddSetUseCase {
  final DashboardRepository _repository;

  AddSetUseCase(this._repository);

  Future<void> call({
    required String deviceId,
    required String exercise,
    required int sets,
    required double weight,
    required int reps,
  }) async {
    await _repository.addSet(
      deviceId: deviceId,
      exercise: exercise,
      sets: sets,
      weight: weight,
      reps: reps,
    );
  }
}
