import 'package:equatable/equatable.dart';

/// Events für den ReportBloc.
abstract class ReportEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Lädt alle Report-Daten für [gymId] mit optionalem Filter.
class ReportLoadAll extends ReportEvent {
  final String gymId;
  final String? deviceId;
  final DateTime? start;
  final DateTime? end;

  ReportLoadAll({
    required this.gymId,
    this.deviceId,
    this.start,
    this.end,
  });

  @override
  List<Object?> get props => [gymId, deviceId, start, end];
}
