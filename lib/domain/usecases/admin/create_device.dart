// lib/domain/usecases/admin/create_device.dart

import 'package:tapem/domain/repositories/admin_repository.dart';

/// UseCase zum Anlegen eines neuen Geräts.
/// 
/// Gibt die erzeugte Dokument-ID zurück.
class CreateDeviceUseCase {
  final AdminRepository _repository;

  CreateDeviceUseCase(this._repository);

  /// Legt ein neues Gerät mit [name] und [exerciseMode] an.
  Future<String> call({
    required String name,
    required String exerciseMode,
  }) async {
    return await _repository.createDevice(
      name: name,
      exerciseMode: exerciseMode,
    );
  }
}
