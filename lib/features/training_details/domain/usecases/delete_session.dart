import '../models/session.dart';
import '../repositories/session_repository.dart';

class DeleteSession {
  final SessionRepository _repository;
  DeleteSession(this._repository);

  Future<void> execute({
    required String gymId,
    required String userId,
    required Session session,
  }) {
    return _repository.deleteSession(
      gymId: gymId,
      userId: userId,
      session: session,
    );
  }
}
