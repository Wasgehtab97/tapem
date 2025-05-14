// lib/domain/repositories/history_repository.dart

import '../models/exercise_entry.dart';

/// Schnittstelle für Trainingshistorie.
abstract class HistoryRepository {
  /// Aktuelle Nutzer-ID oder null.
  Future<String?> getCurrentUserId();

  /// Holt alle Sessions für [userId] und [deviceId], optional gefiltert nach [exercise].
  Future<List<ExerciseEntry>> fetchHistory({
    required String userId,
    required String deviceId,
    String? exercise,
  });
}
