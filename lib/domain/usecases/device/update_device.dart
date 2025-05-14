// lib/domain/usecases/device/update_device.dart

import 'package:tapem/domain/repositories/device_repository.dart';

/// Aktualisiert ein bestehendes Gerät.
/// 
/// [documentId]   – Firestore-Dokument-ID des Geräts  
/// [name]         – Neuer Anzeigename  
/// [exerciseMode] – Neuer Übungsmodus  
/// [secretCode]   – Aktueller Geheimcode zur Authorisierung
class UpdateDeviceUseCase {
  final DeviceRepository _repository;

  UpdateDeviceUseCase(this._repository);

  Future<void> call({
    required String documentId,
    required String name,
    required String exerciseMode,
    required String secretCode,
  }) async {
    await _repository.updateDevice(
      documentId: documentId,
      name: name,
      exerciseMode: exerciseMode,
      secretCode: secretCode,
    );
  }
}
