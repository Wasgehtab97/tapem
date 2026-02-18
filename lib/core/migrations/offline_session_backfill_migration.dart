import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/database/database_service.dart';
import 'package:tapem/core/storage/local_training_days_store.dart';
import 'package:tapem/core/sync/models/hive_sync_job.dart';
import 'package:tapem/core/time/logic_day.dart';
import 'package:tapem/features/training_details/data/models/hive_session.dart';
import 'package:uuid/uuid.dart';

/// One-time migration to backfill local offline projections from existing sessions.
class OfflineSessionBackfillMigration {
  static const String _migrationKey = 'migration_offline_session_backfill_v1';

  static Future<bool> hasRun() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migrationKey) ?? false;
  }

  static Future<void> _markAsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationKey, true);
  }

  static Future<Map<String, dynamic>> run(
    DatabaseService databaseService, {
    LocalTrainingDaysStore? trainingDaysStore,
    DateTime Function()? now,
    Uuid? uuid,
  }) async {
    debugPrint('🧭 Starting offline session backfill migration...');
    if (await hasRun()) {
      debugPrint('⏭️  Offline backfill migration already completed, skipping');
      return {'skipped': true, 'reason': 'already_run'};
    }

    final store = trainingDaysStore ?? const LocalTrainingDaysStore();
    final nowProvider = now ?? DateTime.now;
    final idProvider = uuid ?? const Uuid();

    try {
      final sessions = databaseService.sessionsBox.values.toList(
        growable: false,
      );
      final dayIndex = buildLocalDayIndex(sessions);

      var usersBackfilled = 0;
      var totalWrittenDayKeys = 0;
      for (final entry in dayIndex.entries) {
        final userId = entry.key;
        final existing = await store.readDayKeys(userId);
        final merged = <String>{...existing, ...entry.value}.toList()..sort();
        final changed =
            merged.length != existing.length || !listEquals(merged, existing);
        if (!changed) {
          continue;
        }
        await store.writeDayKeys(userId, merged);
        usersBackfilled++;
        totalWrittenDayKeys += merged.length;
      }

      final missingJobs = buildMissingSessionCreateJobs(
        sessions: sessions,
        existingJobs: databaseService.syncJobsBox.values,
        now: nowProvider,
        uuid: idProvider,
      );
      for (final job in missingJobs) {
        await databaseService.syncJobsBox.add(job);
      }

      await _markAsCompleted();

      final result = <String, dynamic>{
        'success': true,
        'scannedSessions': sessions.length,
        'usersBackfilled': usersBackfilled,
        'writtenDayKeys': totalWrittenDayKeys,
        'enqueuedSessionSyncJobs': missingJobs.length,
      };
      debugPrint('✅ Offline backfill migration completed: $result');
      return result;
    } catch (error, stackTrace) {
      debugPrint('❌ Offline backfill migration failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return {'success': false, 'error': error.toString()};
    }
  }

  @visibleForTesting
  static Map<String, Set<String>> buildLocalDayIndex(
    Iterable<HiveSession> sessions,
  ) {
    final index = <String, Set<String>>{};
    for (final session in sessions) {
      final userId = session.userId.trim();
      if (userId.isEmpty) {
        continue;
      }
      final anchor = (session.startTime ?? session.timestamp).toLocal();
      final dayKey = logicDayKey(anchor);
      index.putIfAbsent(userId, () => <String>{}).add(dayKey);
    }
    return index;
  }

  @visibleForTesting
  static List<HiveSyncJob> buildMissingSessionCreateJobs({
    required Iterable<HiveSession> sessions,
    required Iterable<HiveSyncJob> existingJobs,
    required DateTime Function() now,
    required Uuid uuid,
  }) {
    final existingCreateOrUpdateIds = <String>{
      for (final job in existingJobs)
        if (job.collection.trim().toLowerCase() == 'sessions' &&
            (job.action.trim().toLowerCase() == 'create' ||
                job.action.trim().toLowerCase() == 'update') &&
            job.docId.trim().isNotEmpty)
          job.docId.trim(),
    };
    final existingDeleteIds = <String>{
      for (final job in existingJobs)
        if (job.collection.trim().toLowerCase() == 'sessions' &&
            job.action.trim().toLowerCase() == 'delete' &&
            job.docId.trim().isNotEmpty)
          job.docId.trim(),
    };

    final latestBySessionId = <String, HiveSession>{};
    for (final session in sessions) {
      final sessionId = session.sessionId.trim();
      if (sessionId.isEmpty) {
        continue;
      }
      final previous = latestBySessionId[sessionId];
      if (previous == null || session.updatedAt.isAfter(previous.updatedAt)) {
        latestBySessionId[sessionId] = session;
      }
    }

    final sorted = latestBySessionId.values.toList()
      ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));

    final jobs = <HiveSyncJob>[];
    for (final session in sorted) {
      final sessionId = session.sessionId.trim();
      if (existingCreateOrUpdateIds.contains(sessionId)) {
        continue;
      }
      if (existingDeleteIds.contains(sessionId)) {
        continue;
      }
      jobs.add(_buildCreateJob(session: session, now: now, uuid: uuid));
    }
    return jobs;
  }

  static HiveSyncJob _buildCreateJob({
    required HiveSession session,
    required DateTime Function() now,
    required Uuid uuid,
  }) {
    final anchorStart = (session.startTime ?? session.timestamp).toLocal();
    final anchorDayKey = logicDayKey(anchorStart);
    final payload = <String, dynamic>{
      'sessionId': session.sessionId,
      'gymId': session.gymId,
      'userId': session.userId,
      'deviceId': session.deviceId,
      'deviceName': session.deviceName,
      'deviceDescription': session.deviceDescription,
      'timestamp': session.timestamp.toIso8601String(),
      'startTime': session.startTime?.toIso8601String(),
      'endTime': session.endTime?.toIso8601String(),
      'durationMs': session.durationMs,
      'anchorStartTime': anchorStart.toIso8601String(),
      'anchorDayKey': anchorDayKey,
      'sets': [
        for (final set in session.sets)
          {
            'weight': set.weight,
            'reps': set.reps,
            'setNumber': set.setNumber,
            'dropWeightKg': set.dropWeightKg,
            'dropReps': set.dropReps,
            'isBodyweight': set.isBodyweight,
          },
      ],
      'note': session.note ?? '',
      'exerciseId': session.exerciseId ?? '',
      'exerciseName': session.exerciseName ?? '',
      'isMulti': session.isMulti,
    };

    return HiveSyncJob()
      ..id = uuid.v4()
      ..collection = 'sessions'
      ..docId = session.sessionId
      ..action = 'create'
      ..payload = jsonEncode(payload)
      ..createdAt = now()
      ..retryCount = 0
      ..lastAttempt = null
      ..isDeadLetter = false
      ..deadLetterReason = null
      ..deadLetterErrorCode = null
      ..firstFailureAt = null
      ..deadLetterAt = null;
  }
}
