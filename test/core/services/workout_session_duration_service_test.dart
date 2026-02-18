import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/firebase_provider.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';

class _TestableWorkoutSessionDurationService
    extends WorkoutSessionDurationService {
  _TestableWorkoutSessionDurationService()
    : super(firestore: FakeFirebaseFirestore());

  int saveCallCount = 0;

  @override
  Future<void> save({DateTime? endTime, String? sessionId}) async {
    saveCallCount++;
  }
}

Future<void> _pumpEventQueue([int times = 20]) async {
  for (var i = 0; i < times; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

AuthViewState _authState({String? gymId, String? userId}) {
  return AuthViewState(
    isLoading: false,
    isLoggedIn: gymId != null && userId != null,
    isGuest: false,
    isAdmin: false,
    isCoach: false,
    gymContextStatus: gymId != null
        ? GymContextStatus.ready
        : GymContextStatus.unknown,
    gymCode: gymId,
    userId: userId,
    error: null,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('auto stop does not trigger save automatically', () async {
    final service = _TestableWorkoutSessionDurationService();
    await _pumpEventQueue();

    await service.start(uid: 'user', gymId: 'gym');
    await service.registerSession(sessionId: 's1', completedAt: DateTime.now());

    await Future<void>.delayed(const Duration(milliseconds: 220));

    expect(service.saveCallCount, 0);
    expect(service.isRunning, isTrue);

    service.dispose();
  });

  test('state survives restart without forcing a save', () async {
    final service = _TestableWorkoutSessionDurationService();
    await _pumpEventQueue();

    await service.start(uid: 'user', gymId: 'gym');
    await service.registerSession(sessionId: 's1', completedAt: DateTime.now());

    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(service.saveCallCount, 0);
    expect(service.isRunning, isTrue);

    final restarted = _TestableWorkoutSessionDurationService();
    await _pumpEventQueue();
    await restarted.setActiveContext(uid: 'user', gymId: 'gym');

    expect(restarted.isRunning, isTrue);
    expect(restarted.elapsed, isNot(Duration.zero));
    expect(restarted.saveCallCount, 0);

    service.dispose();
    restarted.dispose();
  });

  test('provider detaches auth listeners on dispose', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final authState = StateController(
      _authState(gymId: 'gym1', userId: 'user1'),
    );
    final container = ProviderContainer(
      overrides: [
        firebaseFirestoreProvider.overrideWith(
          (ref) => FakeFirebaseFirestore(),
        ),
        authViewStateProvider.overrideWith((ref) => authState.state),
      ],
    );
    addTearDown(container.dispose);

    container.read(workoutSessionDurationServiceProvider);
    container.invalidate(workoutSessionDurationServiceProvider);

    authState.state = _authState(gymId: 'gym2', userId: 'user1');

    expect(() => container.invalidate(authViewStateProvider), returnsNormally);
  });

  test(
    'save across midnight keeps start day and writes anchor fields',
    () async {
      final firestore = FakeFirebaseFirestore();
      final start = DateTime(2026, 2, 12, 23, 10);
      final end = DateTime(2026, 2, 13, 0, 20);
      const uid = 'user';
      const gymId = 'gym';
      const sessionId = 'session-midnight';

      SharedPreferences.setMockInitialValues(<String, Object>{
        'workoutTimer:$uid::$gymId': jsonEncode(<String, dynamic>{
          'startEpochMs': start.millisecondsSinceEpoch,
          'uid': uid,
          'gymId': gymId,
        }),
      });

      final service = WorkoutSessionDurationService(firestore: firestore);
      await _pumpEventQueue();
      await service.setActiveContext(uid: uid, gymId: gymId);
      await service.save(endTime: end, sessionId: sessionId);

      final doc = await firestore
          .collection('gyms')
          .doc(gymId)
          .collection('users')
          .doc(uid)
          .collection('session_meta')
          .doc(sessionId)
          .get();
      final data = doc.data();

      expect(data, isNotNull);
      expect(data!['dayKey'], '2026-02-12');
      expect(data['anchorDayKey'], '2026-02-12');
      expect(data['anchorStartEpochMs'], start.millisecondsSinceEpoch);
      expect(
        (data['anchorStartTime'] as Timestamp).toDate().millisecondsSinceEpoch,
        start.millisecondsSinceEpoch,
      );
      expect(
        (data['startTime'] as Timestamp).toDate().millisecondsSinceEpoch,
        start.millisecondsSinceEpoch,
      );
      expect(
        (data['endTime'] as Timestamp).toDate().millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      );
      expect(
        data['durationMs'],
        end.millisecondsSinceEpoch - start.millisecondsSinceEpoch,
      );

      final pending = await service.getPendingCompletions(userId: uid);
      expect(pending, hasLength(1));
      expect(pending.first.dayKey, '2026-02-12');

      service.dispose();
    },
  );

  test('flushQueue normalizes legacy payload with anchor fields', () async {
    final firestore = FakeFirebaseFirestore();
    final start = DateTime(2026, 2, 12, 23, 55);
    final end = DateTime(2026, 2, 13, 0, 5);
    const uid = 'user-q';
    const gymId = 'gym-q';
    const sessionId = 'queued-session';

    SharedPreferences.setMockInitialValues(<String, Object>{
      'workoutTimerQueue': <String>[
        jsonEncode(<String, dynamic>{
          'sessionId': sessionId,
          'uid': uid,
          'gymId': gymId,
          'startTime': start.toIso8601String(),
          'endTime': end.toIso8601String(),
          'durationMs':
              end.millisecondsSinceEpoch - start.millisecondsSinceEpoch,
          'tz': 'Europe/Berlin',
        }),
      ],
    });

    final service = WorkoutSessionDurationService(firestore: firestore);
    await _pumpEventQueue(40);

    final doc = await firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(uid)
        .collection('session_meta')
        .doc(sessionId)
        .get();
    final data = doc.data();
    expect(data, isNotNull);
    expect(data!['dayKey'], '2026-02-12');
    expect(data['anchorDayKey'], '2026-02-12');
    expect(data['anchorStartEpochMs'], start.millisecondsSinceEpoch);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('workoutTimerQueue'), isEmpty);

    service.dispose();
  });

  test(
    'recovery: malformed timer/completion queue payloads are ignored safely',
    () async {
      const uid = 'user-r';
      const gymId = 'gym-r';
      final start = DateTime(2026, 2, 13, 18, 0);
      final end = start.add(const Duration(minutes: 42));

      SharedPreferences.setMockInitialValues(<String, Object>{
        'workoutTimer:$uid::$gymId': '{broken-json',
        'workoutTimerQueue': <String>[
          '{not-json',
          jsonEncode(<String, dynamic>{'sessionId': 'missing-fields'}),
        ],
        'workoutTimerCompletionQueue': <String>[
          '{broken',
          jsonEncode(<String, dynamic>{'key': 'incomplete', 'gymId': gymId}),
          jsonEncode(<String, dynamic>{
            'key': 'valid',
            'gymId': gymId,
            'userId': uid,
            'dayKey': '2026-02-13',
            'startEpochMs': start.millisecondsSinceEpoch,
            'endEpochMs': end.millisecondsSinceEpoch,
            'durationMs':
                end.millisecondsSinceEpoch - start.millisecondsSinceEpoch,
            'sessionId': 'session-valid',
          }),
        ],
      });

      final service = WorkoutSessionDurationService(
        firestore: FakeFirebaseFirestore(),
      );
      await _pumpEventQueue(40);
      await service.setActiveContext(uid: uid, gymId: gymId);

      expect(service.isRunning, isFalse);
      expect(service.startTime, isNull);

      final pending = await service.getPendingCompletions(userId: uid);
      expect(pending, hasLength(1));
      expect(pending.first.sessionId, 'session-valid');
      expect(pending.first.dayKey, '2026-02-13');

      service.dispose();
    },
  );
}
