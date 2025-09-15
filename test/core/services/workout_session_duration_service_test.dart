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
}
