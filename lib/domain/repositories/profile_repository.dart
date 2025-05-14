// lib/domain/repositories/profile_repository.dart

/// Schnittstelle für Profil- und Coaching-Feature.
abstract class ProfileRepository {
  /// Aktuelle Nutzer-ID oder null.
  Future<String?> getCurrentUserId();

  /// Holt das Nutzerprofil als Map.
  Future<Map<String, dynamic>> fetchUserProfile(String userId);

  /// Holt alle Trainingstermine für [userId].
  Future<List<String>> fetchTrainingDates(String userId);

  /// Holt eine offene Coaching-Anfrage oder null.
  Future<Map<String, dynamic>?> fetchPendingCoachingRequest(String userId);

  /// Antwortet auf eine Anfrage [requestId].
  Future<void> respondToCoachingRequest(String requestId, bool accept);

  /// Meldet den Nutzer ab.
  Future<void> signOut();
}
