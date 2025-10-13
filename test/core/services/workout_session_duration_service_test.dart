import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const timezoneChannel = MethodChannel('plugins.flutter.io/flutter_timezone');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    timezoneChannel.setMockMethodCallHandler((methodCall) async {
      if (methodCall.method == 'getLocalTimezone') {
        return 'Europe/Berlin';
      }
      return null;
    });
  });

  tearDown(() {
    timezoneChannel.setMockMethodCallHandler(null);
  });

  test('auto stop after inactivity stores duration using last session timestamp', () async {
    final firestore = FakeFirebaseFirestore();
    final service = WorkoutSessionDurationService(
      firestore: firestore,
      autoStopDelay: const Duration(milliseconds: 50),
    );
    addTearDown(service.dispose);

    await service.start(uid: 'u1', gymId: 'g1');
    final endTime = DateTime.now().add(const Duration(minutes: 90));
    await service.registerSession(sessionId: 'session-1', completedAt: endTime);

    // wait for the auto stop timer to trigger
    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(service.isRunning, isFalse);

    final doc = await firestore
        .collection('gyms')
        .doc('g1')
        .collection('users')
        .doc('u1')
        .collection('session_meta')
        .doc('session-1')
        .get();

    expect(doc.exists, isTrue);
    final data = doc.data()!;
    final startTs = data['startTime'] as Timestamp;
    final endTs = data['endTime'] as Timestamp;
    expect(endTs.toDate(), endTime);
    final expectedDuration =
        endTime.millisecondsSinceEpoch - startTs.toDate().millisecondsSinceEpoch;
    expect(data['durationMs'], expectedDuration);
  });

  test('auto stop after inactivity uses last set completion timestamp', () async {
    final firestore = FakeFirebaseFirestore();
    final service = WorkoutSessionDurationService(
      firestore: firestore,
      autoStopDelay: const Duration(milliseconds: 50),
    );
    addTearDown(service.dispose);

    await service.start(uid: 'u1', gymId: 'g1');
    final setCompletion = DateTime.now().add(const Duration(minutes: 45));
    await service.registerSetCompletion(completedAt: setCompletion);

    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(service.isRunning, isFalse);

    final snap = await firestore
        .collection('gyms')
        .doc('g1')
        .collection('users')
        .doc('u1')
        .collection('session_meta')
        .get();

    expect(snap.docs, hasLength(1));
    final data = snap.docs.single.data();
    final startTs = data['startTime'] as Timestamp;
    final endTs = data['endTime'] as Timestamp;
    expect(endTs.toDate(), setCompletion);
    final expectedDuration = setCompletion.millisecondsSinceEpoch -
        startTs.toDate().millisecondsSinceEpoch;
    expect(data['durationMs'], expectedDuration);
  });

  test('setActiveContext isolates timers per user and gym', () async {
    final firestore = FakeFirebaseFirestore();
    final service = WorkoutSessionDurationService(firestore: firestore);
    addTearDown(service.dispose);

    await service.start(uid: 'userA', gymId: 'gymA');
    expect(service.isRunning, isTrue);

    await service.setActiveContext(uid: 'userB', gymId: 'gymB');
    expect(service.isRunning, isFalse);

    final second = WorkoutSessionDurationService(firestore: firestore);
    addTearDown(second.dispose);
    await second.setActiveContext(uid: 'userA', gymId: 'gymA');
    expect(second.isRunning, isTrue);
  });

  test('legacy persisted state migrates to user and gym key', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'workoutTimer:u1': jsonEncode({
        'startEpochMs': now,
        'uid': 'u1',
        'gymId': 'g1',
      }),
    });

    final firestore = FakeFirebaseFirestore();
    final service = WorkoutSessionDurationService(firestore: firestore);
    addTearDown(service.dispose);

    await service.setActiveContext(uid: 'u1', gymId: 'g1');
    expect(service.isRunning, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('workoutTimer:u1::g1'), isNotNull);
    expect(prefs.getString('workoutTimer:u1'), isNull);
  });

  test('emits day completed event after manual save', () async {
    final firestore = FakeFirebaseFirestore();
    final service = WorkoutSessionDurationService(firestore: firestore);
    addTearDown(service.dispose);

    await service.start(uid: 'userA', gymId: 'gymA');
    final events = <SessionDayCompleted>[];
    final sub = service.dayCompletedStream.listen(events.add);
    addTearDown(sub.cancel);

    await service.save(endTime: DateTime.now(), sessionId: 'session-42');

    expect(events, hasLength(1));
    final event = events.single;
    expect(event.uid, 'userA');
    expect(event.gymId, 'gymA');
    expect(event.sessionId, 'session-42');
    expect(event.autoFinalized, isFalse);
  });
}
