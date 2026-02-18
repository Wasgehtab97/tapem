import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tapem/core/database/database_service.dart';
import 'package:tapem/core/observability/offline_flow_observability_service.dart';
import 'package:tapem/core/storage/local_training_days_store.dart';
import 'package:tapem/core/sync/sync_service.dart';
import 'package:tapem/core/time/logic_day.dart';
import 'package:tapem/features/device/data/sources/firestore_device_source.dart';
import 'package:tapem/features/training_details/data/models/hive_session.dart';
import 'package:tapem/features/training_details/data/session_meta_source.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';
import 'package:tapem/features/training_details/domain/repositories/session_repository.dart';
import 'package:tapem/features/xp/data/sources/firestore_xp_source.dart';

/// Session repository with Hive for local-first data management
class SessionRepositoryImpl implements SessionRepository {
  final DatabaseService _db;
  final SyncService _syncService;
  final SessionMetaSource _meta;
  final FirestoreXpSource _xpSource;
  final FirestoreDeviceSource _deviceSource;
  final LocalTrainingDaysStore _trainingDaysStore;
  final OfflineFlowObservabilityService _observability;
  final Map<String, List<HiveSession>> _sessionsByUserDay =
      <String, List<HiveSession>>{};
  final Map<String, HiveSession> _lastSessionByDeviceExercise =
      <String, HiveSession>{};
  final Map<String, String> _sessionIdToUserDayKey = <String, String>{};
  bool _indexesHydrated = false;

  SessionRepositoryImpl(
    this._db,
    this._syncService,
    this._meta, {
    FirestoreXpSource? xpSource,
    FirestoreDeviceSource? deviceSource,
    LocalTrainingDaysStore? trainingDaysStore,
    OfflineFlowObservabilityService? observability,
  }) : _xpSource = xpSource ?? FirestoreXpSource(),
       _deviceSource = deviceSource ?? FirestoreDeviceSource(),
       _trainingDaysStore = trainingDaysStore ?? const LocalTrainingDaysStore(),
       _observability =
           observability ?? OfflineFlowObservabilityService.instance;

  @override
  Future<void> warmupForUser({required String userId}) async {
    await _ensureIndexesHydrated();
    if (userId.isEmpty) {
      return;
    }
    final activeDayCount = _sessionsByUserDay.keys
        .where((key) => key.startsWith('$userId::'))
        .length;
    debugPrint(
      '[SessionRepository] Warmup completed for user=$userId days=$activeDayCount',
    );
  }

  Future<void> _ensureIndexesHydrated() async {
    if (_indexesHydrated) {
      return;
    }
    _sessionsByUserDay.clear();
    _lastSessionByDeviceExercise.clear();
    _sessionIdToUserDayKey.clear();
    for (final session in _db.sessionsBox.values) {
      _indexSession(session, sortBucket: false);
    }
    for (final bucket in _sessionsByUserDay.values) {
      bucket.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
    _indexesHydrated = true;
  }

  void _invalidateIndexes() {
    _indexesHydrated = false;
  }

  void _indexSession(HiveSession session, {bool sortBucket = true}) {
    final dayKey = logicDayKey(
      (session.startTime ?? session.timestamp).toLocal(),
    );
    final userDayKey = _userDayKey(userId: session.userId, dayKey: dayKey);
    final previousUserDayKey = _sessionIdToUserDayKey[session.sessionId];
    if (previousUserDayKey != null && previousUserDayKey != userDayKey) {
      final previousBucket = _sessionsByUserDay[previousUserDayKey];
      previousBucket?.removeWhere(
        (item) => item.sessionId == session.sessionId,
      );
      if (previousBucket != null && previousBucket.isEmpty) {
        _sessionsByUserDay.remove(previousUserDayKey);
      }
    }

    final bucket = _sessionsByUserDay.putIfAbsent(
      userDayKey,
      () => <HiveSession>[],
    );
    bucket.removeWhere((item) => item.sessionId == session.sessionId);
    bucket.add(session);
    if (sortBucket) {
      bucket.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
    _sessionIdToUserDayKey[session.sessionId] = userDayKey;

    final lookupKey = _deviceExerciseKey(
      gymId: session.gymId,
      userId: session.userId,
      deviceId: session.deviceId,
      exerciseId: session.exerciseId ?? '',
    );
    final current = _lastSessionByDeviceExercise[lookupKey];
    if (current == null || session.timestamp.isAfter(current.timestamp)) {
      _lastSessionByDeviceExercise[lookupKey] = session;
    }
  }

  String _userDayKey({required String userId, required String dayKey}) =>
      '$userId::$dayKey';

  String _deviceExerciseKey({
    required String gymId,
    required String userId,
    required String deviceId,
    required String exerciseId,
  }) => '$gymId::$userId::$deviceId::$exerciseId';

  Session _mapHiveSessionToDomain(HiveSession local) {
    final sortedSets = local.sets.toList()
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));

    return Session(
      sessionId: local.sessionId,
      gymId: local.gymId,
      userId: local.userId,
      deviceId: local.deviceId,
      deviceName: local.deviceName,
      deviceDescription: local.deviceDescription,
      exerciseId: local.exerciseId,
      exerciseName: local.exerciseName,
      isMulti: local.isMulti,
      timestamp: local.timestamp,
      note: local.note ?? '',
      sets: sortedSets
          .map(
            (s) => SessionSet(
              weight: s.weight,
              reps: s.reps,
              setNumber: s.setNumber,
              dropWeightKg: s.dropWeightKg,
              dropReps: s.dropReps,
              isBodyweight: s.isBodyweight,
            ),
          )
          .toList(),
      startTime: local.startTime,
      endTime: local.endTime,
      durationMs: local.durationMs,
    );
  }

