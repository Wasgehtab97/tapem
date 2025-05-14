import 'package:tapem/domain/models/device_model.dart';

abstract class GymState {}

/// Initialzustand – noch nichts geladen.
class GymInitial extends GymState {}

/// Ladezustand während des Abrufs.
class GymLoading extends GymState {}

/// Zustand nach erfolgreichem Laden: Liste der Geräte.
class GymLoadSuccess extends GymState {
  final List<DeviceModel> devices;
  GymLoadSuccess(this.devices);
}

/// Fehlerzustand mit Fehlermeldung.
class GymFailure extends GymState {
  final String message;
  GymFailure(this.message);
}
