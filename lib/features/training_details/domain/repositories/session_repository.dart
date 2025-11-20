import '../models/session.dart';

abstract class SessionRepository {
  Future<List<Session>> getSessionsForDate({
    required String userId,
    required DateTime date,
    bool fromCacheOnly = false,
  });

  Future<void> saveSession({
    required Session session,
  });

  Future<void> deleteSession({
    required String gymId,
    required String userId,
    required Session session,
  });

  Future<void> syncFromRemote({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });
}
