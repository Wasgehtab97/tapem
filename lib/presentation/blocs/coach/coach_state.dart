// lib/presentation/blocs/coach/coach_state.dart

import 'package:tapem/domain/models/client_info.dart';

/// States für den CoachBloc.
abstract class CoachState {}

/// Initialzustand.
class CoachInitial extends CoachState {}

/// Ladezustand während aller Operationen.
class CoachLoading extends CoachState {}

/// State, wenn Klienten erfolgreich geladen wurden.
class CoachClientsLoadSuccess extends CoachState {
  final List<ClientInfo> clients;
  CoachClientsLoadSuccess(this.clients);
}

/// State, wenn Trainingstermine erfolgreich geladen wurden.
class CoachDatesLoadSuccess extends CoachState {
  final List<String> dates;
  CoachDatesLoadSuccess(this.dates);
}

/// State, wenn Coaching-Anfrage erfolgreich gesendet wurde.
class CoachRequestSuccess extends CoachState {}

/// Fehlerzustand mit Nachricht.
class CoachFailure extends CoachState {
  final String message;
  CoachFailure(this.message);
}
