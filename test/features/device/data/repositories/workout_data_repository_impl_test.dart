import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/features/device/data/local/workout_context_cache_store.dart';
import 'package:tapem/features/device/data/repositories/workout_data_repository_impl.dart';
import 'package:tapem/features/device/data/sources/firestore_workout_context_source.dart';
import 'package:tapem/features/device/domain/models/workout_device_xp_state.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';
import 'package:tapem/features/training_details/domain/repositories/session_repository.dart';

class _MockSessionRepository extends Mock implements SessionRepository {}

class _FakeWorkoutContextRemoteSource implements WorkoutContextRemoteSource {
  String? nextNote;
  WorkoutDeviceXpState? nextXp;
  Object? noteError;
  Object? xpError;

  @override
  Future<String> fetchUserNote({
    required String gymId,
    required String deviceId,
    required String userId,
  }) async {
    final error = noteError;
    if (error != null) {
      throw error;
    }
    return nextNote ?? '';
  }

  @override
  Future<WorkoutDeviceXpState> fetchUserDeviceXp({
    required String gymId,
    required String deviceId,
    required String userId,
  }) async {
    final error = xpError;
    if (error != null) {
      throw error;
    }
    return nextXp ?? WorkoutDeviceXpState.initial;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockSessionRepository sessionRepository;
  late _FakeWorkoutContextRemoteSource remoteSource;
  late WorkoutContextCacheStore cacheStore;
  late WorkoutDataRepositoryImpl repository;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    sessionRepository = _MockSessionRepository();
    remoteSource = _FakeWorkoutContextRemoteSource();
    cacheStore = const WorkoutContextCacheStore();
    repository = WorkoutDataRepositoryImpl(
      sessionRepository: sessionRepository,
      remoteSource: remoteSource,
      cacheStore: cacheStore,
    );
  });

  test('returns cached note when remote read fails', () async {
    await cacheStore.writeUserNote(
      gymId: 'gym-1',
      deviceId: 'device-1',
      userId: 'user-1',
      note: 'lokale notiz',
    );
    remoteSource.noteError = Exception('offline');

    final note = await repository.getUserNote(
      gymId: 'gym-1',
      deviceId: 'device-1',
      userId: 'user-1',
    );

    expect(note, 'lokale notiz');
  });

  test('uses remote note and updates local cache on success', () async {
    await cacheStore.writeUserNote(
      gymId: 'gym-1',
      deviceId: 'device-1',
      userId: 'user-1',
      note: 'alt',
    );
    remoteSource.nextNote = 'neu';

    final note = await repository.getUserNote(
      gymId: 'gym-1',
      deviceId: 'device-1',
      userId: 'user-1',
    );

    expect(note, 'neu');
    final cached = await cacheStore.readUserNote(
      gymId: 'gym-1',
      deviceId: 'device-1',
      userId: 'user-1',
    );
    expect(cached, 'neu');
  });

  test('returns cached xp stats when remote read fails', () async {
    await cacheStore.writeUserDeviceXp(
      gymId: 'gym-1',
      deviceId: 'device-1',
      userId: 'user-1',
      stats: const WorkoutDeviceXpState(xp: 230, level: 5),
    );
    remoteSource.xpError = Exception('timeout');

    final stats = await repository.getUserDeviceXp(
      gymId: 'gym-1',
      deviceId: 'device-1',
      userId: 'user-1',
    );

    expect(stats.xp, 230);
    expect(stats.level, 5);
  });

  test('delegates last session lookup to session repository', () async {
    final expected = Session(
      sessionId: 'session-1',
      gymId: 'gym-1',
      userId: 'user-1',
      deviceId: 'device-1',
      deviceName: 'Leg Press',
      timestamp: DateTime(2026, 2, 15, 10, 0),
      note: 'top set',
      sets: <SessionSet>[],
    );
    when(
      () => sessionRepository.getLastSession(
        gymId: any(named: 'gymId'),
        userId: any(named: 'userId'),
        deviceId: any(named: 'deviceId'),
        exerciseId: any(named: 'exerciseId'),
      ),
    ).thenAnswer((_) async => expected);

    final actual = await repository.getLastSession(
      gymId: 'gym-1',
      userId: 'user-1',
      deviceId: 'device-1',
      exerciseId: 'exercise-1',
    );

    expect(actual, same(expected));
  });
}
