import 'package:equatable/equatable.dart';
import 'package:tapem/domain/models/device_model.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

/// Noch keine Aktion ausgeführt
class AdminInitial extends AdminState {}

/// Lädt gerade (Load, Create oder Update)
class AdminLoading extends AdminState {}

/// Geräteliste erfolgreich geladen
class AdminLoadSuccess extends AdminState {
  final List<DeviceModel> devices;

  const AdminLoadSuccess(this.devices);

  @override
  List<Object?> get props => [devices];
}

/// Neues Gerät erfolgreich angelegt (liefert die neue Doc-ID)
class AdminCreateSuccess extends AdminState {
  final String newDocumentId;

  const AdminCreateSuccess(this.newDocumentId);

  @override
  List<Object?> get props => [newDocumentId];
}

/// Gerät erfolgreich upgedated
class AdminUpdateSuccess extends AdminState {}

/// Irgendwo ist ein Fehler passiert
class AdminFailure extends AdminState {
  final String error;

  const AdminFailure(this.error);

  @override
  List<Object?> get props => [error];
}
