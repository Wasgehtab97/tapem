// lib/domain/usecases/history/fetch_history.dart

import 'package:tapem/domain/models/exercise_entry.dart';
import 'package:tapem/domain/repositories/history_repository.dart';

/// Holt die Trainingshistorie eines Nutzers für ein bestimmtes Gerät.
///
/// [userId] – Die ID des aktuellen Nutzers.
/// [deviceId] – Die ID des Geräts, dessen Historie geladen werden soll.
/// [exercise] – Optionaler Übungsfilter.
/// Rückgabe: Liste von [ExerciseEntry].
class FetchHistoryUseCase {
  final HistoryRepository _repository;

  FetchHistoryUseCase(this._repository);

  Future<List<ExerciseEntry>> call({
    required String userId,
    required String deviceId,
    String? exercise,
  }) async {
    return await _repository.fetchHistory(
      userId: userId,
      deviceId: deviceId,
      exercise: exercise,
    );
  }
}
