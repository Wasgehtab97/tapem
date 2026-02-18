import 'package:tapem/features/device/domain/models/workout_device_xp_state.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';

abstract class WorkoutDataRepository {
  Future<Session?> getLastSession({
    required String gymId,
    required String userId,
    required String deviceId,
    required String exerciseId,
  });

  Future<String> getUserNote({
    required String gymId,
    required String deviceId,
    required String userId,
  });

  Future<WorkoutDeviceXpState> getUserDeviceXp({
    required String gymId,
    required String deviceId,
    required String userId,
  });

  Future<void> cacheUserNote({
    required String gymId,
    required String deviceId,
    required String userId,
    required String note,
  });

  Future<void> cacheUserDeviceXp({
    required String gymId,
    required String deviceId,
    required String userId,
    required WorkoutDeviceXpState stats,
  });
}
