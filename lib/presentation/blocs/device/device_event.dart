part of 'device_bloc.dart';

/// Basis-Event für Device-BLoC.
abstract class DeviceEvent {}

/// Liste aller Geräte laden.
class DeviceLoadAll extends DeviceEvent {}

/// Registrierung eines neuen Geräts.
class DeviceRegisterRequested extends DeviceEvent {
  final String name;
  final String exerciseMode;

  DeviceRegisterRequested({
    required this.name,
    required this.exerciseMode,
  });
}

/// Update eines bestehenden Geräts.
class DeviceUpdateRequested extends DeviceEvent {
  final String documentId;
  final String name;
  final String exerciseMode;
  final String secretCode;

  DeviceUpdateRequested({
    required this.documentId,
    required this.name,
    required this.exerciseMode,
    required this.secretCode,
  });
}
