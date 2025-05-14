import 'package:equatable/equatable.dart';
import 'package:tapem/domain/models/device_model.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

/// Alle Geräte laden
class AdminFetchDevices extends AdminEvent {}

/// Neues Gerät anlegen
class AdminCreateDevice extends AdminEvent {
  final String name;
  final String exerciseMode;

  const AdminCreateDevice({
    required this.name,
    required this.exerciseMode,
  });

  @override
  List<Object?> get props => [name, exerciseMode];
}

/// Bestehendes Gerät updaten
class AdminUpdateDevice extends AdminEvent {
  final String documentId;
  final String name;
  final String exerciseMode;
  final String secretCode;

  const AdminUpdateDevice({
    required this.documentId,
    required this.name,
    required this.exerciseMode,
    required this.secretCode,
  });

  @override
  List<Object?> get props => [documentId, name, exerciseMode, secretCode];
}
