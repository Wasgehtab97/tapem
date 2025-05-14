// lib/domain/usecases/training_details/fetch_details.dart

import 'package:tapem/domain/repositories/training_details_repository.dart';

/// Use-Case: Holt alle Detail-Daten für ein bestimmtes Datum eines Nutzers.
///
/// - [userId]: ID des Nutzers.
/// - [dateKey]: ISO-String oder anderer Schlüssel, der das Datum identifiziert.
///
/// Gibt eine Liste von Maps zurück, in denen jeweils die Details
/// zum Trainingseintrag enthalten sind.
class FetchTrainingDetailsUseCase {
  final TrainingDetailsRepository _repository;

  FetchTrainingDetailsUseCase(this._repository);

  Future<List<Map<String, dynamic>>> call({
    required String userId,
    required String dateKey,
  }) async {
    return await _repository.fetchDetailsForDate(
      userId: userId,
      dateKey: dateKey,
    );
  }
}
