import 'package:equatable/equatable.dart';

abstract class TenantEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class TenantLoad extends TenantEvent {}

class TenantInit extends TenantEvent {
  final String gymId;
  TenantInit(this.gymId);
  @override
  List<Object?> get props => [gymId];
}
