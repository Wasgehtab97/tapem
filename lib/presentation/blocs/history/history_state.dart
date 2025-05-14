import 'package:tapem/domain/models/exercise_entry.dart';

/// States für den HistoryBloc.
abstract class HistoryState {}

/// Initialzustand.
class HistoryInitial extends HistoryState {}

/// Ladezustand während des Abrufs.
class HistoryLoading extends HistoryState {}

/// State, wenn die Historie erfolgreich geladen wurde.
class HistoryLoadSuccess extends HistoryState {
  final List<ExerciseEntry> entries;
  HistoryLoadSuccess(this.entries);
}

/// Fehlerzustand mit Nachricht.
class HistoryFailure extends HistoryState {
  final String message;
  HistoryFailure(this.message);
}
