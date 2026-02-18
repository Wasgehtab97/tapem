import 'dart:convert';
import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/services/workout_session_coordinator.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';

class _FakeDurationService extends WorkoutSessionDurationService {
  _FakeDurationService() : super(firestore: FakeFirebaseFirestore());

  bool _running = false;
  DateTime? _startedAt;
  DateTime? _lastActivityAt;
  int startCalls = 0;
  int discardCalls = 0;
  int registerSetCalls = 0;
  Completer<void>? startCompleter;
  Completer<void>? registerSetCompleter;

  @override
  bool get isRunning => _running;

  @override
  DateTime? get startTime => _startedAt;

  @override
  DateTime? get lastActivityTime => _lastActivityAt;

  void seedRunning({required DateTime startedAt, DateTime? lastActivityAt}) {
    _running = true;
    _startedAt = startedAt;
    _lastActivityAt = lastActivityAt;
  }

  @override
  Future<void> start({required String uid, required String gymId}) async {
    final completer = startCompleter;
    if (completer != null) {
      await completer.future;
    }
    startCalls += 1;
    _running = true;
    _startedAt ??= DateTime.now();
    _lastActivityAt = null;
  }

  @override
  Future<void> discard() async {
    discardCalls += 1;
    _running = false;
    _startedAt = null;
    _lastActivityAt = null;
  }

  @override
  Future<void> registerSetCompletion({DateTime? completedAt}) async {
    final completer = registerSetCompleter;
    if (completer != null) {
      await completer.future;
    }
    registerSetCalls += 1;
    _lastActivityAt = completedAt ?? DateTime.now();
  }
}

