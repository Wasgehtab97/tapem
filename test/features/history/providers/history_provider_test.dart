
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/firebase_provider.dart';
import 'package:tapem/features/history/domain/models/workout_log.dart';
import 'package:tapem/features/history/domain/usecases/get_history_for_device.dart';
import 'package:tapem/features/history/providers/history_provider.dart';

class _FakeHistoryRepo implements GetHistoryForDeviceRepository {
  List<WorkoutLog> logs = const [];
  int calls = 0;

  @override
  Future<List<WorkoutLog>> getHistory({
    required String gymId,
    required String deviceId,
    required String userId,
    String? exerciseId,
  }) async {
    calls++;
    return logs;
  }
}

AuthViewState _authState({String? gymId, String? userId}) {
  return AuthViewState(
    isLoading: false,
    isLoggedIn: gymId != null && userId != null,
    isAdmin: false,
    gymContextStatus:
        gymId != null ? GymContextStatus.ready : GymContextStatus.unknown,
    gymCode: gymId,
    userId: userId,
    error: null,
  );
}

WorkoutLog _log(int i) {
  return WorkoutLog(
    id: 'log$i',
    userId: 'user1',
    sessionId: 'session$i',
    exerciseId: 'ex$i',
    timestamp: DateTime(2024, 1, i + 1),
    weight: 100.0 + i,
    reps: 5,
    setNumber: i + 1,
  );
}

Future<void> _pumpEventQueue() async {
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test('historyProvider clears when auth context changes', () async {
    final repo = _FakeHistoryRepo();
    repo.logs = List.generate(2, _log);
    final authState = StateController(_authState(gymId: 'gym1', userId: 'user1'));
    final container = ProviderContainer(
      overrides: [
        getHistoryForDeviceProvider.overrideWith((ref) => GetHistoryForDevice(repo)),
        authViewStateProvider.overrideWith((ref) => authState.state),
        firebaseFirestoreProvider.overrideWith((ref) => FakeFirebaseFirestore()),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(historyProvider);
    await notifier.loadHistory(
      gymId: 'gym1',
      deviceId: 'dev1',
      userId: 'user1',
    );
    expect(repo.calls, 1);
    expect(notifier.logs, isNotEmpty);

    authState.state = _authState(gymId: 'gym2', userId: 'user1');
    container.invalidate(authViewStateProvider);
    await _pumpEventQueue();

    expect(notifier.logs, isEmpty);
  });
}
