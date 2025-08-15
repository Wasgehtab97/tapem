import 'session_draft.dart';

abstract class SessionDraftRepository {
  Future<SessionDraft?> get(String key);
  Future<void> put(String key, SessionDraft draft);
  Future<void> delete(String key);
  Future<void> deleteExpired(int nowMs);
  Future<void> deleteAll();
}
