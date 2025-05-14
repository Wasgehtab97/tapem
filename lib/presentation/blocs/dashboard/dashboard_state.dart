part of 'dashboard_bloc.dart';

abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoadSuccess extends DashboardState {
  final DashboardData data;
  final String? secretCode;

  DashboardLoadSuccess(this.data, this.secretCode);
}

class DashboardFailure extends DashboardState {
  final String message;
  DashboardFailure(this.message);
}