  @override
  Future<List<Session>> getSessionsForDate({
    required String userId,
    required DateTime date,
    bool fromCacheOnly = false,
  }) async {
    await _ensureIndexesHydrated();
    final dayKey = logicDayKey(date.toLocal());
    final localSessions =
        _sessionsByUserDay[_userDayKey(userId: userId, dayKey: dayKey)] ??
        const <HiveSession>[];
    return localSessions.map(_mapHiveSessionToDomain).toList();
  }

  @override
  Future<Session?> getLastSession({
    required String gymId,
    required String userId,
    required String deviceId,
    required String exerciseId,
  }) async {
    await _ensureIndexesHydrated();
    final latest =
        _lastSessionByDeviceExercise[_deviceExerciseKey(
          gymId: gymId,
          userId: userId,
          deviceId: deviceId,
          exerciseId: exerciseId,
        )];
    if (latest == null) {
      return null;
    }
    return _mapHiveSessionToDomain(latest);
  }

  @override
  Future<void> saveSession({required Session session}) async {
    final anchorStart = (session.startTime ?? session.timestamp).toLocal();
    final anchorDayKey = logicDayKey(anchorStart);

    // 1. Save to Hive
    final hiveSession = HiveSession()
      ..sessionId = session.sessionId
      ..gymId = session.gymId
      ..userId = session.userId
      ..deviceId = session.deviceId
      ..deviceName = session.deviceName
      ..deviceDescription = session.deviceDescription
      ..isMulti = session.isMulti
      ..exerciseId = session.exerciseId
      ..exerciseName = session.exerciseName
      ..timestamp = session.timestamp
      ..note = session.note
      ..sets = session.sets
          .map(
            (s) => HiveSessionSet()
              ..weight = s.weight
              ..reps = s.reps
              ..setNumber = s.setNumber
              ..dropWeightKg = s.dropWeightKg ?? 0.0
              ..dropReps = s.dropReps ?? 0
              ..isBodyweight = s.isBodyweight,
          )
          .toList()
      ..startTime = session.startTime
      ..endTime = session.endTime
      ..durationMs = session.durationMs
      ..updatedAt = DateTime.now();

    await _db.sessionsBox.add(hiveSession);
    if (_indexesHydrated) {
      _indexSession(hiveSession);
    }
    await _trainingDaysStore.addDayKey(session.userId, anchorDayKey);
    await _observability.recordLocalSessionSaveSuccess();

    // 2. Queue Sync Job
    try {
      await _syncService.addJob(
        collection: 'sessions',
        docId: session.sessionId,
        action: 'create',
        payload: {
          'sessionId': session.sessionId,
          'gymId': session.gymId,
          'userId': session
              .userId, // ← CRITICAL: Must include userId for friend calendar queries
          'deviceId': session.deviceId,
          'deviceName': session.deviceName,
          'deviceDescription': session.deviceDescription,
          'timestamp': session.timestamp.toIso8601String(),
          'startTime': session.startTime?.toIso8601String(),
          'endTime': session.endTime?.toIso8601String(),
          'durationMs': session.durationMs,
          'anchorStartTime': anchorStart.toIso8601String(),
          'anchorDayKey': anchorDayKey,
          'sets': session.sets
              .map(
                (s) => {
                  'weight': s.weight,
                  'reps': s.reps,
                  'setNumber': s.setNumber,
                  'dropWeightKg': s.dropWeightKg,
                  'dropReps': s.dropReps,
                  'isBodyweight': s.isBodyweight,
                },
              )
              .toList(),
          'note': session.note,
          'exerciseId': session.exerciseId ?? '',
          'exerciseName': session.exerciseName ?? '',
          'isMulti': session.isMulti,
        },
      );
    } catch (e) {
      // Session is already persisted locally. Sync can be retried later.
      debugPrint(
        '[SessionRepository] Failed to enqueue sync job for ${session.sessionId}: $e',
      );
    }
  }

