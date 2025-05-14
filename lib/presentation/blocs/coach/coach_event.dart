// lib/presentation/blocs/coach/coach_event.dart

/// Events für den CoachBloc.
abstract class CoachEvent {}

/// Lädt alle Klienten für einen Coach.
class CoachLoadClients extends CoachEvent {
  final String coachId;
  CoachLoadClients(this.coachId);
}

/// Holt alle Trainingstermine für einen Klienten.
class CoachFetchTrainingDates extends CoachEvent {
  final String clientId;
  CoachFetchTrainingDates(this.clientId);
}

/// Sendet eine Coaching-Anfrage an ein Mitglied.
class CoachSendRequest extends CoachEvent {
  final String coachId;
  final String membershipNumber;
  CoachSendRequest({required this.coachId, required this.membershipNumber});
}
