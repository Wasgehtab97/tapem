import 'package:equatable/equatable.dart';

/// Events für den ProfileBloc.
abstract class ProfileEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Lädt alle Profildaten (UserData, Termine, offene Anfrage).
class ProfileLoadAll extends ProfileEvent {}

/// Antwortet auf eine Coaching-Anfrage.
class ProfileRespondRequest extends ProfileEvent {
  final String requestId;
  final bool accept;

  ProfileRespondRequest(this.requestId, this.accept);

  @override
  List<Object?> get props => [requestId, accept];
}

/// Meldet den Nutzer ab.
class ProfileSignOut extends ProfileEvent {}
