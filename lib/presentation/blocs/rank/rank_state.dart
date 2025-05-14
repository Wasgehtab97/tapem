import 'package:tapem/domain/models/user_data.dart';

/// States für den RankBloc.
abstract class RankState {}

/// Initialzustand.
class RankInitial extends RankState {}

/// Ladezustand.
class RankLoading extends RankState {}

/// State, wenn die Nutzer erfolgreich geladen wurden.
class RankLoadSuccess extends RankState {
  final List<UserData> users;
  RankLoadSuccess(this.users);
}

/// Fehlerzustand.
class RankFailure extends RankState {
  final String message;
  RankFailure(this.message);
}
