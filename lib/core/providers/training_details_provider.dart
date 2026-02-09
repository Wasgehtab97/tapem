import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/database/database_service.dart';
import 'package:tapem/core/sync/sync_service.dart';
import 'package:tapem/features/training_details/data/repositories/session_repository_impl.dart';
import 'package:tapem/features/training_details/data/sources/firestore_session_source.dart';
import 'package:tapem/features/training_details/data/session_meta_source.dart';
import 'package:tapem/features/training_details/domain/usecases/delete_session.dart';
import 'package:tapem/features/training_details/domain/usecases/get_sessions_for_date.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';
import 'package:tapem/core/time/logic_day.dart';
import 'database_provider.dart';

/// Notifier für den TrainingDetailsScreen.
class TrainingDetailsProvider extends ChangeNotifier {
  late final GetSessionsForDate _getSessions;
  late final DeleteSession _deleteSession;
  final SessionMetaSource _meta = SessionMetaSource();
  String? _userId;
  String? _gymId;
  DateTime? _date;
  bool _canAccessMeta = false;

  bool _isLoading = false;
  String? _error;
  List<Session> _sessions = [];
  int? _dayDurationMs;
  String? _planName;
  String? _planId;
  StreamSubscription<DayMetaSnapshot>? _dayMetaSubscription;
  bool _disposed = false;
  String? _lastMetaSignature;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Session> get sessions => List.unmodifiable(_sessions);
  int? get dayDurationMs => _dayDurationMs;
  String? get gymId => _gymId;
  String? get planName => _planName;
  String? get planId => _planId;

  TrainingDetailsProvider(
    DatabaseService databaseService,
    SyncService syncService,
  ) {
    final repo = SessionRepositoryImpl(databaseService, syncService, _meta);
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
      '📆 loadSessions user=$userId date=$date gym=${gymId ?? 'auto'}',
    );
    _userId = userId;
    _date = date;
    _canAccessMeta = _isCurrentUser(userId);
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

