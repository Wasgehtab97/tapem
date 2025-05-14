// lib/domain/usecases/profile/fetch_training_dates.dart

import 'package:tapem/domain/repositories/profile_repository.dart';

/// Holt alle Trainingstermine für den aktuellen Nutzer.
///
/// [userId] – Die ID des aktuellen Nutzers.
/// Rückgabe: Liste von ISO-Strings der Trainingstermine.
class FetchProfileTrainingDatesUseCase {
  final ProfileRepository _repository;

  FetchProfileTrainingDatesUseCase(this._repository);

  Future<List<String>> call(String userId) async {
    return await _repository.fetchTrainingDates(userId);
  }
}
