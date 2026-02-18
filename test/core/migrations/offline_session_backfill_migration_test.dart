import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/migrations/offline_session_backfill_migration.dart';
import 'package:tapem/core/sync/models/hive_sync_job.dart';
import 'package:tapem/features/training_details/data/models/hive_session.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('OfflineSessionBackfillMigration.buildLocalDayIndex', () {
    test('builds per-user day sets and prefers startTime over timestamp', () {
      final sessions = <HiveSession>[
        _session(
          sessionId: 's-1',
          userId: 'user-a',
          timestamp: DateTime(2026, 2, 14, 10, 0),
          startTime: DateTime(2026, 2, 13, 23, 45),
          updatedAt: DateTime(2026, 2, 14, 10, 1),
        ),
        _session(
          sessionId: 's-2',
          userId: 'user-a',
          timestamp: DateTime(2026, 2, 13, 12, 0),
          updatedAt: DateTime(2026, 2, 13, 12, 1),
        ),
        _session(
          sessionId: 's-3',
          userId: 'user-a',
          timestamp: DateTime(2026, 2, 14, 8, 0),
          updatedAt: DateTime(2026, 2, 14, 8, 1),
        ),
        _session(
          sessionId: 's-4',
          userId: 'user-b',
          timestamp: DateTime(2026, 2, 12, 9, 0),
          updatedAt: DateTime(2026, 2, 12, 9, 1),
        ),
        _session(
          sessionId: 's-5',
          userId: '   ',
          timestamp: DateTime(2026, 2, 11, 9, 0),
          updatedAt: DateTime(2026, 2, 11, 9, 1),
        ),
      ];

      final index = OfflineSessionBackfillMigration.buildLocalDayIndex(
        sessions,
      );

      expect(index.keys, unorderedEquals(<String>['user-a', 'user-b']));
      expect(index['user-a'], equals(<String>{'2026-02-13', '2026-02-14'}));
      expect(index['user-b'], equals(<String>{'2026-02-12'}));
    });
  });

  group('OfflineSessionBackfillMigration.buildMissingSessionCreateJobs', () {
    test(
      'creates jobs only for missing sessions and uses latest duplicate',
      () {
        final now = DateTime(2026, 2, 15, 8, 30);
        final sessions = <HiveSession>[
          _session(
            sessionId: 'session-a',
            userId: 'user-1',
            timestamp: DateTime(2026, 2, 10, 10, 0),
            updatedAt: DateTime(2026, 2, 10, 10, 1),
          ),
          _session(
            sessionId: 'session-b',
            userId: 'user-1',
            timestamp: DateTime(2026, 2, 11, 10, 0),
            updatedAt: DateTime(2026, 2, 11, 10, 1),
          ),
          _session(
            sessionId: 'session-c',
            userId: 'user-1',
            timestamp: DateTime(2026, 2, 12, 10, 0),
            updatedAt: DateTime(2026, 2, 12, 10, 1),
          ),
          _session(
            sessionId: 'session-d',
            userId: 'user-1',
            timestamp: DateTime(2026, 2, 13, 10, 0),
            startTime: DateTime(2026, 2, 13, 9, 50),
            note: 'old note',
            updatedAt: DateTime(2026, 2, 13, 10, 1),
            sets: <HiveSessionSet>[_set(weight: 80.0, reps: 8)],
          ),
          _session(
            sessionId: 'session-e',
            userId: 'user-2',
            timestamp: DateTime(2026, 2, 14, 10, 0),
            updatedAt: DateTime(2026, 2, 14, 10, 1),
            sets: <HiveSessionSet>[_set(weight: 90.0, reps: 5)],
          ),
          _session(
            sessionId: 'session-d',
            userId: 'user-1',
            timestamp: DateTime(2026, 2, 13, 10, 0),
            startTime: DateTime(2026, 2, 13, 9, 55),
            note: 'latest note',
            updatedAt: DateTime(2026, 2, 15, 7, 0),
            sets: <HiveSessionSet>[_set(weight: 82.5, reps: 7)],
          ),
          _session(
            sessionId: '   ',
            userId: 'user-3',
            timestamp: DateTime(2026, 2, 9, 10, 0),
            updatedAt: DateTime(2026, 2, 9, 10, 1),
          ),
        ];

        final existingJobs = <HiveSyncJob>[
          _syncJob(docId: 'session-a', action: 'create'),
          _syncJob(docId: 'session-b', action: 'UPDATE'),
          _syncJob(docId: 'session-c', action: 'delete'),
        ];

        final jobs =
            OfflineSessionBackfillMigration.buildMissingSessionCreateJobs(
              sessions: sessions,
              existingJobs: existingJobs,
              now: () => now,
              uuid: const Uuid(),
            );

        expect(
          jobs.map((job) => job.docId).toList(),
          equals(<String>['session-e', 'session-d']),
        );
        expect(jobs.every((job) => job.collection == 'sessions'), isTrue);
        expect(jobs.every((job) => job.action == 'create'), isTrue);
        expect(jobs.every((job) => job.createdAt == now), isTrue);
        expect(jobs.every((job) => job.retryCount == 0), isTrue);
        expect(jobs.every((job) => job.isDeadLetter == false), isTrue);
        expect(jobs.every((job) => job.id.isNotEmpty), isTrue);
        expect(jobs[0].id == jobs[1].id, isFalse);

        final latestSessionPayload =
            jsonDecode(jobs.last.payload) as Map<String, dynamic>;
        expect(latestSessionPayload['sessionId'], 'session-d');
        expect(latestSessionPayload['note'], 'latest note');
        expect(latestSessionPayload['anchorDayKey'], '2026-02-13');
        expect(latestSessionPayload['startTime'], isNotNull);
        final sets = latestSessionPayload['sets'] as List<dynamic>;
        expect(sets, hasLength(1));
        final firstSet = sets.first as Map<String, dynamic>;
        expect(firstSet['weight'], 82.5);
        expect(firstSet['reps'], 7);
      },
    );
  });
}

HiveSyncJob _syncJob({required String docId, required String action}) {
  return HiveSyncJob()
    ..id = 'job-$docId-$action'
    ..collection = 'sessions'
    ..docId = docId
    ..action = action
    ..payload = '{}'
    ..createdAt = DateTime(2026, 2, 10, 0, 0)
    ..retryCount = 0
    ..lastAttempt = null
    ..isDeadLetter = false
    ..deadLetterReason = null
    ..deadLetterErrorCode = null
    ..firstFailureAt = null
    ..deadLetterAt = null;
}

HiveSession _session({
  required String sessionId,
  required String userId,
  required DateTime timestamp,
  DateTime? startTime,
  DateTime? updatedAt,
  String? note,
  List<HiveSessionSet>? sets,
}) {
  return HiveSession()
    ..sessionId = sessionId
    ..gymId = 'gym-1'
    ..userId = userId
    ..deviceId = 'device-1'
    ..deviceName = 'Leg Press'
    ..deviceDescription = 'Machine'
    ..isMulti = false
    ..exerciseId = null
    ..exerciseName = null
    ..timestamp = timestamp
    ..startTime = startTime
    ..endTime = null
    ..durationMs = 0
    ..note = note
    ..sets = sets ?? <HiveSessionSet>[_set()]
    ..updatedAt = updatedAt ?? timestamp;
}

HiveSessionSet _set({double weight = 100.0, int reps = 5, int setNumber = 1}) {
  return HiveSessionSet()
    ..weight = weight
    ..reps = reps
    ..setNumber = setNumber
    ..dropWeightKg = 0
    ..dropReps = 0
    ..isBodyweight = false;
}
