part of 'dashboard_bloc.dart';

abstract class DashboardEvent {}

class DashboardLoad extends DashboardEvent {
  final String deviceId;
  final String? secretCode;
  DashboardLoad({required this.deviceId, this.secretCode});
}

class DashboardAddSet extends DashboardEvent {
  final String deviceId;
  final String? secretCode;
  final String exercise;
  final int sets;
  final double weight;
  final int reps;

  DashboardAddSet({
    required this.deviceId,
    this.secretCode,
    required this.exercise,
    required this.sets,
    required this.weight,
    required this.reps,
  });
}

class DashboardFinish extends DashboardEvent {
  final String deviceId;
  final String? secretCode;
  final String exercise;

  DashboardFinish({
    required this.deviceId,
    this.secretCode,
    required this.exercise,
  });
}
