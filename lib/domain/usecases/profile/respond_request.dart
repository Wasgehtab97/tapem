// lib/domain/usecases/profile/respond_request.dart

import 'package:tapem/domain/repositories/profile_repository.dart';

/// Antwortet auf eine offene Coaching-Anfrage.
///
/// [requestId] – Die ID der zu beantwortenden Anfrage.
/// [accept] – `true`, um die Anfrage zu akzeptieren, sonst `false`.
/// Rückgabe: `void`.
class RespondRequestUseCase {
  final ProfileRepository _repository;

  RespondRequestUseCase(this._repository);

  Future<void> call(String requestId, bool accept) async {
    await _repository.respondToCoachingRequest(requestId, accept);
  }
}
