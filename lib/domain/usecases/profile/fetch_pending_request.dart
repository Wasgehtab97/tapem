// lib/domain/usecases/profile/fetch_pending_request.dart

import 'package:tapem/domain/repositories/profile_repository.dart';

/// Holt eine offene Coaching-Anfrage.
class FetchPendingRequestUseCase {
  final ProfileRepository _repository;
  FetchPendingRequestUseCase(this._repository);

  Future<Map<String, dynamic>?> call(String userId) {
    return _repository.fetchPendingCoachingRequest(userId);
  }
}
