// lib/domain/usecases/device/register_device.dart

import 'package:tapem/domain/repositories/device_repository.dart';

/// Registriert ein neues Gerät.
/// 
/// [name]         – Anzeigename des Geräts  
/// [exerciseMode] – Übungsmodus (z. B. “cardio”, “strength”)  
/// Rückgabe: Dokument-ID des neuen Geräts
class RegisterDeviceUseCase {
  final DeviceRepository _repository;

  RegisterDeviceUseCase(this._repository);

  Future<String> call({
    required String name,
    required String exerciseMode,
  }) async {
    return await _repository.registerDevice(
      name: name,
      exerciseMode: exerciseMode,
    );
  }
}
