import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tapem/core/database/database_service.dart';
import 'package:tapem/core/sync/models/hive_sync_job.dart';
import 'package:tapem/core/sync/sync_service.dart';

class _MockDatabaseService extends Mock implements DatabaseService {}

class _MockSyncJobBox extends Mock implements Box<HiveSyncJob> {}

class _TestHiveSyncJob extends HiveSyncJob {
  int saveCalls = 0;
  int deleteCalls = 0;

  @override
  Future<void> save() async {
    saveCalls++;
  }

  @override
  Future<void> delete() async {
    deleteCalls++;
  }
}

HiveSyncJob _buildJob({
  required String id,
  required String docId,
  required String action,
  required Map<String, dynamic> payload,
  String collection = 'sessions',
}) {
  final job = _TestHiveSyncJob()
    ..id = id
    ..collection = collection
    ..docId = docId
    ..action = action
    ..payload = jsonEncode(payload)
    ..createdAt = DateTime(2026, 2, 13, 10, 0)
    ..retryCount = 0
    ..lastAttempt = null
    ..isDeadLetter = false
    ..deadLetterReason = null
    ..deadLetterErrorCode = null
    ..firstFailureAt = null
    ..deadLetterAt = null;
  return job;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore firestore;
  late _MockDatabaseService db;
  late _MockSyncJobBox syncJobsBox;
  late SyncService syncService;
  late List<HiveSyncJob> queuedJobs;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    db = _MockDatabaseService();
    syncJobsBox = _MockSyncJobBox();
    queuedJobs = <HiveSyncJob>[];

    when(() => db.syncJobsBox).thenReturn(syncJobsBox);
    when(() => syncJobsBox.values).thenAnswer((_) => queuedJobs);

    syncService = SyncService(db, firestore: firestore);
  });

  test('create jobs are idempotent via existing logs check', () async {
    final payload = <String, dynamic>{
      'gymId': 'gym-1',
      'deviceId': 'device-1',
      'userId': 'user-1',
      'anchorDayKey': '2026-02-13',
      'timestamp': DateTime(2026, 2, 13, 10, 0).toIso8601String(),
      'sets': <Map<String, dynamic>>[
        {'weight': 80.0, 'reps': 8, 'setNumber': 1},
        {'weight': 85.0, 'reps': 6, 'setNumber': 2},
      ],
    };

    final job1 = _buildJob(
      id: 'job-1',
      docId: 'session-1',
      action: 'create',
      payload: payload,
    );
    final job2 = _buildJob(
      id: 'job-2',
      docId: 'session-1',
      action: 'create',
      payload: payload,
    );
    queuedJobs = <HiveSyncJob>[job1, job2];

    await syncService.syncPendingJobs();

    final logs = await firestore
        .collection('gyms')
        .doc('gym-1')
        .collection('devices')
        .doc('device-1')
        .collection('logs')
        .where('sessionId', isEqualTo: 'session-1')
        .get();
    expect(logs.docs.length, 2);

    expect((job1 as _TestHiveSyncJob).deleteCalls, 1);
    expect((job2 as _TestHiveSyncJob).deleteCalls, 1);
  });

  test(
    'delete jobs are idempotent and do not recreate deleted sessions',
    () async {
      final createPayload = <String, dynamic>{
        'gymId': 'gym-1',
        'deviceId': 'device-1',
        'userId': 'user-1',
        'anchorDayKey': '2026-02-13',
        'timestamp': DateTime(2026, 2, 13, 10, 0).toIso8601String(),
        'sets': <Map<String, dynamic>>[
          {'weight': 100.0, 'reps': 5, 'setNumber': 1},
        ],
      };
      final createJob = _buildJob(
        id: 'job-create',
        docId: 'session-2',
        action: 'create',
        payload: createPayload,
      );
      queuedJobs = <HiveSyncJob>[createJob];
      await syncService.syncPendingJobs();

      final deletePayload = <String, dynamic>{
        'gymId': 'gym-1',
        'deviceId': 'device-1',
        'anchorDayKey': '2026-02-13',
        'anchorStartTime': DateTime(2026, 2, 13, 10, 0).toIso8601String(),
      };
      final deleteJob1 = _buildJob(
        id: 'job-delete-1',
        docId: 'session-2',
        action: 'delete',
        payload: deletePayload,
      );
      final deleteJob2 = _buildJob(
        id: 'job-delete-2',
        docId: 'session-2',
        action: 'delete',
        payload: deletePayload,
      );
      queuedJobs = <HiveSyncJob>[deleteJob1, deleteJob2];
      await syncService.syncPendingJobs();

      final logsAfterDelete = await firestore
          .collection('gyms')
          .doc('gym-1')
          .collection('devices')
          .doc('device-1')
          .collection('logs')
          .where('sessionId', isEqualTo: 'session-2')
          .get();
      expect(logsAfterDelete.docs, isEmpty);

      expect((createJob as _TestHiveSyncJob).deleteCalls, 1);
      expect((deleteJob1 as _TestHiveSyncJob).deleteCalls, 1);
      expect((deleteJob2 as _TestHiveSyncJob).deleteCalls, 1);
    },
  );

  test(
    'invalid payload is moved to dead-letter and no longer retried',
    () async {
      final invalidPayload = <String, dynamic>{
        'deviceId': 'device-1',
        'userId': 'user-1',
        'sets': <Map<String, dynamic>>[
          {'weight': 80.0, 'reps': 8, 'setNumber': 1},
        ],
      };
      final job =
          _buildJob(
                id: 'job-invalid',
                docId: 'session-invalid',
                action: 'create',
                payload: invalidPayload,
              )
              as _TestHiveSyncJob;
      queuedJobs = <HiveSyncJob>[job];

      await syncService.syncPendingJobs();

      expect(job.isDeadLetter, isTrue);
      expect(job.deadLetterReason, contains('invalidPayload'));
      expect(job.saveCalls, 1);
      expect(job.deleteCalls, 0);

      await syncService.syncPendingJobs();
      expect(job.saveCalls, 1, reason: 'dead-letter jobs must not retry again');
    },
  );

  test('replayDeadLetterJobs resets dead-letter flags', () async {
    final job =
        _buildJob(
                id: 'job-dead',
                docId: 'session-dead',
                action: 'create',
                payload: <String, dynamic>{
                  'gymId': 'gym-1',
                  'deviceId': 'device-1',
                },
              )
              as _TestHiveSyncJob
          ..isDeadLetter = true
          ..deadLetterReason = 'permission-denied'
          ..deadLetterErrorCode = 'permission-denied'
          ..retryCount = 4
          ..deadLetterAt = DateTime(2026, 2, 14, 12, 0)
          ..lastAttempt = DateTime(2026, 2, 14, 11, 0)
          ..firstFailureAt = DateTime(2026, 2, 14, 11, 0);
    queuedJobs = <HiveSyncJob>[job];

    final replayed = await syncService.replayDeadLetterJobs();
    expect(replayed, 1);
    expect(job.isDeadLetter, isFalse);
    expect(job.deadLetterReason, isNull);
    expect(job.deadLetterErrorCode, isNull);
    expect(job.deadLetterAt, isNull);
    expect(job.firstFailureAt, isNull);
    expect(job.retryCount, 0);
    expect(job.lastAttempt, isNull);
  });

  test(
    'replayed dead-letter create stays idempotent with duplicate create job',
    () async {
      final invalidJob =
          _buildJob(
                id: 'job-replay-invalid',
                docId: 'session-replay',
                action: 'create',
                payload: <String, dynamic>{
                  'deviceId': 'device-1',
                  'userId': 'user-1',
                },
              )
              as _TestHiveSyncJob;
      queuedJobs = <HiveSyncJob>[invalidJob];

      await syncService.syncPendingJobs();
      expect(invalidJob.isDeadLetter, isTrue);

      final validPayload = <String, dynamic>{
        'gymId': 'gym-1',
        'deviceId': 'device-1',
        'userId': 'user-1',
        'anchorDayKey': '2026-02-13',
        'timestamp': DateTime(2026, 2, 13, 10, 0).toIso8601String(),
        'sets': <Map<String, dynamic>>[
          {'weight': 90.0, 'reps': 6, 'setNumber': 1},
        ],
      };
      invalidJob.payload = jsonEncode(validPayload);

      final duplicateCreateJob =
          _buildJob(
                id: 'job-replay-duplicate',
                docId: 'session-replay',
                action: 'create',
                payload: validPayload,
              )
              as _TestHiveSyncJob;
      queuedJobs = <HiveSyncJob>[invalidJob, duplicateCreateJob];

      final replayed = await syncService.replayDeadLetterJobs();
      expect(replayed, 1);
      expect(invalidJob.isDeadLetter, isFalse);

      await syncService.syncPendingJobs();

      final logs = await firestore
          .collection('gyms')
          .doc('gym-1')
          .collection('devices')
          .doc('device-1')
          .collection('logs')
          .where('sessionId', isEqualTo: 'session-replay')
          .get();
      expect(logs.docs.length, 1);

      expect(invalidJob.deleteCalls, 1);
      expect(duplicateCreateJob.deleteCalls, 1);
    },
  );

  test('permission denied is classified as permanent', () {
    final error = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message: 'Missing or insufficient permissions.',
    );
    expect(SyncService.classifyFailure(error), SyncJobFailureKind.permanent);
  });

  test('app check permission denied is classified as transient', () {
    final error = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message:
          'AppCheck failed: SERVICE_DISABLED firebaseappcheck.googleapis.com',
    );
    expect(SyncService.classifyFailure(error), SyncJobFailureKind.transient);
  });

  test('workout aux attempts+note jobs are persisted and deleted', () async {
    final job =
        _buildJob(
              id: 'job-aux-1',
              collection: 'workout_aux',
              docId: 'session-aux-1',
              action: 'attempts_and_note_upsert',
              payload: <String, dynamic>{
                'gymId': 'gym-1',
                'deviceId': 'device-1',
                'userId': 'user-1',
                'note': 'great set',
                'attempts': <Map<String, dynamic>>[
                  {'weight': 100.0, 'reps': 5, 'e1rm': 116.67},
                ],
              },
            )
            as _TestHiveSyncJob;
    queuedJobs = <HiveSyncJob>[job];

    await syncService.syncPendingJobs();

    final noteDoc = await firestore
        .collection('gyms')
        .doc('gym-1')
        .collection('devices')
        .doc('device-1')
        .collection('userNotes')
        .doc('user-1')
        .get();
    expect(noteDoc.exists, isTrue);
    expect(noteDoc.data()?['note'], 'great set');

    final attemptDoc = await firestore
        .collection('gyms')
        .doc('gym-1')
        .collection('machines')
        .doc('device-1')
        .collection('attempts')
        .doc('session-aux-1_1')
        .get();
    expect(attemptDoc.exists, isTrue);
    expect(attemptDoc.data()?['weight'], 100.0);
    expect(attemptDoc.data()?['reps'], 5);
    expect(job.deleteCalls, 1);
  });

  test('invalid optional workout aux job is discarded (no dead-letter)', () async {
    final job =
        _buildJob(
              id: 'job-aux-invalid',
              collection: 'workout_aux',
              docId: 'session-aux-invalid',
              action: 'attempts_and_note_upsert',
              payload: <String, dynamic>{
                // gymId present, but required keys for this action are missing
                // -> invalidPayload (permanent) should discard optional aux job
                // instead of moving it to dead-letter.
                'gymId': 'gym-1',
                'deviceId': 'device-1',
              },
            )
            as _TestHiveSyncJob;
    queuedJobs = <HiveSyncJob>[job];

    await syncService.syncPendingJobs();

    expect(job.isDeadLetter, isFalse);
    expect(job.deleteCalls, 1);
  });
}
