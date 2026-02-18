import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import 'package:tapem/core/database/database_service.dart';
import 'package:tapem/core/observability/offline_flow_observability_service.dart';
import 'package:tapem/core/sync/models/hive_sync_job.dart';
import 'package:tapem/features/challenges/data/sources/firestore_challenge_source.dart';
import 'package:tapem/features/community/data/community_stats_writer.dart';
import 'package:tapem/features/device/data/sources/firestore_device_source.dart';
import 'package:tapem/features/device/domain/models/device_session_snapshot.dart';
import 'package:tapem/features/xp/data/sources/firestore_xp_source.dart';
import 'package:uuid/uuid.dart';

enum SyncServiceErrorCode {
  invalidPayload,
  unsupportedCollection,
  unsupportedAction,
}

class SyncServiceException implements Exception {
  const SyncServiceException({required this.code, required this.message});

  final SyncServiceErrorCode code;
  final String message;

  @override
  String toString() => 'SyncServiceException($code): $message';
}

enum _SessionSyncAction { create, delete }

enum _WorkoutAuxSyncAction {
  attemptsAndNoteUpsert,
  snapshotUpsert,
  communityRecord,
  restStatsRecord,
  xpCreditSession,
  challengeCheck,
}

enum SyncJobFailureKind { transient, permanent }

@immutable
class SyncQueueStatus {
  const SyncQueueStatus({
    required this.pendingCount,
    required this.deadLetterCount,
    required this.isSyncing,
    this.lastSyncedAt,
    this.lastErrorReason,
    this.lastErrorCode,
  });

  final int pendingCount;
  final int deadLetterCount;
  final bool isSyncing;
  final DateTime? lastSyncedAt;
  final String? lastErrorReason;
  final String? lastErrorCode;

  const SyncQueueStatus.initial()
    : pendingCount = 0,
      deadLetterCount = 0,
      isSyncing = false,
      lastSyncedAt = null,
      lastErrorReason = null,
      lastErrorCode = null;

  SyncQueueStatus copyWith({
    int? pendingCount,
    int? deadLetterCount,
    bool? isSyncing,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
    String? lastErrorReason,
    bool clearLastErrorReason = false,
    String? lastErrorCode,
    bool clearLastErrorCode = false,
  }) {
    return SyncQueueStatus(
      pendingCount: pendingCount ?? this.pendingCount,
      deadLetterCount: deadLetterCount ?? this.deadLetterCount,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncedAt: clearLastSyncedAt
          ? null
          : (lastSyncedAt ?? this.lastSyncedAt),
      lastErrorReason: clearLastErrorReason
          ? null
          : (lastErrorReason ?? this.lastErrorReason),
      lastErrorCode: clearLastErrorCode
          ? null
          : (lastErrorCode ?? this.lastErrorCode),
    );
  }
}

/// Sync service with Hive-based offline sync queue
class SyncService {
  static const int _maxRetryCount = 5;
  final DatabaseService _db;
  final FirebaseFirestore _firestore;
  final Connectivity _connectivity;
  final FirestoreDeviceSource _deviceSource;
  final CommunityStatsWriter _communityStatsWriter;
  final FirestoreXpSource _xpSource;
  final FirestoreChallengeSource _challengeSource;
  final OfflineFlowObservabilityService _observability;
  final ValueNotifier<SyncQueueStatus> _status = ValueNotifier<SyncQueueStatus>(
    const SyncQueueStatus.initial(),
  );

  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;
  Timer? _periodicSyncTimer;

  SyncService(
    this._db, {
    FirebaseFirestore? firestore,
    Connectivity? connectivity,
    FirestoreDeviceSource? deviceSource,
    CommunityStatsWriter? communityStatsWriter,
    FirestoreXpSource? xpSource,
    FirestoreChallengeSource? challengeSource,
    OfflineFlowObservabilityService? observability,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _connectivity = connectivity ?? Connectivity(),
       _deviceSource =
           deviceSource ?? FirestoreDeviceSource(firestore: firestore),
       _communityStatsWriter =
           communityStatsWriter ?? CommunityStatsWriter(firestore: firestore),
       _xpSource = xpSource ?? FirestoreXpSource(firestore: firestore),
       _challengeSource =
           challengeSource ?? FirestoreChallengeSource(firestore: firestore),
       _observability =
           observability ?? OfflineFlowObservabilityService.instance;

  ValueListenable<SyncQueueStatus> get statusListenable => _status;
  SyncQueueStatus get status => _status.value;

  void init() {
    unawaited(_cleanupOptionalAuxDeadLetters());
    _refreshQueueStatus();
    unawaited(_cleanupJobsForOtherUsers());
    unawaited(_recoverAppCheckDeadLetters());
    unawaited(_recoverPermissionDeniedSessionDeadLetters());
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        debugPrint('[SyncService] Connectivity restored, triggering sync');
        unawaited(_preparePendingJobsForImmediateRetry());
        syncPendingJobs();
      }
    });

