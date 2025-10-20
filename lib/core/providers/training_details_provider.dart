import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tapem/features/training_details/data/repositories/session_repository_impl.dart';
import 'package:tapem/features/training_details/data/sources/firestore_session_source.dart';
import 'package:tapem/features/training_details/data/session_meta_source.dart';
import 'package:tapem/features/training_details/domain/usecases/delete_session.dart';
import 'package:tapem/features/training_details/domain/usecases/get_sessions_for_date.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';
import 'package:tapem/core/time/logic_day.dart';

/// Notifier für den TrainingDetailsScreen.
class TrainingDetailsProvider extends ChangeNotifier {
  late final GetSessionsForDate _getSessions;
  late final DeleteSession _deleteSession;
  final SessionMetaSource _meta = SessionMetaSource();
  String? _userId;
  String? _gymId;
  DateTime? _date;

  bool _isLoading = false;
  String? _error;
  List<Session> _sessions = [];
  int? _dayDurationMs;
  StreamSubscription<DayMetaSnapshot>? _dayMetaSubscription;
  bool _disposed = false;
  String? _lastMetaSignature;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Session> get sessions => List.unmodifiable(_sessions);
  int? get dayDurationMs => _dayDurationMs;
  String? get gymId => _gymId;

  TrainingDetailsProvider() {
    final repo = SessionRepositoryImpl(
      FirestoreSessionSource(),
      _meta,
    );
    _getSessions = GetSessionsForDate(repo);
    _deleteSession = DeleteSession(repo);
  }

  /// Lädt alle Sessions für [userId] am [date].
  Future<void> loadSessions({
    required String userId,
    required DateTime date,
    String? gymId,
  }) async {
    debugPrint(
        '📆 loadSessions user=$userId date=$date gym=${gymId ?? 'auto'}');
    _userId = userId;
    _date = date;
    await _updateGymId(gymId);
    await _refreshSessions(showLoading: true);
  }

  Future<void> deleteSession(Session session) async {
    final userId = _userId;
    final gymId = _gymId;
    if (userId == null || gymId == null || _date == null) {
      throw StateError('TrainingDetailsProvider not initialised');
    }
    _isLoading = true;
    _safeNotifyListeners();
    try {
      await _deleteSession.execute(
        gymId: gymId,
        userId: userId,
        session: session,
      );
      await _refreshSessions(showLoading: false, refreshFromServer: true);
      if (_error != null) {
        throw Exception(_error);
      }
    } catch (e) {
      debugPrint('❌ deleteSession error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<void> _refreshSessions({
    required bool showLoading,
    bool refreshFromServer = false,
  }) async {
    final userId = _userId;
    final date = _date;
    if (userId == null || date == null) {
      return;
    }

    if (showLoading) {
      _isLoading = true;
      _safeNotifyListeners();
    }
    _error = null;

    List<Session> cachedSessions = const [];
    try {
      cachedSessions = await _getSessions.execute(
        userId: userId,
        date: date,
        fromCacheOnly: true,
      );
      debugPrint('✅ cache loaded ${cachedSessions.length} sessions');
      await _applySessions(
        sessions: cachedSessions,
        userId: userId,
        date: date,
        fromCacheOnly: true,
      );
      if (showLoading && cachedSessions.isNotEmpty) {
        _isLoading = false;
      }
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('⚠️ cache load error: $e');
    }

    final shouldLoadRemote = refreshFromServer || cachedSessions.isEmpty;
    if (!shouldLoadRemote) {
      if (showLoading) {
        _isLoading = false;
        _safeNotifyListeners();
      }
      return;
    }

    var remoteSucceeded = false;
    try {
      final sessions = await _getSessions.execute(userId: userId, date: date);
      debugPrint('✅ loaded ${sessions.length} sessions');
      await _applySessions(
        sessions: sessions,
        userId: userId,
        date: date,
        fromCacheOnly: false,
      );
      remoteSucceeded = true;
      if (showLoading) {
        _isLoading = false;
      }
      _safeNotifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ loadSessions error: $e');
    }

    if (!remoteSucceeded) {
      if (showLoading) {
        _isLoading = false;
      }
      _safeNotifyListeners();
    }
  }

  Future<void> _applySessions({
    required List<Session> sessions,
    required String userId,
    required DateTime date,
    required bool fromCacheOnly,
  }) async {
    _sessions = sessions;
    if (_sessions.isNotEmpty) {
      final sessionGymId = _sessions.first.gymId;
      await _updateGymId(sessionGymId);
      _dayDurationMs = _sessions.first.durationMs;
      _lastMetaSignature = null;
    } else {
      final currentGymId = _gymId;
      Map<String, dynamic>? meta;
      if (currentGymId != null) {
        final dayKey = logicDayKey(date);
        meta = await _meta.getMetaByDayKey(
          gymId: currentGymId,
          uid: userId,
          dayKey: dayKey,
          fromCacheOnly: fromCacheOnly,
        );
        _dayDurationMs = (meta?['durationMs'] as num?)?.toInt();
      } else {
        _dayDurationMs = null;
        meta = null;
      }
      final newSignature = _buildMetaSignature(meta);
      if (newSignature != _lastMetaSignature) {
        _lastMetaSignature = newSignature;
      }
    }
    if (!fromCacheOnly) {
      _isLoading = false;
    }
  }

  Future<void> _updateGymId(String? newGymId) async {
    if (newGymId == null || newGymId.isEmpty) {
      return;
    }
    if (_gymId == newGymId) {
      return;
    }
    _gymId = newGymId;
    await _startMetaSubscription();
  }

  Future<void> _startMetaSubscription() async {
    await _dayMetaSubscription?.cancel();
    final userId = _userId;
    final gymId = _gymId;
    final date = _date;
    if (userId == null || gymId == null || date == null) {
      return;
    }
    final dayKey = logicDayKey(date);
    _dayMetaSubscription = _meta
        .watchMetaByDayKey(gymId: gymId, uid: userId, dayKey: dayKey)
        .listen((event) async {
      if (_disposed) return;
      final signature = _buildMetaSignature(event.data);
      if (event.isFromCache) {
        _lastMetaSignature = signature;
        return;
      }
      if (signature == _lastMetaSignature) {
        return;
      }
      _lastMetaSignature = signature;
      await _refreshSessions(showLoading: false, refreshFromServer: true);
    });
  }

  String? _buildMetaSignature(Map<String, dynamic>? meta) {
    if (meta == null) return null;
    final sortedKeys = meta.keys.toList()..sort();
    final buffer = StringBuffer();
    for (final key in sortedKeys) {
      buffer
        ..write(key)
        ..write(':')
        ..write(meta[key])
        ..write(';');
    }
    return buffer.toString();
  }

  void _safeNotifyListeners() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _dayMetaSubscription?.cancel();
    super.dispose();
  }
}
