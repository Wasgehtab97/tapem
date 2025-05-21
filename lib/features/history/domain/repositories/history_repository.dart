// lib/features/history/domain/repositories/history_repository.dart
import '../models/workout_log.dart';

/// Interface für den Zugriff auf Workout-Logs eines Geräts.
abstract class HistoryRepository {
  /// Holt alle Logs für [gymId], [deviceId] und [userId].
  Future<List<WorkoutLog>> getHistory(
      String gymId, String deviceId, String userId);
}
