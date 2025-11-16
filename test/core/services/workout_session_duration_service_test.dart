import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';

class _TestableWorkoutSessionDurationService
    extends WorkoutSessionDurationService {
  _TestableWorkoutSessionDurationService({
    required Duration autoStopDelay,
  }) : super(
          firestore: FakeFirebaseFirestore(),
          autoStopDelay: autoStopDelay,
        );

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('auto stop does not trigger save automatically', () async {
    final service = _TestableWorkoutSessionDurationService(
      autoStopDelay: const Duration(milliseconds: 120),
    );
    await _pumpEventQueue();

    await service.start(uid: 'user', gymId: 'gym');
    await service.registerSession(
      sessionId: 's1',
      completedAt: DateTime.now(),
    );

    await Future<void>.delayed(const Duration(milliseconds: 220));

    expect(service.saveCallCount, 0);
    expect(service.isRunning, isTrue);

    service.dispose();
  });

  test('state survives restart without forcing a save', () async {
    final service = _TestableWorkoutSessionDurationService(
      autoStopDelay: const Duration(milliseconds: 100),
    );
    await _pumpEventQueue();

    await service.start(uid: 'user', gymId: 'gym');
    await service.registerSession(
      sessionId: 's1',
      completedAt: DateTime.now(),
    );

    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(service.saveCallCount, 0);
    expect(service.isRunning, isTrue);

    final restarted = _TestableWorkoutSessionDurationService(
      autoStopDelay: const Duration(seconds: 5),
    );
    await _pumpEventQueue();
    await restarted.setActiveContext(uid: 'user', gymId: 'gym');

    expect(restarted.isRunning, isTrue);
    expect(restarted.elapsed, isNot(Duration.zero));
    expect(restarted.saveCallCount, 0);

    service.dispose();
    restarted.dispose();
  });
}
