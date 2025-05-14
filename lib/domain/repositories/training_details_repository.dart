// lib/domain/repositories/training_details_repository.dart

/// Schnittstelle für Detail-Feature (Training nach Datum).
abstract class TrainingDetailsRepository {
  /// Aktuelle Nutzer-ID oder null.
  Future<String?> getCurrentUserId();

  /// Holt alle Details für [userId] und [dateKey].
  Future<List<Map<String, dynamic>>> fetchDetailsForDate({
    required String userId,
    required String dateKey,
  });
}
