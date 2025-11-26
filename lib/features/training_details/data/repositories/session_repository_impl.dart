import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tapem/core/database/database_service.dart';
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

  SessionRepositoryImpl(
    this._db,
    this._syncService,
    this._meta, {
    FirestoreXpSource? xpSource,
    FirestoreDeviceSource? deviceSource,
  })  : _xpSource = xpSource ?? FirestoreXpSource(),
        _deviceSource = deviceSource ?? FirestoreDeviceSource();

  @override
  Future<List<Session>> getSessionsForDate({
    required String userId,
    required DateTime date,
    bool fromCacheOnly = false,
  }) async {
    // Local-First: Query Hive
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final box = _db.sessionsBox;
    final localSessions = box.values.where((session) {
      return session.userId == userId &&
          session.timestamp.isAfter(startOfDay) &&
          session.timestamp.isBefore(endOfDay);
    }).toList();

    // Sort by timestamp
    localSessions.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return localSessions.map((local) => Session(
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
      sets: local.sets.map((s) => SessionSet(
        weight: s.weight,
        reps: s.reps,
        setNumber: s.setNumber,
        dropWeightKg: s.dropWeightKg,
        dropReps: s.dropReps,
        isBodyweight: s.isBodyweight,
      )).toList(),
      startTime: local.startTime,
      endTime: local.endTime,
      durationMs: local.durationMs,
    )).toList();
  }

   @override
  Future<void> saveSession({required Session session}) async {
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
      ..sets = session.sets.map((s) => HiveSessionSet()
        ..weight = s.weight
        ..reps = s.reps
        ..setNumber = s.setNumber
        ..dropWeightKg = s.dropWeightKg ?? 0.0
        ..dropReps = s.dropReps ?? 0
        ..isBodyweight = s.isBodyweight).toList()
      ..startTime = session.startTime
      ..endTime = session.endTime
      ..durationMs = session.durationMs
      ..updatedAt = DateTime.now();

    await _db.sessionsBox.add(hiveSession);

    // 2. Queue Sync Job
    await _syncService.addJob(
      collection: 'sessions',
      docId: session.sessionId,
      action: 'create',
      payload: {
        'sessionId': session.sessionId,
        'gymId': session.gymId,
        'deviceId': session.deviceId,
        'timestamp': session.timestamp.toIso8601String(),
        'sets': session.sets.map((s) => {
          'weight': s.weight,
          'reps': s.reps,
          'setNumber': s.setNumber,
          'dropWeightKg': s.dropWeightKg,
          'dropReps': s.dropReps,
          'isBodyweight': s.isBodyweight,
        }).toList(),
        'note': session.note,
        'exerciseId': session.exerciseId ?? '',
      },
    );
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
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
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

      // Convert to HiveSession and save to Hive
      final box = _db.sessionsBox;
      for (final entry in grouped.entries) {
        final docs = entry.value;
        if (docs.isEmpty) continue;

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

        final hiveSession = HiveSession()
          ..sessionId = entry.key
          ..gymId = gymId
          ..userId = userId
          ..deviceId = firstData['deviceId'] as String? ?? ''
          ..deviceName = deviceName
          ..deviceDescription = deviceDescription
          ..isMulti = isMulti
          ..exerciseId = firstData['exerciseId'] as String?
          ..timestamp = (firstData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now()
          ..note = firstData['note'] as String?
          ..sets = sets
          ..updatedAt = DateTime.now();

        await box.add(hiveSession);
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
    // 1. Delete from Hive
    final box = _db.sessionsBox;
    final toDelete = box.values.where((s) => s.sessionId == session.sessionId).toList();
    for (final item in toDelete) {
      await item.delete();
    }

    // 2. Queue Sync Job
    await _syncService.addJob(
      collection: 'sessions',
      docId: session.sessionId,
      action: 'delete',
      payload: {
        'gymId': gymId,
        'deviceId': session.deviceId,
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
        final metaDayKey = meta?['dayKey'] as String?;
        final derivedDayKey = metaDayKey ??
            logicDayKey(
              (session.startTime ?? session.timestamp).toLocal(),
            );

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
