// lib/domain/usecases/coach/fetch_training_dates.dart

import 'package:tapem/domain/repositories/coach_repository.dart';

/// UseCase zum Abrufen aller Trainingstermine eines Klienten.
///
/// Gibt eine Liste von ISO-Datum-Strings zurück.
class FetchTrainingDatesUseCase {
  final CoachRepository _repository;

  FetchTrainingDatesUseCase(this._repository);

  /// [clientId] ist die eindeutige Kennung des Klienten.
  Future<List<String>> call({ required String clientId }) async {
    return await _repository.fetchTrainingDates(clientId);
  }
}