Future<void> _pumpEventQueue([int times = 20]) async {
  for (var i = 0; i < times; i += 1) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('first set completion starts running session with anchor day', () async {
    final durationService = _FakeDurationService();
    final coordinator = WorkoutSessionCoordinator(
      durationService: durationService,
      inactivityDelay: const Duration(minutes: 1),
    );

    final completedAt = DateTime(2026, 2, 12, 23, 40);
    await coordinator.onFirstSetCompleted(
      uid: 'user-1',
      gymId: 'gym-1',
      completedAt: completedAt,
    );

    expect(coordinator.isRunning, isTrue);
    expect(coordinator.anchorDayKey, '2026-02-12');
    expect(
      coordinator.anchorStartAt?.millisecondsSinceEpoch,
      completedAt.millisecondsSinceEpoch,
    );
    expect(
      coordinator.lastSetCompletedAt?.millisecondsSinceEpoch,
      completedAt.millisecondsSinceEpoch,
    );
    expect(durationService.startCalls, 1);
    expect(durationService.registerSetCalls, 1);

    coordinator.dispose();
    durationService.dispose();
  });

  test('inactivity timeout auto-finalizes with last set timestamp', () async {
    final durationService = _FakeDurationService();
    final coordinator = WorkoutSessionCoordinator(
      durationService: durationService,
      inactivityDelay: const Duration(milliseconds: 120),
    );
    final completedAt = DateTime.now();
    DateTime? handledAt;

    coordinator.setAutoFinalizeHandler((lastSetCompletedAt) async {
      handledAt = lastSetCompletedAt;
      await coordinator.finishAutomaticallyAfterInactivity(
        lastSetCompletedAt: lastSetCompletedAt,
      );
    });

    await coordinator.onSetCompleted(
      uid: 'user-1',
      gymId: 'gym-1',
      completedAt: completedAt,
    );

    await Future<void>.delayed(const Duration(milliseconds: 260));

    expect(
      handledAt?.millisecondsSinceEpoch,
      completedAt.millisecondsSinceEpoch,
    );
    expect(coordinator.isRunning, isFalse);
    expect(
      coordinator.finalizedAt?.millisecondsSinceEpoch,
      completedAt.millisecondsSinceEpoch,
    );
    expect(
      coordinator.finalizeReason,
      WorkoutFinalizeReason.autoInactivity.name,
    );

    coordinator.dispose();
    durationService.dispose();
  });

  test(
    'auto-finalize handler failure retries with backoff instead of tight loop',
    () async {
      final durationService = _FakeDurationService();
      final coordinator = WorkoutSessionCoordinator(
        durationService: durationService,
        inactivityDelay: const Duration(milliseconds: 50),
        autoFinalizeRetryDelay: const Duration(milliseconds: 120),
      );
      var calls = 0;

      coordinator.setAutoFinalizeHandler((_) async {
        calls += 1;
        throw StateError('boom');
      });

      await coordinator.onSetCompleted(uid: 'user-1', gymId: 'gym-1');
      await Future<void>.delayed(const Duration(milliseconds: 260));

      expect(calls, greaterThanOrEqualTo(1));
      expect(calls, lessThanOrEqualTo(2));

      coordinator.dispose();
      durationService.dispose();
    },
  );

  test(
    'auto-finalize across midnight keeps start-day anchor and uses last set as end time',
    () async {
      final durationService = _FakeDurationService();
      final coordinator = WorkoutSessionCoordinator(
        durationService: durationService,
        inactivityDelay: const Duration(milliseconds: 120),
      );
      final startedAt = DateTime(2026, 2, 12, 23, 0);
      final lastSetAt = DateTime(2026, 2, 12, 23, 40);

      coordinator.setAutoFinalizeHandler((lastSetCompletedAt) async {
        await coordinator.finishAutomaticallyAfterInactivity(
          lastSetCompletedAt: lastSetCompletedAt,
        );
      });

      await coordinator.startFromProfilePlay(
        uid: 'user-1',
        gymId: 'gym-1',
        startedAt: startedAt,
      );
      await coordinator.onSetCompleted(
        uid: 'user-1',
        gymId: 'gym-1',
        completedAt: lastSetAt,
      );

      await Future<void>.delayed(const Duration(milliseconds: 260));

      expect(coordinator.anchorDayKey, '2026-02-12');
      expect(
        coordinator.anchorStartAt?.millisecondsSinceEpoch,
        startedAt.millisecondsSinceEpoch,
      );
      expect(
        coordinator.finalizedAt?.millisecondsSinceEpoch,
        lastSetAt.millisecondsSinceEpoch,
      );
      expect(
        coordinator.finalizeReason,
        WorkoutFinalizeReason.autoInactivity.name,
      );

      coordinator.dispose();
      durationService.dispose();
    },
  );

  test(
    'restart recovery triggers immediate auto-finalize when overdue',
    () async {
      final now = DateTime.now();
      final lastSet = now.subtract(const Duration(hours: 2));
      final anchorStart = lastSet.subtract(const Duration(minutes: 30));

      SharedPreferences.setMockInitialValues(<String, Object>{
        'workoutCoordinator:user-1::gym-1': jsonEncode(<String, dynamic>{
          'isRunning': true,
          'anchorStartEpochMs': anchorStart.millisecondsSinceEpoch,
          'anchorDayKey': '2026-02-12',
          'lastSetCompletedEpochMs': lastSet.millisecondsSinceEpoch,
          'finalizedEpochMs': null,
          'finalizeReason': null,
        }),
      });

      final durationService = _FakeDurationService();
      final coordinator = WorkoutSessionCoordinator(
        durationService: durationService,
        inactivityDelay: const Duration(hours: 1),
      );

      var autoFinalizeCalls = 0;
      DateTime? recoveredLastSet;
      coordinator.setAutoFinalizeHandler((lastSetCompletedAt) async {
        autoFinalizeCalls += 1;
        recoveredLastSet = lastSetCompletedAt;
        await coordinator.finishAutomaticallyAfterInactivity(
          lastSetCompletedAt: lastSetCompletedAt,
        );
      });

      await coordinator.setActiveContext(uid: 'user-1', gymId: 'gym-1');
      await _pumpEventQueue(40);

      expect(autoFinalizeCalls, greaterThanOrEqualTo(1));
      expect(
        recoveredLastSet?.millisecondsSinceEpoch,
        lastSet.millisecondsSinceEpoch,
      );
      expect(coordinator.isRunning, isFalse);
      expect(
        coordinator.finalizeReason,
        WorkoutFinalizeReason.autoInactivity.name,
      );

      coordinator.dispose();
      durationService.dispose();
    },
  );

  test(
    'soak: 60 start/finalize cycles keep anchor + end timestamp stable',
    () async {
      final durationService = _FakeDurationService();
      final coordinator = WorkoutSessionCoordinator(
        durationService: durationService,
        inactivityDelay: const Duration(minutes: 1),
      );

      for (var i = 0; i < 60; i += 1) {
        final startedAt = DateTime(
          2026,
          1,
          1,
        ).add(Duration(days: i, hours: 23));
        final lastSetAt = startedAt.add(const Duration(minutes: 37));

        await coordinator.startFromProfilePlay(
          uid: 'user-1',
          gymId: 'gym-1',
          startedAt: startedAt,
        );
        await coordinator.onSetCompleted(
          uid: 'user-1',
          gymId: 'gym-1',
          completedAt: lastSetAt,
        );
        await coordinator.finishAutomaticallyAfterInactivity(
          lastSetCompletedAt: lastSetAt,
        );

        expect(
          coordinator.anchorDayKey,
          '${startedAt.year.toString().padLeft(4, '0')}-${startedAt.month.toString().padLeft(2, '0')}-${startedAt.day.toString().padLeft(2, '0')}',
        );
        expect(
          coordinator.anchorStartAt?.millisecondsSinceEpoch,
          startedAt.millisecondsSinceEpoch,
        );
        expect(
          coordinator.finalizedAt?.millisecondsSinceEpoch,
          lastSetAt.millisecondsSinceEpoch,
        );
        expect(
          coordinator.finalizeReason,
          WorkoutFinalizeReason.autoInactivity.name,
        );
        expect(coordinator.isRunning, isFalse);
      }

      coordinator.dispose();
      durationService.dispose();
    },
  );

  test(
    'recovery: malformed persisted coordinator state is ignored defensively',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'workoutCoordinator:user-1::gym-1': '{invalid-json',
      });

      final durationService = _FakeDurationService();
      final coordinator = WorkoutSessionCoordinator(
        durationService: durationService,
        inactivityDelay: const Duration(minutes: 1),
      );

      await coordinator.setActiveContext(uid: 'user-1', gymId: 'gym-1');

      expect(coordinator.isRunning, isFalse);
      expect(coordinator.anchorDayKey, isNull);
      expect(coordinator.anchorStartAt, isNull);
      expect(coordinator.lastSetCompletedAt, isNull);
      expect(coordinator.finalizedAt, isNull);
      expect(coordinator.finalizeReason, isNull);

      coordinator.dispose();
      durationService.dispose();
    },
  );

  test(
    'startFromProfilePlay exits safely when coordinator gets disposed mid-await',
    () async {
      final durationService = _FakeDurationService();
      final startCompleter = Completer<void>();
      durationService.startCompleter = startCompleter;
      final coordinator = WorkoutSessionCoordinator(
        durationService: durationService,
        inactivityDelay: const Duration(minutes: 1),
      );

      final future = coordinator.startFromProfilePlay(
        uid: 'user-1',
        gymId: 'gym-1',
      );
      await Future<void>.delayed(Duration.zero);
      coordinator.dispose();
      startCompleter.complete();

      await future;
      durationService.dispose();
    },
  );

  test(
    'late set completion after manual finalize does not revive session',
    () async {
      final durationService = _FakeDurationService();
      final coordinator = WorkoutSessionCoordinator(
        durationService: durationService,
        inactivityDelay: const Duration(minutes: 1),
      );
      final startedAt = DateTime(2026, 2, 13, 22, 0, 0);
      final finalizedAt = DateTime(2026, 2, 13, 22, 10, 0);
      final lateSetAt = DateTime(2026, 2, 13, 22, 12, 0);

      await coordinator.startFromProfilePlay(
        uid: 'user-1',
        gymId: 'gym-1',
        startedAt: startedAt,
      );
      await coordinator.finishManuallyFromWorkoutSave(finalizedAt: finalizedAt);
      await durationService.discard();
      await coordinator.onSetCompleted(
        uid: 'user-1',
        gymId: 'gym-1',
        completedAt: lateSetAt,
      );

      expect(coordinator.isRunning, isFalse);
      expect(
        coordinator.finalizedAt?.millisecondsSinceEpoch,
        finalizedAt.millisecondsSinceEpoch,
      );
      expect(coordinator.finalizeReason, WorkoutFinalizeReason.manualSave.name);
      expect(durationService.startCalls, 1);
      expect(durationService.registerSetCalls, 0);

      coordinator.dispose();
      durationService.dispose();
    },
  );

  test(
    'duplicate manual finalize is skipped and keeps first finalize metadata',
    () async {
      final durationService = _FakeDurationService();
      final coordinator = WorkoutSessionCoordinator(
        durationService: durationService,
        inactivityDelay: const Duration(minutes: 1),
      );
      final startedAt = DateTime(2026, 2, 13, 22, 0, 0);
      final firstFinalizedAt = DateTime(2026, 2, 13, 22, 10, 0);
      final secondFinalizedAt = DateTime(2026, 2, 13, 22, 10, 5);

      await coordinator.startFromProfilePlay(
        uid: 'user-1',
        gymId: 'gym-1',
        startedAt: startedAt,
      );
      await coordinator.finishManuallyFromWorkoutSave(
        finalizedAt: firstFinalizedAt,
      );
      final firstToken = coordinator.finalizeToken;
      await coordinator.finishManuallyFromWorkoutSave(
        finalizedAt: secondFinalizedAt,
      );

      expect(coordinator.isRunning, isFalse);
      expect(
        coordinator.finalizedAt?.millisecondsSinceEpoch,
        firstFinalizedAt.millisecondsSinceEpoch,
      );
      expect(coordinator.finalizeReason, WorkoutFinalizeReason.manualSave.name);
      expect(coordinator.finalizeToken, firstToken);

      coordinator.dispose();
      durationService.dispose();
    },
  );

  test(
    'new set completion after explicit add-intent starts a fresh session',
    () async {
      final durationService = _FakeDurationService();
      final coordinator = WorkoutSessionCoordinator(
        durationService: durationService,
        inactivityDelay: const Duration(minutes: 1),
      );
      final startedAt = DateTime(2026, 2, 13, 22, 0, 0);
      final finalizedAt = DateTime(2026, 2, 13, 22, 10, 0);
      final newSetAt = DateTime(2026, 2, 13, 22, 12, 0);

      await coordinator.startFromProfilePlay(
        uid: 'user-1',
        gymId: 'gym-1',
        startedAt: startedAt,
      );
      await coordinator.finishManuallyFromWorkoutSave(finalizedAt: finalizedAt);
      await durationService.discard();
      await coordinator.onExerciseAddedFromGymOrNfc(
        uid: 'user-1',
        gymId: 'gym-1',
      );
      await coordinator.onSetCompleted(
        uid: 'user-1',
        gymId: 'gym-1',
        completedAt: newSetAt,
      );

      expect(coordinator.isRunning, isTrue);
      expect(
        coordinator.anchorStartAt?.millisecondsSinceEpoch,
        newSetAt.millisecondsSinceEpoch,
      );
      expect(coordinator.finalizedAt, isNull);
      expect(coordinator.finalizeReason, isNull);
      expect(durationService.startCalls, 2);
      expect(durationService.registerSetCalls, 1);

      coordinator.dispose();
      durationService.dispose();
    },
  );

  test(
    'profile play recovers from stale running marker when timer is idle',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'workoutCoordinator:user-1::gym-1': jsonEncode(<String, dynamic>{
          'isRunning': true,
          'anchorStartEpochMs': DateTime(
            2026,
            2,
            13,
            20,
            0,
          ).millisecondsSinceEpoch,
          'anchorDayKey': '2026-02-13',
          'lastSetCompletedEpochMs': DateTime(
            2026,
            2,
            13,
            20,
            10,
          ).millisecondsSinceEpoch,
          'finalizedEpochMs': null,
          'finalizeReason': null,
        }),
      });

      final durationService = _FakeDurationService();
      final coordinator = WorkoutSessionCoordinator(
        durationService: durationService,
        inactivityDelay: const Duration(minutes: 1),
      );

      await coordinator.setActiveContext(uid: 'user-1', gymId: 'gym-1');
      expect(coordinator.isRunning, isTrue);
      expect(durationService.isRunning, isFalse);

      await coordinator.startFromProfilePlay(uid: 'user-1', gymId: 'gym-1');

      expect(coordinator.isRunning, isTrue);
      expect(durationService.isRunning, isTrue);
      expect(durationService.startCalls, 1);

      coordinator.dispose();
      durationService.dispose();
    },
  );

  test('resume lifecycle triggers overdue inactivity auto-finalize', () async {
    final durationService = _FakeDurationService();
    final coordinator = WorkoutSessionCoordinator(
      durationService: durationService,
      inactivityDelay: const Duration(hours: 1),
    );
    final startedAt = DateTime.now().subtract(const Duration(hours: 3));
    final lastSetAt = DateTime.now().subtract(const Duration(hours: 2));

    var autoFinalizeCalls = 0;
    coordinator.setAutoFinalizeHandler((lastSetCompletedAt) async {
      autoFinalizeCalls += 1;
      await coordinator.finishAutomaticallyAfterInactivity(
        lastSetCompletedAt: lastSetCompletedAt,
      );
    });

    await coordinator.startFromProfilePlay(
      uid: 'user-1',
      gymId: 'gym-1',
      startedAt: startedAt,
    );
    await coordinator.onSetCompleted(
      uid: 'user-1',
      gymId: 'gym-1',
      completedAt: lastSetAt,
    );

    coordinator.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await _pumpEventQueue(40);

    expect(autoFinalizeCalls, 1);
    expect(coordinator.isRunning, isFalse);
    expect(
      coordinator.finalizedAt?.millisecondsSinceEpoch,
      lastSetAt.millisecondsSinceEpoch,
    );
    expect(
      coordinator.finalizeReason,
      WorkoutFinalizeReason.autoInactivity.name,
    );

    coordinator.dispose();
    durationService.dispose();
  });

  test(
    'recovery uses duration last activity when coordinator state misses last set',
    () async {
      final now = DateTime.now();
      final startedAt = now.subtract(const Duration(hours: 3));
      final lastActivityAt = now.subtract(const Duration(hours: 2));

      SharedPreferences.setMockInitialValues(<String, Object>{
        'workoutCoordinator:user-1::gym-1': jsonEncode(<String, dynamic>{
          'isRunning': true,
          'anchorStartEpochMs': startedAt.millisecondsSinceEpoch,
          'anchorDayKey': '2026-02-13',
          'lastSetCompletedEpochMs': null,
          'finalizedEpochMs': null,
          'finalizeReason': null,
        }),
      });

      final durationService = _FakeDurationService()
        ..seedRunning(startedAt: startedAt, lastActivityAt: lastActivityAt);
      final coordinator = WorkoutSessionCoordinator(
        durationService: durationService,
        inactivityDelay: const Duration(hours: 1),
      );

      var autoFinalizeCalls = 0;
      DateTime? handledLastSetAt;
      coordinator.setAutoFinalizeHandler((lastSetCompletedAt) async {
        autoFinalizeCalls += 1;
        handledLastSetAt = lastSetCompletedAt;
        await coordinator.finishAutomaticallyAfterInactivity(
          lastSetCompletedAt: lastSetCompletedAt,
        );
      });

      await coordinator.setActiveContext(uid: 'user-1', gymId: 'gym-1');
      await _pumpEventQueue(40);

      expect(autoFinalizeCalls, greaterThanOrEqualTo(1));
      expect(
        handledLastSetAt?.millisecondsSinceEpoch,
        lastActivityAt.millisecondsSinceEpoch,
      );
      expect(coordinator.isRunning, isFalse);
      expect(
        coordinator.finalizedAt?.millisecondsSinceEpoch,
        lastActivityAt.millisecondsSinceEpoch,
      );
      expect(
        coordinator.finalizeReason,
        WorkoutFinalizeReason.autoInactivity.name,
      );

      coordinator.dispose();
      durationService.dispose();
    },
  );
}
