import '../models/session.dart';
import '../repositories/session_repository.dart';

/// Use-Case, der alle Sessions eines Tages liefert.
class GetSessionsForDate {
  final SessionRepository _repository;

  GetSessionsForDate(this._repository);

  Future<List<Session>> execute({
    required String userId,
    required DateTime date,
    bool fromCacheOnly = false,
    bool includePrivateMeta = true,
  }) {
    return _repository.getSessionsForDate(
      userId: userId,
      date: date,
      fromCacheOnly: fromCacheOnly,
      includePrivateMeta: includePrivateMeta,
    );
  }
}
