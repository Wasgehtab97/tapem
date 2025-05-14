// lib/presentation/blocs/training_details/training_details_event.dart

abstract class TrainingDetailsEvent {}

/// Event zum Laden der Details für ein konkretes Datum.
class TrainingDetailsLoad extends TrainingDetailsEvent {
  final String dateKey;
  TrainingDetailsLoad(this.dateKey);
}
