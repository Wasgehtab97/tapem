import '../models/session.dart';

abstract class SessionRepository {
  Future<List<Session>> getSessionsForDate({
    required String userId,
    required DateTime date,
    bool fromCacheOnly = false,
  });

  Future<void> deleteSession({
    required String gymId,
    required String userId,
    required Session session,
  });
}
