// lib/features/history/domain/usecases/get_history_for_device.dart
import '../models/workout_log.dart';
import '../repositories/history_repository.dart';

/// Use Case: Holt die Workout-Historie für ein Gerät für den aktuellen User.
class GetHistoryForDevice {
  final HistoryRepository _repository;
  GetHistoryForDevice(this._repository);

  Future<List<WorkoutLog>> execute(
      String gymId, String deviceId, String userId) {
    return _repository.getHistory(gymId, deviceId, userId);
  }
}
