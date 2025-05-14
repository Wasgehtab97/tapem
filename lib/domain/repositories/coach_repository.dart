// lib/domain/repositories/coach_repository.dart

import '../models/client_info.dart';

/// Schnittstelle für Coach-Feature.
abstract class CoachRepository {
  /// Lädt alle Klienten des Coaches [coachId].
  Future<List<ClientInfo>> loadClients(String coachId);

  /// Holt alle Trainingstermine für Klient [clientId].
  Future<List<String>> fetchTrainingDates(String clientId);

  /// Sendet eine Coaching-Anfrage für [membershipNumber].
  Future<void> sendCoachingRequest(
    String coachId,
    String membershipNumber,
  );
}
