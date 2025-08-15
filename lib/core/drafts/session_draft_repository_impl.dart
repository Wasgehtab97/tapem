import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'session_draft.dart';
import 'session_draft_repository.dart';

const _prefix = 'sessionDraft/';

class SessionDraftRepositoryImpl implements SessionDraftRepository {
  @override
  Future<SessionDraft?> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('$_prefix$key');
    if (data == null) return null;
    try {
      return SessionDraft.decode(data);
    } catch (_) {
      await prefs.remove('$_prefix$key');
      return null;
    }
  }

  @override
  Future<void> put(String key, SessionDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$key', draft.encode());
  }

  @override
  Future<void> delete(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
  }

  @override
  Future<void> deleteExpired(int nowMs) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final k in keys) {
      final raw = prefs.getString(k);
      if (raw == null) continue;
      try {
        final draft = SessionDraft.decode(raw);
        if (nowMs - draft.updatedAt > draft.ttlMs) {
          await prefs.remove(k);
        }
      } catch (_) {
        await prefs.remove(k);
      }
    }
  }

  @override
  Future<void> deleteAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
