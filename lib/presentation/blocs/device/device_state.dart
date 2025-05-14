part of 'device_bloc.dart';

/// Basis-State für Device-BLoC.
abstract class DeviceState {}

/// Initialer Zustand – noch nichts passiert.
class DeviceInitial extends DeviceState {}

/// Ladezustand bei allen Aktionen.
class DeviceLoading extends DeviceState {}

/// State nach erfolgreichem Laden aller Geräte.
class DeviceLoaded extends DeviceState {
  final List<DeviceModel> devices;
  DeviceLoaded(this.devices);
}

/// State nach erfolgreicher Registrierung: enthält neue Document-ID.
class DeviceRegisterSuccess extends DeviceState {
  final String documentId;
  DeviceRegisterSuccess(this.documentId);
}

/// State nach erfolgreichem Update.
class DeviceUpdateSuccess extends DeviceState {}

/// Fehlerzustand mit Meldung.
class DeviceFailure extends DeviceState {
  final String message;
  DeviceFailure(this.message);
}
