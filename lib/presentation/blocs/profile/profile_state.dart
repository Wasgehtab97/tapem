import 'package:tapem/domain/models/client_info.dart';
import 'package:tapem/domain/models/user_data.dart';

/// States für den ProfileBloc.
abstract class ProfileState {}

/// Initialzustand.
class ProfileInitial extends ProfileState {}

/// Ladezustand während aller Operationen.
class ProfileLoading extends ProfileState {}

/// State, wenn das komplette Profil geladen wurde.
class ProfileLoadSuccess extends ProfileState {
  final UserData user;
  final List<String> trainingDates;
  final Map<String, dynamic>? pendingRequest;

  ProfileLoadSuccess({
    required this.user,
    required this.trainingDates,
    required this.pendingRequest,
  });
}

/// State, wenn auf Anfrage geantwortet wurde.
class ProfileRequestResponded extends ProfileState {
  final bool accepted;
  ProfileRequestResponded(this.accepted);
}

/// State, wenn der Nutzer ausgeloggt wurde.
class ProfileSignedOut extends ProfileState {}

/// Fehlerzustand mit Nachricht.
class ProfileFailure extends ProfileState {
  final String message;
  ProfileFailure(this.message);
}
