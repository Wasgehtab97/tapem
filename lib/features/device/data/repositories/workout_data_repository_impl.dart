import 'package:tapem/features/device/data/local/workout_context_cache_store.dart';
import 'package:tapem/features/device/data/sources/firestore_workout_context_source.dart';
import 'package:tapem/features/device/domain/models/workout_device_xp_state.dart';
import 'package:tapem/features/device/domain/repositories/workout_data_repository.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';
import 'package:tapem/features/training_details/domain/repositories/session_repository.dart';

class WorkoutDataRepositoryImpl implements WorkoutDataRepository {
  WorkoutDataRepositoryImpl({
    required SessionRepository sessionRepository,
    required WorkoutContextRemoteSource remoteSource,
    WorkoutContextCacheStore? cacheStore,
  }) : _sessionRepository = sessionRepository,
       _remoteSource = remoteSource,
       _cacheStore = cacheStore ?? const WorkoutContextCacheStore();

  final SessionRepository _sessionRepository;
  final WorkoutContextRemoteSource _remoteSource;
  final WorkoutContextCacheStore _cacheStore;

  @override
  Future<Session?> getLastSession({
    required String gymId,
    required String userId,
    required String deviceId,
    required String exerciseId,
  }) {
    return _sessionRepository.getLastSession(
      gymId: gymId,
      userId: userId,
      deviceId: deviceId,
      exerciseId: exerciseId,
    );
  }

  @override
  Future<String> getUserNote({
    required String gymId,
    required String deviceId,
    required String userId,
  }) async {
    final local = await _cacheStore.readUserNote(
      gymId: gymId,
      deviceId: deviceId,
      userId: userId,
    );
    try {
      final remote = await _remoteSource.fetchUserNote(
        gymId: gymId,
        deviceId: deviceId,
        userId: userId,
      );
      if (remote != local) {
        await _cacheStore.writeUserNote(
          gymId: gymId,
          deviceId: deviceId,
          userId: userId,
          note: remote,
        );
      }
      return remote;
    } catch (_) {
      return local;
    }
  }

  @override
  Future<WorkoutDeviceXpState> getUserDeviceXp({
    required String gymId,
    required String deviceId,
    required String userId,
  }) async {
    final local = await _cacheStore.readUserDeviceXp(
      gymId: gymId,
      deviceId: deviceId,
      userId: userId,
    );
    try {
      final remote = await _remoteSource.fetchUserDeviceXp(
        gymId: gymId,
        deviceId: deviceId,
        userId: userId,
      );
      if (remote.xp != local.xp || remote.level != local.level) {
        await _cacheStore.writeUserDeviceXp(
          gymId: gymId,
          deviceId: deviceId,
          userId: userId,
          stats: remote,
        );
      }
      return remote;
    } catch (_) {
      return local;
    }
  }

  @override
  Future<void> cacheUserNote({
    required String gymId,
    required String deviceId,
    required String userId,
    required String note,
  }) {
    return _cacheStore.writeUserNote(
      gymId: gymId,
      deviceId: deviceId,
      userId: userId,
      note: note,
    );
  }

  @override
  Future<void> cacheUserDeviceXp({
    required String gymId,
    required String deviceId,
    required String userId,
    required WorkoutDeviceXpState stats,
  }) {
    return _cacheStore.writeUserDeviceXp(
      gymId: gymId,
      deviceId: deviceId,
      userId: userId,
      stats: stats,
    );
  }
}