    final hasIncompleteLabels = _hasIncompleteLabels(cachedSessions);
    final shouldLoadRemote =
        refreshFromServer || cachedSessions.isEmpty || hasIncompleteLabels;
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
    await _hydrateExerciseNamesIfNeeded();
    final sessionsDurationMs = _deriveDurationFromSessions(_sessions);
    if (_sessions.isNotEmpty) {
      final sessionGymId = _sessions.first.gymId;
      await _updateGymId(sessionGymId);
      _dayDurationMs = sessionsDurationMs;
      if (_canAccessMeta) {
        final dayKey = logicDayKey(date);
        final meta = await _meta.getMetaByDayKey(
          gymId: sessionGymId,
          uid: userId,
          dayKey: dayKey,
          fromCacheOnly: fromCacheOnly,
        );
        debugPrint(
          '📌 TrainingDetails meta (sessions>0) gym=$sessionGymId dayKey=$dayKey meta=$meta',
        );
        final metaDurationMs = (meta?['durationMs'] as num?)?.toInt();
        _dayDurationMs = _preferDuration(_dayDurationMs, metaDurationMs);
        _planName = meta?['planName'] as String?;
        _planId = meta?['planId'] as String?;
        final newSignature = _buildMetaSignature(meta);
        if (newSignature != _lastMetaSignature) {
          _lastMetaSignature = newSignature;
        }
      } else {
        _planName = null;
        _planId = null;
        _lastMetaSignature = null;
      }
    } else {
      Map<String, dynamic>? meta;
      if (_canAccessMeta) {
        final currentGymId = _gymId;
        if (currentGymId != null) {
          final dayKey = logicDayKey(date);
          meta = await _meta.getMetaByDayKey(
            gymId: currentGymId,
            uid: userId,
            dayKey: dayKey,
            fromCacheOnly: fromCacheOnly,
          );
          _dayDurationMs = _preferDuration(
            sessionsDurationMs,
            (meta?['durationMs'] as num?)?.toInt(),
          );
          _planName = meta?['planName'] as String?;
          _planId = meta?['planId'] as String?;
        } else {
          _dayDurationMs = null;
          _planName = null;
          _planId = null;
          meta = null;
        }
        final newSignature = _buildMetaSignature(meta);
        if (newSignature != _lastMetaSignature) {
          _lastMetaSignature = newSignature;
        }
      } else {
        _dayDurationMs = null;
        _planName = null;
        _planId = null;
      }
    }
    if (!fromCacheOnly) {
      _isLoading = false;
    }
  }

  int? _deriveDurationFromSessions(List<Session> sessions) {
    if (sessions.isEmpty) return null;

    var totalKnownDurationMs = 0;
    DateTime? earliestStart;
    DateTime? latestEnd;
    for (final session in sessions) {
      final sessionDuration = session.durationMs;
      if (sessionDuration != null && sessionDuration > 0) {
        totalKnownDurationMs += sessionDuration;
      }

      final start = session.startTime ?? session.timestamp;
      final end = session.endTime ?? session.timestamp;
      if (earliestStart == null || start.isBefore(earliestStart)) {
        earliestStart = start;
      }
      if (latestEnd == null || end.isAfter(latestEnd)) {
        latestEnd = end;
      }
    }

    if (totalKnownDurationMs > 0) {
      return totalKnownDurationMs;
    }

    if (earliestStart != null && latestEnd != null) {
      final diff = latestEnd.difference(earliestStart).inMilliseconds;
      if (diff > 0) {
        return diff;
      }
    }
    return null;
  }

  int? _preferDuration(int? primary, int? fallback) {
    final normalizedPrimary = primary != null && primary > 0 ? primary : null;
    final normalizedFallback = fallback != null && fallback > 0
        ? fallback
        : null;
    if (normalizedPrimary == null) return normalizedFallback;
    if (normalizedFallback == null) return normalizedPrimary;
    return normalizedPrimary >= normalizedFallback
        ? normalizedPrimary
        : normalizedFallback;
  }

  Future<void> _hydrateExerciseNamesIfNeeded() async {
    final gymId = _gymId;
    if (gymId == null || gymId.isEmpty) {
      return;
    }

    final pending = _sessions.where((s) {
      final hasExerciseId = s.exerciseId != null && s.exerciseId!.isNotEmpty;
      final hasName =
          s.exerciseName != null && s.exerciseName!.trim().isNotEmpty;
      return s.isMulti && hasExerciseId && !hasName;
    }).toList();

    if (pending.isEmpty) {
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final cache = <String, String>{}; // "$deviceId|$exerciseId" -> name

    for (final session in pending) {
      final exerciseId = session.exerciseId;
      if (exerciseId == null || exerciseId.isEmpty) continue;
      final key = '${session.deviceId}|$exerciseId';
      if (cache.containsKey(key)) continue;
      try {
        final deviceRef = firestore
            .collection('gyms')
            .doc(gymId)
            .collection('devices')
            .doc(session.deviceId);
        final exerciseSnap = await deviceRef
            .collection('exercises')
            .doc(exerciseId)
            .get();
        final data = exerciseSnap.data();
        final name = data != null ? data['name'] as String? : null;
        if (name != null && name.trim().isNotEmpty) {
          cache[key] = name.trim();
        }
      } catch (_) {
        // Silent failure – we fallen back to deviceName later anyway.
      }
    }

    if (cache.isEmpty) {
      return;
    }

    _sessions = _sessions.map((s) {
      if (!s.isMulti ||
          s.exerciseId == null ||
          (s.exerciseName != null && s.exerciseName!.trim().isNotEmpty)) {
        return s;
      }
      final key = '${s.deviceId}|${s.exerciseId}';
      final resolved = cache[key];
      if (resolved == null || resolved.isEmpty) {
        return s;
      }
      return s.copyWith(exerciseName: resolved);
    }).toList();
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
    if (!_canAccessMeta) {
      return;
    }
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

  bool _hasIncompleteLabels(List<Session> sessions) {
    for (final session in sessions) {
      final deviceName = session.deviceName.trim();
      final deviceId = session.deviceId.trim();
      if (deviceName.isEmpty || deviceName == deviceId) {
        return true;
      }
      if (session.isMulti) {
        final exerciseId = session.exerciseId?.trim();
        final exerciseName = session.exerciseName?.trim() ?? '';
        if ((exerciseName.isEmpty ||
                (exerciseId != null && exerciseName == exerciseId)) &&
            (exerciseId != null && exerciseId.isNotEmpty)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isCurrentUser(String userId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return false;
    }
    return currentUser.uid == userId;
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

/// Parameterobjekt für den Riverpod-Provider.
@immutable
class TrainingDetailsRequest {
  const TrainingDetailsRequest({
    required this.userId,
    required this.date,
    this.gymId,
  });

  final String userId;
  final DateTime date;
  final String? gymId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrainingDetailsRequest &&
        other.userId == userId &&
        other.gymId == gymId &&
        other.date == date;
  }

  @override
  int get hashCode => Object.hash(userId, gymId, date.millisecondsSinceEpoch);
}

/// Riverpod-Provider für TrainingDetailsScreen.
///
/// Erzeugt einen [TrainingDetailsProvider] und lädt die Sessions für die
/// angegebene Kombination aus User, Datum und Gym.
final trainingDetailsStateProvider = ChangeNotifierProvider.autoDispose
    .family<TrainingDetailsProvider, TrainingDetailsRequest>((ref, request) {
      final databaseService = ref.watch(databaseServiceProvider);
      final syncService = ref.watch(syncServiceProvider);
      final provider = TrainingDetailsProvider(databaseService, syncService);
      provider.loadSessions(
        userId: request.userId,
        date: request.date,
        gymId: request.gymId,
      );
      return provider;
    });
