import 'package:tapem/domain/models/report_entry.dart';

/// States für den ReportBloc.
abstract class ReportState {}

/// Initialzustand.
class ReportInitial extends ReportState {}

/// Ladezustand.
class ReportLoading extends ReportState {}

/// State, wenn Report-Daten erfolgreich geladen wurden.
class ReportLoadSuccess extends ReportState {
  final List<ReportEntry> entries;
  ReportLoadSuccess(this.entries);
}

/// Fehlerzustand.
class ReportFailure extends ReportState {
  final String message;
  ReportFailure(this.message);
}