    // Start periodic sync every 5 minutes when online
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      syncPendingJobs();
    });

    // Initial sync on startup
    Future.delayed(const Duration(seconds: 2), () {
      syncPendingJobs();
    });

    debugPrint('[SyncService] Initialized with Hive');
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
    _status.dispose();
  }

  Future<void> syncPendingJobs() async {
    if (_isSyncing) {
      debugPrint('[SyncService] Already syncing, skipping');
      return;
    }

    final cycleStartedAt = DateTime.now();
    var processedJobs = 0;
    var processedQueueLatencySumMs = 0.0;

    _isSyncing = true;
    _refreshQueueStatus(isSyncing: true);

    try {
      final box = _db.syncJobsBox;
      final allJobs = box.values.toList();
      final deadLetterCount = allJobs.where((job) => job.isDeadLetter).length;
      final pendingJobs = allJobs.where((job) => !job.isDeadLetter).toList();

      // Sort by createdAt and take max 50
      pendingJobs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final jobs = pendingJobs.take(50).toList();

      debugPrint(
        '[SyncService] Found ${jobs.length} pending jobs'
        '${deadLetterCount > 0 ? ' (+$deadLetterCount dead-letter)' : ''}',
      );

      for (final job in jobs) {
        final droppedForUserMismatch = await _discardIfForeignUserJob(job);
        if (droppedForUserMismatch) {
          continue;
        }

        if (job.retryCount >= _maxRetryCount) {
          await _moveToDeadLetter(
            job,
            reason: 'retry_limit_exceeded',
            errorCode: job.deadLetterErrorCode,
          );
          continue;
        }

        // Exponential backoff
        if (job.lastAttempt != null) {
          final backoffMs = min(pow(2, job.retryCount) * 1000, 60000).toInt();
          final elapsed = DateTime.now()
              .difference(job.lastAttempt!)
              .inMilliseconds;
          if (elapsed < backoffMs) {
            continue; // Skip this job for now
          }
        }

        try {
          await _processJob(job);
          debugPrint('[SyncService] Successfully processed job ${job.id}');
          processedJobs++;
          processedQueueLatencySumMs += DateTime.now()
              .difference(job.createdAt)
              .inMilliseconds;

          // Delete job from Hive
          await job.delete();
        } catch (e) {
          await _handleJobFailure(job: job, error: e);
        }
      }
      _refreshQueueStatus(
        isSyncing: true,
        lastSyncedAt: DateTime.now(),
        clearError: true,
      );
    } catch (e) {
      debugPrint('[SyncService] Sync error: $e');
      _refreshQueueStatus(
        isSyncing: true,
        lastErrorReason: e.toString(),
        lastErrorCode: _extractErrorCode(e),
      );
    } finally {
      _isSyncing = false;
      _refreshQueueStatus(isSyncing: false);
      final jobsAfter = _db.syncJobsBox.values.toList(growable: false);
      final deadLetterCountAfter = jobsAfter
          .where((job) => job.isDeadLetter)
          .length;
      final pendingCountAfter = jobsAfter.length - deadLetterCountAfter;
      final averageQueueLatencyMs = processedJobs > 0
          ? processedQueueLatencySumMs / processedJobs
          : null;
      unawaited(
        _observability.recordSyncCycle(
          pendingCount: pendingCountAfter,
          deadLetterCount: deadLetterCountAfter,
          processedJobs: processedJobs,
          reconcileDuration: DateTime.now().difference(cycleStartedAt),
          averageQueueLatencyMs: averageQueueLatencyMs,
        ),
      );
    }
  }

  void _refreshQueueStatus({
    bool? isSyncing,
    DateTime? lastSyncedAt,
    String? lastErrorReason,
    String? lastErrorCode,
    bool clearError = false,
  }) {
    final jobs = _db.syncJobsBox.values.toList(growable: false);
    final deadLetterCount = jobs.where((job) => job.isDeadLetter).length;
    final pendingCount = jobs.length - deadLetterCount;
    _status.value = _status.value.copyWith(
      pendingCount: pendingCount,
      deadLetterCount: deadLetterCount,
      isSyncing: isSyncing ?? _isSyncing,
      lastSyncedAt: lastSyncedAt,
      lastErrorReason: lastErrorReason,
      lastErrorCode: lastErrorCode,
      clearLastErrorReason: clearError,
      clearLastErrorCode: clearError,
    );
    unawaited(
      _observability.recordQueueSnapshot(
        pendingCount: pendingCount,
        deadLetterCount: deadLetterCount,
      ),
    );
  }

  Future<void> _processJob(HiveSyncJob job) async {
    final data = jsonDecode(job.payload) as Map<String, dynamic>;

    final collection = job.collection.trim().toLowerCase();
    switch (collection) {
      case 'sessions':
        await _processSessionJob(job: job, data: data);
        return;
      case 'workout_aux':
        await _processWorkoutAuxJob(job: job, data: data);
        return;
      default:
        throw SyncServiceException(
          code: SyncServiceErrorCode.unsupportedCollection,
          message: 'Unsupported collection: ${job.collection}',
        );
    }
  }

  Future<void> _processSessionJob({
    required HiveSyncJob job,
    required Map<String, dynamic> data,
  }) async {
    final gymId = _requiredPayloadString(
      data: data,
      key: 'gymId',
      context: 'session',
    );
    final deviceId = _requiredPayloadString(
      data: data,
      key: 'deviceId',
      context: 'session',
    );

    switch (_normalizeSessionAction(job.action)) {
      case _SessionSyncAction.create:
        await _processCreateSessionJob(
          job: job,
          data: data,
          gymId: gymId,
          deviceId: deviceId,
        );
        return;
      case _SessionSyncAction.delete:
        await _processDeleteSessionJob(
          job: job,
          gymId: gymId,
          deviceId: deviceId,
        );
        return;
    }
  }

  Future<void> _processWorkoutAuxJob({
    required HiveSyncJob job,
    required Map<String, dynamic> data,
  }) async {
    final gymId = _requiredPayloadString(
      data: data,
      key: 'gymId',
      context: 'workout_aux',
    );
    switch (_normalizeWorkoutAuxAction(job.action)) {
      case _WorkoutAuxSyncAction.attemptsAndNoteUpsert:
        await _processAttemptsAndNoteJob(
          data: data,
          gymId: gymId,
          sessionId: job.docId,
        );
        return;
      case _WorkoutAuxSyncAction.snapshotUpsert:
        await _processSnapshotJob(data: data, gymId: gymId);
        return;
      case _WorkoutAuxSyncAction.communityRecord:
        await _processCommunityStatsJob(
          data: data,
          gymId: gymId,
          sessionId: job.docId,
        );
        return;
      case _WorkoutAuxSyncAction.restStatsRecord:
        await _processRestStatsJob(
          data: data,
          gymId: gymId,
          sessionId: job.docId,
        );
        return;
      case _WorkoutAuxSyncAction.xpCreditSession:
        await _processXpCreditJob(
          data: data,
          gymId: gymId,
          sessionId: job.docId,
        );
        return;
      case _WorkoutAuxSyncAction.challengeCheck:
        await _processChallengeCheckJob(data: data, gymId: gymId);
        return;
    }
  }

  _SessionSyncAction _normalizeSessionAction(String rawAction) {
    final action = rawAction.trim().toLowerCase();
    if (action == 'create' || action == 'update') {
      return _SessionSyncAction.create;
    }
    if (action == 'delete') {
      return _SessionSyncAction.delete;
    }
    throw SyncServiceException(
      code: SyncServiceErrorCode.unsupportedAction,
      message: 'Unsupported session action: $rawAction',
    );
  }

  _WorkoutAuxSyncAction _normalizeWorkoutAuxAction(String rawAction) {
    final action = rawAction.trim().toLowerCase();
    switch (action) {
      case 'attempts_and_note_upsert':
        return _WorkoutAuxSyncAction.attemptsAndNoteUpsert;
      case 'snapshot_upsert':
        return _WorkoutAuxSyncAction.snapshotUpsert;
      case 'community_record':
        return _WorkoutAuxSyncAction.communityRecord;
      case 'rest_stats_record':
        return _WorkoutAuxSyncAction.restStatsRecord;
      case 'xp_credit_session':
        return _WorkoutAuxSyncAction.xpCreditSession;
      case 'challenge_check':
        return _WorkoutAuxSyncAction.challengeCheck;
      default:
        throw SyncServiceException(
          code: SyncServiceErrorCode.unsupportedAction,
          message: 'Unsupported workout_aux action: $rawAction',
        );
    }
  }

  String _requiredPayloadString({
    required Map<String, dynamic> data,
    required String key,
    required String context,
  }) {
    final value = (data[key] as String?)?.trim();
    if (value == null || value.isEmpty) {
      throw SyncServiceException(
        code: SyncServiceErrorCode.invalidPayload,
        message: 'Invalid $context payload: missing $key',
      );
    }
    return value;
  }

  Future<void> _processCreateSessionJob({
    required HiveSyncJob job,
    required Map<String, dynamic> data,
    required String gymId,
    required String deviceId,
  }) async {
    final sets = _normalizeSets(data['sets']);
    final userId = (data['userId'] as String? ?? '').trim();
    final exerciseId = (data['exerciseId'] as String? ?? '').trim();
    final queuedAnchorStartTime = DateTime.tryParse(
      data['anchorStartTime'] as String? ?? '',
    );
    final queuedStartTime = DateTime.tryParse(
      data['startTime'] as String? ?? '',
    );
    final sessionTimestamp =
        queuedAnchorStartTime ??
        queuedStartTime ??
        DateTime.tryParse(data['timestamp'] as String? ?? '') ??
        DateTime.now();

    final existingLogs = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('logs')
        .where('sessionId', isEqualTo: job.docId)
        .limit(1)
        .get();
    final hasExistingLogs = existingLogs.docs.isNotEmpty;
    if (sets.isEmpty) {
      debugPrint(
        '[SyncService] Skip create for session=${job.docId}: payload has no sets',
      );
      return;
    }

    final batch = _firestore.batch();
    if (!hasExistingLogs) {
      for (var i = 0; i < sets.length; i++) {
        final set = sets[i];
        final ref = _firestore
            .collection('gyms')
            .doc(gymId)
            .collection('devices')
            .doc(deviceId)
            .collection('logs')
            .doc();
        batch.set(ref, {
          'sessionId': job.docId,
          'userId': userId,
          'deviceId': deviceId,
          'exerciseId': exerciseId,
          'timestamp': Timestamp.fromDate(sessionTimestamp),
          'weight': set['weight'] ?? 0.0,
          'reps': set['reps'] ?? 0,
          'setNumber': i + 1,
          'dropWeightKg': set['dropWeightKg'] ?? 0.0,
          'dropReps': set['dropReps'] ?? 0,
          'isBodyweight': set['isBodyweight'] ?? false,
          'note': data['note'],
        });
      }
    } else {
      debugPrint(
        '[SyncService] Skip log writes for session=${job.docId}: logs already exist',
      );
      return;
    }
    await batch.commit();
  }

  Future<void> _processDeleteSessionJob({
    required HiveSyncJob job,
    required String gymId,
    required String deviceId,
  }) async {
    final logsRef = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('logs');
    final snapshot = await logsRef
        .where('sessionId', isEqualTo: job.docId)
        .get();

    final batch = _firestore.batch();
    if (snapshot.docs.isNotEmpty) {
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
  }

  Future<void> _processAttemptsAndNoteJob({
    required Map<String, dynamic> data,
    required String gymId,
    required String sessionId,
  }) async {
    final deviceId = _requiredPayloadString(
      data: data,
      key: 'deviceId',
      context: 'workout_aux.attempts_and_note_upsert',
    );
    final userId = _requiredPayloadString(
      data: data,
      key: 'userId',
      context: 'workout_aux.attempts_and_note_upsert',
    );
    final attempts = _normalizeMaps(data['attempts']);
    final note = (data['note'] as String?)?.trim() ?? '';
    final username = (data['userName'] as String?)?.trim();
    final gender = (data['gender'] as String?)?.trim();
    final bodyWeightKg = _toDoubleOrNull(data['bodyWeightKg']);
    final isMulti = _toBool(data['isMulti']);

    final batch = _firestore.batch();

    final noteRef = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('userNotes')
        .doc(userId);
    batch.set(noteRef, {
      'note': note,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    for (var i = 0; i < attempts.length; i++) {
      final attempt = attempts[i];
      final weight = _toDouble(attempt['weight']);
      if (weight <= 0) {
        continue;
      }
      final reps = _toInt(attempt['reps']);
      final e1rm = _toDoubleOrNull(attempt['e1rm']);
      final attemptRef = _firestore
          .collection('gyms')
          .doc(gymId)
          .collection('machines')
          .doc(deviceId)
          .collection('attempts')
          .doc('${sessionId}_${i + 1}');
      batch.set(attemptRef, {
        'gymId': gymId,
        'machineId': deviceId,
        'userId': userId,
        'username': (username == null || username.isEmpty) ? userId : username,
        'sessionId': sessionId,
        'isMulti': isMulti,
        'reps': reps,
        'weight': weight,
        if (e1rm != null && e1rm > 0) 'e1rm': e1rm,
        if (gender != null && gender.isNotEmpty) 'gender': gender,
        if (bodyWeightKg != null && bodyWeightKg > 0)
          'bodyWeightKg': bodyWeightKg,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> _processSnapshotJob({
    required Map<String, dynamic> data,
    required String gymId,
  }) async {
    final snapshot = Map<String, dynamic>.from(
      (data['snapshot'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    final sessionId = _requiredPayloadString(
      data: snapshot,
      key: 'sessionId',
      context: 'workout_aux.snapshot_upsert',
    );
    final deviceId = _requiredPayloadString(
      data: snapshot,
      key: 'deviceId',
      context: 'workout_aux.snapshot_upsert',
    );
    final userId = _requiredPayloadString(
      data: snapshot,
      key: 'userId',
      context: 'workout_aux.snapshot_upsert',
    );

    final createdAt =
        DateTime.tryParse(snapshot['createdAt'] as String? ?? '') ??
        DateTime.now();
    final payload = <String, dynamic>{
      'sessionId': sessionId,
      'deviceId': deviceId,
      'exerciseId': snapshot['exerciseId'],
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'note': snapshot['note'],
      'sets': (snapshot['sets'] is List) ? snapshot['sets'] : const <dynamic>[],
      'renderVersion': _toInt(snapshot['renderVersion'], fallback: 1),
      'uiHints': snapshot['uiHints'],
      'primaryMuscleGroupIds': _normalizeStringList(
        snapshot['primaryMuscleGroupIds'],
      ),
      'secondaryMuscleGroupIds': _normalizeStringList(
        snapshot['secondaryMuscleGroupIds'],
      ),
      'muscleGroupRevision': _toIntOrNull(snapshot['muscleGroupRevision']),
    };

    final model = DeviceSessionSnapshot.fromJson(payload);
    await _deviceSource.writeSessionSnapshot(gymId, model);
  }

  Future<void> _processCommunityStatsJob({
    required Map<String, dynamic> data,
    required String gymId,
    required String sessionId,
  }) async {
    final userId = _requiredPayloadString(
      data: data,
      key: 'userId',
      context: 'workout_aux.community_record',
    );
    final localTimestamp =
        DateTime.tryParse(data['localTimestamp'] as String? ?? '') ??
        DateTime.now();
    try {
      await _communityStatsWriter.recordSession(
        gymId: gymId,
        sessionId: sessionId,
        userId: userId,
        username: (data['userName'] as String?)?.trim(),
        avatarUrl: (data['avatarUrl'] as String?)?.trim(),
        localTimestamp: localTimestamp,
        sets: _normalizeMaps(data['sets']),
        setCount: _toIntOrNull(data['setCount']),
        exerciseCount: _toIntOrNull(data['exerciseCount']),
      );
    } on CommunityStatsAlreadyAppliedException {
      // Idempotent path: already applied is considered successful.
    }
  }

  Future<void> _processRestStatsJob({
    required Map<String, dynamic> data,
    required String gymId,
    required String sessionId,
  }) async {
    final userId = _requiredPayloadString(
      data: data,
      key: 'userId',
      context: 'workout_aux.rest_stats_record',
    );
    final deviceId = _requiredPayloadString(
      data: data,
      key: 'deviceId',
      context: 'workout_aux.rest_stats_record',
    );
    final deviceName = _requiredPayloadString(
      data: data,
      key: 'deviceName',
      context: 'workout_aux.rest_stats_record',
    );
    final exerciseId = (data['exerciseId'] as String?)?.trim();
    final exerciseName = (data['exerciseName'] as String?)?.trim();
    final averageActualRestMs = _toDouble(data['averageActualRestMs']);
    final plannedRestMs = _toDoubleOrNull(data['plannedRestMs']);
    final setCount = _toIntOrNull(data['setCount']);
    final sessionDate =
        DateTime.tryParse(data['sessionDate'] as String? ?? '') ??
        DateTime.now();

    final markerRef = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(userId)
        .collection('rest_stats_applied')
        .doc(sessionId);

    await _firestore.runTransaction((tx) async {
      final marker = await tx.get(markerRef);
      if (marker.exists) {
        return;
      }
      final effectiveSetCount = setCount ?? 0;
      final totalRestDuration = effectiveSetCount > 0
          ? averageActualRestMs * effectiveSetCount
          : averageActualRestMs;
      final docId = (exerciseId == null || exerciseId.isEmpty)
          ? deviceId
          : '${deviceId}__$exerciseId';
      final statsRef = _firestore
          .collection('gyms')
          .doc(gymId)
          .collection('users')
          .doc(userId)
          .collection('rest_stats')
          .doc(docId);

      tx.set(markerRef, {
        'sessionId': sessionId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.set(statsRef, {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'exerciseId': exerciseId ?? '',
        'exerciseName': exerciseName ?? '',
        'sampleCount': FieldValue.increment(1),
        'sumActualRestMs': FieldValue.increment(averageActualRestMs),
        'sumActualRestDurationMs': FieldValue.increment(totalRestDuration),
        'sumPlannedRestMs': FieldValue.increment(plannedRestMs ?? 0),
        'plannedSampleCount': FieldValue.increment(
          plannedRestMs != null ? 1 : 0,
        ),
        'lastSessionAt': Timestamp.fromDate(sessionDate),
        'updatedAt': FieldValue.serverTimestamp(),
        if (effectiveSetCount > 0)
          'sumSetCount': FieldValue.increment(effectiveSetCount),
      }, SetOptions(merge: true));
    });
  }

  Future<void> _processXpCreditJob({
    required Map<String, dynamic> data,
    required String gymId,
    required String sessionId,
  }) async {
    final userId = _requiredPayloadString(
      data: data,
      key: 'userId',
      context: 'workout_aux.xp_credit_session',
    );
    final deviceId = _requiredPayloadString(
      data: data,
      key: 'deviceId',
      context: 'workout_aux.xp_credit_session',
    );
    final traceId = (data['traceId'] as String?)?.trim().isNotEmpty == true
        ? (data['traceId'] as String).trim()
        : 'sync-$sessionId';
    final sessionDate =
        DateTime.tryParse(data['sessionDate'] as String? ?? '') ??
        DateTime.now();
    final timeZone = (data['timeZone'] as String?)?.trim();

    await _xpSource.addSessionXp(
      gymId: gymId,
      userId: userId,
      deviceId: deviceId,
      sessionId: sessionId,
      showInLeaderboard: _toBool(data['showInLeaderboard']),
      isMulti: _toBool(data['isMulti']),
      exerciseId: (data['exerciseId'] as String?)?.trim(),
      traceId: traceId,
      sessionDate: sessionDate,
      timeZone: (timeZone == null || timeZone.isEmpty) ? 'UTC' : timeZone,
      primaryMuscleGroupIds: _normalizeStringList(
        data['primaryMuscleGroupIds'],
      ),
      secondaryMuscleGroupIds: _normalizeStringList(
        data['secondaryMuscleGroupIds'],
      ),
    );
  }

  Future<void> _processChallengeCheckJob({
    required Map<String, dynamic> data,
    required String gymId,
  }) async {
    final userId = _requiredPayloadString(
      data: data,
      key: 'userId',
      context: 'workout_aux.challenge_check',
    );
    final deviceId = _requiredPayloadString(
      data: data,
      key: 'deviceId',
      context: 'workout_aux.challenge_check',
    );
    await _challengeSource.checkChallenges(
      gymId: gymId,
      userId: userId,
      deviceId: deviceId,
    );
  }

  List<Map<String, dynamic>> _normalizeMaps(dynamic raw) {
    if (raw is! List) {
      return const <Map<String, dynamic>>[];
    }
    final normalized = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is Map) {
        normalized.add(Map<String, dynamic>.from(item));
      }
    }
    return normalized;
  }

  List<String> _normalizeStringList(dynamic raw) {
    if (raw is! List) {
      return const <String>[];
    }
    return raw.map((item) => item.toString()).toList(growable: false);
  }

  int _toInt(dynamic raw, {int fallback = 0}) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) {
      return int.tryParse(raw.trim()) ?? fallback;
    }
    return fallback;
  }

  int? _toIntOrNull(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) {
      return int.tryParse(raw.trim());
    }
    return null;
  }

  double _toDouble(dynamic raw, {double fallback = 0.0}) {
    if (raw is double) return raw;
    if (raw is num) return raw.toDouble();
    if (raw is String) {
      final normalized = raw.replaceAll(',', '.').trim();
      return double.tryParse(normalized) ?? fallback;
    }
    return fallback;
  }

  double? _toDoubleOrNull(dynamic raw) {
    if (raw == null) return null;
    if (raw is double) return raw;
    if (raw is num) return raw.toDouble();
    if (raw is String) {
      final normalized = raw.replaceAll(',', '.').trim();
      return double.tryParse(normalized);
    }
    return null;
  }

  bool _toBool(dynamic raw, {bool fallback = false}) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final normalized = raw.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return fallback;
  }

  List<Map<String, dynamic>> _normalizeSets(dynamic rawSets) {
    if (rawSets is! List) {
      return const <Map<String, dynamic>>[];
    }
    final normalized = <Map<String, dynamic>>[];
    for (final item in rawSets) {
      if (item is Map) {
        normalized.add(Map<String, dynamic>.from(item));
      }
    }
    return normalized;
  }

  @visibleForTesting
  static SyncJobFailureKind classifyFailure(Object error) {
    if (error is SyncServiceException) {
      return SyncJobFailureKind.permanent;
    }
    if (error is FirebaseException) {
      final code = error.code.trim().toLowerCase();
      if (code == 'permission-denied' &&
          _looksLikeAppCheckFailure(
            '${error.code} ${(error.message ?? '').toLowerCase()}',
          )) {
        return SyncJobFailureKind.transient;
      }
      const permanentCodes = <String>{
        'permission-denied',
        'unauthenticated',
        'invalid-argument',
        'failed-precondition',
        'not-found',
      };
      if (permanentCodes.contains(code)) {
        return SyncJobFailureKind.permanent;
      }
      return SyncJobFailureKind.transient;
    }
    return SyncJobFailureKind.transient;
  }

  Future<void> _handleJobFailure({
    required HiveSyncJob job,
    required Object error,
  }) async {
    var kind = classifyFailure(error);
    if (kind == SyncJobFailureKind.permanent &&
        await _shouldTreatSessionPermissionDeniedAsTransient(
          job: job,
          error: error,
        )) {
      kind = SyncJobFailureKind.transient;
      debugPrint(
        '[SyncService] Reclassify permission-denied as transient for job ${job.id} (likely membership bootstrap race)',
      );
    }
    final isRecoverableAppCheckFailure = _isRecoverableAppCheckFailure(error);
    final now = DateTime.now();
    final errorCode = _extractErrorCode(error);
    final reason = _buildFailureReason(error);
    job.firstFailureAt ??= now;
    job.lastAttempt = now;
    if (errorCode != null && errorCode.isNotEmpty) {
      job.deadLetterErrorCode = errorCode;
    }

    if (kind == SyncJobFailureKind.permanent) {
      if (_isOptionalAuxJob(job)) {
        await _discardOptionalAuxJob(
          job: job,
          reason: reason,
          errorCode: errorCode,
        );
        return;
      }
      if (error is SyncServiceException) {
        debugPrint(
          '[SyncService] Permanent failure for job ${job.id} '
          '(code=${error.code.name}): ${error.message}',
        );
      } else {
        debugPrint(
          '[SyncService] Permanent failure for job ${job.id}: $reason',
        );
      }
      await _moveToDeadLetter(job, reason: reason, errorCode: errorCode);
      return;
    }

    job.retryCount++;
    if (job.retryCount >= _maxRetryCount) {
      if (_isOptionalAuxJob(job)) {
        await _discardOptionalAuxJob(
          job: job,
          reason: 'retry_limit_exceeded: $reason',
          errorCode: errorCode,
        );
        return;
      }
      if (isRecoverableAppCheckFailure) {
        // Keep retrying recoverable App Check failures without polluting
        // dead-letter so UI stays in "pending sync" state.
        job.retryCount = _maxRetryCount - 1;
        await job.save();
        _refreshQueueStatus(
          isSyncing: _isSyncing,
          lastErrorReason: reason,
          lastErrorCode: errorCode,
        );
        return;
      }
      await _moveToDeadLetter(
        job,
        reason: 'retry_limit_exceeded: $reason',
        errorCode: errorCode,
      );
      return;
    }
    debugPrint(
      '[SyncService] Transient failure for job ${job.id} '
      '(retry=${job.retryCount}/$_maxRetryCount): $reason',
    );
    await job.save();
    _refreshQueueStatus(
      isSyncing: _isSyncing,
      lastErrorReason: reason,
      lastErrorCode: errorCode,
    );
  }

  Future<void> _moveToDeadLetter(
    HiveSyncJob job, {
    required String reason,
    String? errorCode,
  }) async {
    if (job.isDeadLetter) {
      return;
    }
    final now = DateTime.now();
    job.isDeadLetter = true;
    job.deadLetterReason = reason;
    if (errorCode != null && errorCode.isNotEmpty) {
      job.deadLetterErrorCode = errorCode;
    }
    job.deadLetterAt = now;
    job.firstFailureAt ??= now;
    job.lastAttempt = now;
    await job.save();
    debugPrint(
      '[SyncService] Job ${job.id} moved to dead-letter '
      '(reason=$reason, code=${job.deadLetterErrorCode ?? 'unknown'})',
    );
    _refreshQueueStatus(
      isSyncing: _isSyncing,
      lastErrorReason: reason,
      lastErrorCode: errorCode,
    );
  }

  String _buildFailureReason(Object error) {
    if (error is SyncServiceException) {
      return '${error.code.name}: ${error.message}';
    }
    if (error is FirebaseException) {
      final msg = (error.message ?? '').trim();
      if (msg.isEmpty) {
        return 'firebase:${error.code}';
      }
      return 'firebase:${error.code}: $msg';
    }
    return error.toString();
  }

  String? _extractErrorCode(Object error) {
    if (error is SyncServiceException) {
      return error.code.name;
    }
    if (error is FirebaseException) {
      final code = error.code.trim().toLowerCase();
      if (code.isNotEmpty) {
        return code;
      }
    }
    return null;
  }

  bool _isOptionalAuxJob(HiveSyncJob job) {
    return job.collection.trim().toLowerCase() == 'workout_aux';
  }

  Future<void> _discardOptionalAuxJob({
    required HiveSyncJob job,
    required String reason,
    String? errorCode,
  }) async {
    debugPrint(
      '[SyncService] Discard optional aux job ${job.id} '
      '(reason=$reason, code=${errorCode ?? 'unknown'})',
    );
    await job.delete();
    _refreshQueueStatus(
      isSyncing: _isSyncing,
      lastErrorReason: reason,
      lastErrorCode: errorCode,
    );
  }

  Future<void> _cleanupOptionalAuxDeadLetters() async {
    final auxDeadLetters = _db.syncJobsBox.values
        .where(
          (job) =>
              job.isDeadLetter &&
              job.collection.trim().toLowerCase() == 'workout_aux',
        )
        .toList(growable: false);
    if (auxDeadLetters.isEmpty) {
      return;
    }
    for (final job in auxDeadLetters) {
      // Optional telemetry jobs must not block UX with permanent red banners.
      await job.delete();
    }
    debugPrint(
      '[SyncService] Removed ${auxDeadLetters.length} optional aux dead-letter jobs',
    );
    _refreshQueueStatus(isSyncing: _isSyncing, clearError: true);
  }

  Future<void> _cleanupJobsForOtherUsers() async {
    final currentUid = _currentAuthUid();
    if (currentUid == null || currentUid.isEmpty) {
      return;
    }
    final foreignJobs = _db.syncJobsBox.values
        .where((job) {
          final jobUid = _extractJobUserId(job);
          if (jobUid == null || jobUid.isEmpty) {
            return false;
          }
          return jobUid != currentUid;
        })
        .toList(growable: false);
    if (foreignJobs.isEmpty) {
      return;
    }
    for (final job in foreignJobs) {
      await job.delete();
    }
    debugPrint(
      '[SyncService] Removed ${foreignJobs.length} sync jobs from other users',
    );
    _refreshQueueStatus(isSyncing: _isSyncing, clearError: true);
  }

  Future<void> _preparePendingJobsForImmediateRetry() async {
    final pending = _db.syncJobsBox.values
        .where((job) => !job.isDeadLetter && job.retryCount > 0)
        .toList(growable: false);
    if (pending.isEmpty) {
      return;
    }
    for (final job in pending) {
      job.lastAttempt = null;
      await job.save();
    }
    _refreshQueueStatus(isSyncing: _isSyncing, clearError: true);
  }

  Future<void> _recoverAppCheckDeadLetters() async {
    final toReplay = _db.syncJobsBox.values
        .where(
          (job) =>
              job.isDeadLetter &&
              _looksLikeAppCheckFailure(job.deadLetterReason),
        )
        .toList(growable: false);
    if (toReplay.isEmpty) {
      return;
    }

    for (final job in toReplay) {
      job.isDeadLetter = false;
      job.deadLetterReason = null;
      job.deadLetterErrorCode = null;
      job.deadLetterAt = null;
      job.firstFailureAt = null;
      job.retryCount = 0;
      job.lastAttempt = null;
      await job.save();
    }
    debugPrint(
      '[SyncService] Re-queued ${toReplay.length} App Check dead-letter jobs',
    );
    _refreshQueueStatus(isSyncing: _isSyncing, clearError: true);
  }

  Future<void> _recoverPermissionDeniedSessionDeadLetters() async {
    final toReplay = _db.syncJobsBox.values
        .where(
          (job) =>
              job.isDeadLetter &&
              job.collection.trim().toLowerCase() == 'sessions' &&
              (job.deadLetterErrorCode ?? '').trim().toLowerCase() ==
                  'permission-denied',
        )
        .toList(growable: false);
    if (toReplay.isEmpty) {
      return;
    }

    for (final job in toReplay) {
      job.isDeadLetter = false;
      job.deadLetterReason = null;
      job.deadLetterErrorCode = null;
      job.deadLetterAt = null;
      job.firstFailureAt = null;
      job.retryCount = 0;
      job.lastAttempt = null;
      await job.save();
    }
    debugPrint(
      '[SyncService] Re-queued ${toReplay.length} legacy permission-denied session dead-letter jobs',
    );
    _refreshQueueStatus(isSyncing: _isSyncing, clearError: true);
  }

  String? _currentAuthUid() {
    try {
      return fb_auth.FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  String? _extractJobUserId(HiveSyncJob job) {
    try {
      final payload = jsonDecode(job.payload);
      if (payload is! Map<String, dynamic>) {
        return null;
      }
      final direct = (payload['userId'] as String?)?.trim();
      if (direct != null && direct.isNotEmpty) {
        return direct;
      }
      final snapshotPayload = payload['snapshot'];
      if (snapshotPayload is Map<String, dynamic>) {
        final nested = (snapshotPayload['userId'] as String?)?.trim();
        if (nested != null && nested.isNotEmpty) {
          return nested;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String? _extractJobGymId(HiveSyncJob job) {
    try {
      final payload = jsonDecode(job.payload);
      if (payload is! Map<String, dynamic>) {
        return null;
      }
      final gymId = (payload['gymId'] as String?)?.trim();
      if (gymId != null && gymId.isNotEmpty) {
        return gymId;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _discardIfForeignUserJob(HiveSyncJob job) async {
    final currentUid = _currentAuthUid();
    if (currentUid == null || currentUid.isEmpty) {
      return false;
    }
    final jobUid = _extractJobUserId(job);
    if (jobUid == null || jobUid.isEmpty || jobUid == currentUid) {
      return false;
    }
    debugPrint(
      '[SyncService] Discard sync job ${job.id} for foreign user $jobUid (current=$currentUid)',
    );
    await job.delete();
    _refreshQueueStatus(isSyncing: _isSyncing, clearError: true);
    return true;
  }

  Future<bool> _shouldTreatSessionPermissionDeniedAsTransient({
    required HiveSyncJob job,
    required Object error,
  }) async {
    if (job.collection.trim().toLowerCase() != 'sessions') {
      return false;
    }
    if (error is! FirebaseException) {
      return false;
    }
    final code = error.code.trim().toLowerCase();
    if (code != 'permission-denied') {
      return false;
    }
    final currentUid = _currentAuthUid();
    final jobUid = _extractJobUserId(job);
    final gymId = _extractJobGymId(job);
    if (jobUid == null || jobUid.isEmpty || gymId == null || gymId.isEmpty) {
      return false;
    }
    if (currentUid != null && currentUid.isNotEmpty && currentUid != jobUid) {
      return false;
    }

    try {
      final membership = await _firestore
          .collection('gyms')
          .doc(gymId)
          .collection('users')
          .doc(jobUid)
          .get();
      if (!membership.exists) {
        return true;
      }
      return false;
    } catch (_) {
      // If we cannot verify membership (network race), keep retrying.
      return true;
    }
  }

  bool _isRecoverableAppCheckFailure(Object error) {
    if (error is FirebaseException) {
      final code = error.code.trim().toLowerCase();
      if (code != 'permission-denied') {
        return false;
      }
      return _looksLikeAppCheckFailure(
        '${error.code} ${(error.message ?? '').toLowerCase()}',
      );
    }
    return _looksLikeAppCheckFailure(error.toString());
  }

  static bool _looksLikeAppCheckFailure(String? raw) {
    final message = (raw ?? '').toLowerCase();
    if (message.isEmpty) {
      return false;
    }
    return message.contains('app check') ||
        message.contains('appcheck') ||
        message.contains('firebaseappcheck.googleapis.com') ||
        message.contains('exchangedevicechecktoken') ||
        message.contains('service_disabled');
  }

  Future<void> addJob({
    required String collection,
    required String docId,
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    final job = HiveSyncJob()
      ..id = const Uuid().v4()
      ..collection = collection
      ..docId = docId
      ..action = action
      ..payload = jsonEncode(payload)
      ..createdAt = DateTime.now()
      ..retryCount = 0
      ..isDeadLetter = false
      ..deadLetterReason = null
      ..deadLetterErrorCode = null
      ..firstFailureAt = null
      ..deadLetterAt = null
      ..lastAttempt = null;

    await _db.syncJobsBox.add(job);

    debugPrint('[SyncService] Added sync job: $collection/$docId ($action)');
    _refreshQueueStatus(isSyncing: _isSyncing);

    // Trigger sync immediately if online
    syncPendingJobs();
  }

  Future<int> replayDeadLetterJobs({String? onlyErrorCode}) async {
    final normalizedCode = onlyErrorCode?.trim().toLowerCase();
    final deadLetterJobs = _db.syncJobsBox.values.where((job) {
      if (!job.isDeadLetter) {
        return false;
      }
      if (normalizedCode == null || normalizedCode.isEmpty) {
        return true;
      }
      return (job.deadLetterErrorCode ?? '').trim().toLowerCase() ==
          normalizedCode;
    }).toList();
    for (final job in deadLetterJobs) {
      job.isDeadLetter = false;
      job.deadLetterReason = null;
      job.deadLetterErrorCode = null;
      job.deadLetterAt = null;
      job.firstFailureAt = null;
      job.retryCount = 0;
      job.lastAttempt = null;
      await job.save();
    }
    if (deadLetterJobs.isNotEmpty) {
      debugPrint(
        '[SyncService] Replayed ${deadLetterJobs.length} dead-letter jobs',
      );
    }
    _refreshQueueStatus(isSyncing: _isSyncing, clearError: true);
    return deadLetterJobs.length;
  }
}
