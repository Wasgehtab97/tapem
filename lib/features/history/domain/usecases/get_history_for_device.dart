// lib/features/history/domain/usecases/get_history_for_device.dart

import '../models/workout_log.dart';

/// Repository-Interface ohne exerciseId
abstract class GetHistoryForDeviceRepository {
  Future<List<WorkoutLog>> getHistory({
    required String gymId,
    required String deviceId,
    required String userId,
  });
}

/// Use-Case ohne exerciseId
class GetHistoryForDevice {
  final GetHistoryForDeviceRepository _repo;
  GetHistoryForDevice(this._repo);

  Future<List<WorkoutLog>> execute({
    required String gymId,
    required String deviceId,
    required String userId,
  }) {
    return _repo.getHistory(
      gymId: gymId,
      deviceId: deviceId,
      userId: userId,
    );
  }
}