  @override
  Future<void> syncFromRemote({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Fetch from Firestore
      final firestore = FirebaseFirestore.instance;
      final query = firestore
          .collectionGroup('logs')
          .where('userId', isEqualTo: userId)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));

      final snap = await query.get();

      // Group by sessionId
      final Map<String, List<DocumentSnapshot>> grouped = {};
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        final sessionId = data['sessionId'] as String?;
        if (sessionId == null) continue;
        grouped.putIfAbsent(sessionId, () => []).add(doc);
      }

      // Convert to HiveSession and save to Hive (with upsert logic to prevent duplicates)
      final box = _db.sessionsBox;
      final importedDayKeys = <String>{};
      for (final entry in grouped.entries) {
        final docs = entry.value;
        if (docs.isEmpty) continue;

        final sessionId = entry.key;
        final firstData = docs.first.data() as Map<String, dynamic>;
        final deviceRef = docs.first.reference.parent.parent!;
        final gymId = deviceRef.parent.parent!.id;

        // Fetch device metadata
        String deviceName = firstData['deviceId'] as String? ?? '';
        String deviceDescription = '';
        bool isMulti = false;
        try {
          final deviceSnap = await deviceRef.get();
          final deviceData = deviceSnap.data();
          if (deviceData != null) {
            deviceName = deviceData['name'] as String? ?? deviceName;
            deviceDescription = deviceData['description'] as String? ?? '';
            isMulti = deviceData['isMulti'] as bool? ?? false;
          }
        } catch (_) {}

        final sets = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return HiveSessionSet()
            ..weight = (data['weight'] as num?)?.toDouble() ?? 0.0
            ..reps = (data['reps'] as num?)?.toInt() ?? 0
            ..setNumber = (data['setNumber'] as num?)?.toInt() ?? 0
            ..dropWeightKg = (data['dropWeightKg'] as num?)?.toDouble() ?? 0.0
            ..dropReps = (data['dropReps'] as num?)?.toInt() ?? 0
            ..isBodyweight = data['isBodyweight'] as bool? ?? false;
        }).toList();

        // Check if session already exists to prevent duplicates
        HiveSession? existingSession;
        for (final session in box.values) {
          if (session.sessionId == sessionId) {
            existingSession = session;
            break;
          }
        }

        if (existingSession != null) {
          // Update existing session
          existingSession
            ..gymId = gymId
            ..userId = userId
            ..deviceId = firstData['deviceId'] as String? ?? ''
            ..deviceName = deviceName
            ..deviceDescription = deviceDescription
            ..isMulti = isMulti
            ..exerciseId = firstData['exerciseId'] as String?
            ..exerciseName = firstData['exerciseName'] as String?
            ..timestamp =
                (firstData['timestamp'] as Timestamp?)?.toDate() ??
                DateTime.now()
            ..note = firstData['note'] as String?
            ..sets = sets
            ..startTime = firstData['startTime'] != null
                ? (firstData['startTime'] as Timestamp).toDate()
                : null
            ..endTime = firstData['endTime'] != null
                ? (firstData['endTime'] as Timestamp).toDate()
                : null
            ..durationMs = (firstData['durationMs'] as num?)?.toInt()
            ..updatedAt = DateTime.now();
          await existingSession.save();
          if (_indexesHydrated) {
            _indexSession(existingSession);
          }
          importedDayKeys.add(
            logicDayKey(
              (existingSession.startTime ?? existingSession.timestamp)
                  .toLocal(),
            ),
          );
          debugPrint('🔄 Updated existing session: $sessionId');
        } else {
          // Add new session
          final hiveSession = HiveSession()
            ..sessionId = sessionId
            ..gymId = gymId
            ..userId = userId
            ..deviceId = firstData['deviceId'] as String? ?? ''
            ..deviceName = deviceName
            ..deviceDescription = deviceDescription
            ..isMulti = isMulti
            ..exerciseId = firstData['exerciseId'] as String?
            ..exerciseName = firstData['exerciseName'] as String?
            ..timestamp =
                (firstData['timestamp'] as Timestamp?)?.toDate() ??
                DateTime.now()
            ..note = firstData['note'] as String?
            ..sets = sets
            ..startTime = firstData['startTime'] != null
                ? (firstData['startTime'] as Timestamp).toDate()
                : null
            ..endTime = firstData['endTime'] != null
                ? (firstData['endTime'] as Timestamp).toDate()
                : null
            ..durationMs = (firstData['durationMs'] as num?)?.toInt()
            ..updatedAt = DateTime.now();

          await box.add(hiveSession);
          if (_indexesHydrated) {
            _indexSession(hiveSession);
          }
          importedDayKeys.add(
            logicDayKey(
              (hiveSession.startTime ?? hiveSession.timestamp).toLocal(),
            ),
          );
          debugPrint('✅ Added new session: $sessionId');
        }
      }
      if (importedDayKeys.isNotEmpty) {
        final existing = await _trainingDaysStore.readDayKeys(userId);
        await _trainingDaysStore.writeDayKeys(userId, {
          ...existing,
          ...importedDayKeys,
        });
      }
      if (grouped.isNotEmpty) {
        _invalidateIndexes();
      }
    } catch (e) {
      // Log error but don't throw - sync should be best effort
      debugPrint('syncFromRemote error: $e');
    }
  }

  @override
  Future<void> deleteSession({
    required String gymId,
    required String userId,
    required Session session,
  }) async {
    final anchorStart = (session.startTime ?? session.timestamp).toLocal();
    final anchorDayKey = logicDayKey(anchorStart);

    // 1. Delete from Hive
    final box = _db.sessionsBox;
    final toDelete = box.values
        .where((s) => s.sessionId == session.sessionId)
        .toList();
    for (final item in toDelete) {
      await item.delete();
    }
    if (toDelete.isNotEmpty) {
      _invalidateIndexes();
    }
    final stillHasSessionForDay = box.values.any((s) {
      if (s.userId != userId) return false;
      final day = logicDayKey((s.startTime ?? s.timestamp).toLocal());
      return day == anchorDayKey;
    });
    if (!stillHasSessionForDay) {
      await _trainingDaysStore.removeDayKey(userId, anchorDayKey);
    }

    // 2. Queue Sync Job
    await _syncService.addJob(
      collection: 'sessions',
      docId: session.sessionId,
      action: 'delete',
      payload: {
        'gymId': gymId,
        'deviceId': session.deviceId,
        'anchorStartTime': anchorStart.toIso8601String(),
        'anchorDayKey': anchorDayKey,
      },
    );

    // 3. Cleanup auxiliary data (best effort)
    try {
      final snapshot = await _deviceSource.getSnapshotBySessionId(
        gymId: gymId,
        deviceId: session.deviceId,
        sessionId: session.sessionId,
      );

      final exerciseIds = <String>{};
      if (session.exerciseId != null) exerciseIds.add(session.exerciseId!);
      if (snapshot?.exerciseId != null) exerciseIds.add(snapshot!.exerciseId!);

      final meta = await _meta.getMetaBySessionId(
        gymId: gymId,
        uid: userId,
        sessionId: session.sessionId,
      );
      final metaAnchorDayKey = meta?['anchorDayKey'] as String?;
      final metaDayKey = meta?['dayKey'] as String?;
      final derivedDayKey =
          metaAnchorDayKey ??
          metaDayKey ??
          logicDayKey((session.startTime ?? session.timestamp).toLocal());

      await _deviceSource.deleteSessionSnapshot(
        gymId: gymId,
        deviceId: session.deviceId,
        sessionId: session.sessionId,
      );
      await _meta.deleteMeta(
        gymId: gymId,
        uid: userId,
        sessionId: session.sessionId,
      );
      await _xpSource.removeSessionXp(
        gymId: gymId,
        userId: userId,
        deviceId: session.deviceId,
        sessionId: session.sessionId,
        dayKey: derivedDayKey,
        exerciseIds: exerciseIds,
        primaryMuscleGroupIds: snapshot?.primaryMuscleGroupIds ?? const [],
        secondaryMuscleGroupIds: snapshot?.secondaryMuscleGroupIds ?? const [],
      );
    } catch (e) {
      debugPrint('[SessionRepository] Error deleting remote session: $e');
    }
  }
}
