/// Events für den HistoryBloc.
abstract class HistoryEvent {}

/// Lädt die Historie für ein Gerät, optional mit Übungsfilter.
class HistoryLoad extends HistoryEvent {
  final String deviceId;
  final String? exerciseFilter;

  HistoryLoad({
    required this.deviceId,
    this.exerciseFilter,
  });
}
