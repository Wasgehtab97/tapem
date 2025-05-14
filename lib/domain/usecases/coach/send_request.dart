// lib/domain/usecases/coach/send_request.dart

import 'package:tapem/domain/repositories/coach_repository.dart';

/// UseCase zum Versenden einer Coaching-Anfrage.
class SendCoachingRequestUseCase {
  final CoachRepository _repository;

  SendCoachingRequestUseCase(this._repository);

  /// [coachId] ist die Kennung des Coaches, [membershipNumber] die
  /// Mitgliedsnummer des anfragenden Nutzers.
  Future<void> call({
    required String coachId,
    required String membershipNumber,
  }) async {
    await _repository.sendCoachingRequest(coachId, membershipNumber);
  }
}
