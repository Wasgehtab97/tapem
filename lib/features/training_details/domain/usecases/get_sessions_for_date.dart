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
  }) async {
    if (fromCacheOnly) {
      return _repository.getSessionsForDate(
        userId: userId,
        date: date,
        fromCacheOnly: true,
      );
    }

    // Sync from remote
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    await _repository.syncFromRemote(
      userId: userId,
      startDate: startOfDay,
      endDate: endOfDay,
    );

    // Return from cache (now populated)
    return _repository.getSessionsForDate(
      userId: userId,
      date: date,
      fromCacheOnly: true,
    );
  }
}
