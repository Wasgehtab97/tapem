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
    await service.registerSession(
      sessionId: 'session-1',
      completedAt: endTime,
      setCount: 3,
      totalVolume: 120,
      exerciseId: 'ex-1',
      note: 'session note',
    );

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

  test('session document reflects activity lifecycle', () async {
    final firestore = FakeFirebaseFirestore();
    final service = WorkoutSessionDurationService(
      firestore: firestore,
      autoStopDelay: const Duration(milliseconds: 50),
    );
    addTearDown(service.dispose);

    await service.start(uid: 'u1', gymId: 'g1');
    final completedAt = DateTime.now();
    await service.registerSession(
      sessionId: 'session-1',
      completedAt: completedAt,
      setCount: 5,
      totalVolume: 180,
      exerciseId: 'ex-1',
      note: 'focus',
    );

    final doc = await firestore
        .collection('users')
        .doc('u1')
        .collection('sessions')
        .doc('session-1')
        .get();

    expect(doc.exists, isTrue);
    final data = doc.data()!;
    expect(data['status'], 'open');
    expect(data['gymId'], 'g1');
    final summary = data['summary'] as Map<String, dynamic>;
    expect(summary['setCount'], 5);
    expect(summary['exerciseCount'], 1);
    expect((summary['totalVolume'] as num).toDouble(), 180);
    final lastActivity = (data['lastActivityAt'] as Timestamp).toDate();
    expect(lastActivity.difference(completedAt).inMilliseconds.abs(), lessThan(500));
  });

  test('manual save closes session with now endAt', () async {
    final firestore = FakeFirebaseFirestore();
    final service = WorkoutSessionDurationService(
      firestore: firestore,
      autoStopDelay: const Duration(milliseconds: 50),
    );
    addTearDown(service.dispose);

    await service.start(uid: 'u1', gymId: 'g1');
    final completedAt = DateTime.now();
    await service.registerSession(
      sessionId: 'session-1',
      completedAt: completedAt,
      setCount: 4,
      totalVolume: 160,
      exerciseId: 'ex-1',
    );

    final before = DateTime.now();
    await service.save();
    final after = DateTime.now();

    final doc = await firestore
        .collection('users')
        .doc('u1')
        .collection('sessions')
        .doc('session-1')
        .get();
    final data = doc.data()!;
    expect(data['status'], 'closed');
    final endAt = (data['endAt'] as Timestamp).toDate();
    expect(endAt.isAfter(before) || endAt.isAtSameMomentAs(before), isTrue);
    expect(endAt.isBefore(after) || endAt.isAtSameMomentAs(after), isTrue);
  });

  test('idle auto close respects inactivity window', () async {
    final firestore = FakeFirebaseFirestore();
    final service = WorkoutSessionDurationService(
      firestore: firestore,
      autoStopDelay: const Duration(milliseconds: 50),
    );
    addTearDown(service.dispose);

    await service.start(uid: 'u1', gymId: 'g1');
    final completedAt = DateTime.now();
    await service.registerSession(
      sessionId: 'session-1',
      completedAt: completedAt,
      setCount: 2,
      totalVolume: 40,
      exerciseId: 'ex-1',
    );

    await Future<void>.delayed(const Duration(milliseconds: 200));

    final doc = await firestore
        .collection('users')
        .doc('u1')
        .collection('sessions')
        .doc('session-1')
        .get();
    final data = doc.data()!;
    expect(data['status'], 'closed');
    final endAt = (data['endAt'] as Timestamp).toDate();
    final expected = completedAt.add(const Duration(milliseconds: 50));
    expect(endAt.difference(expected).inMilliseconds.abs(), lessThan(60));
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
}
