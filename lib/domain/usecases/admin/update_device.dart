// lib/domain/usecases/admin/update_device.dart

import 'package:tapem/domain/repositories/admin_repository.dart';

/// UseCase zum Aktualisieren eines bestehenden Geräts.
/// 
/// [documentId] ist die Firestore-ID, [secretCode] das Admin-Passwort.
class UpdateDeviceUseCase {
  final AdminRepository _repository;

  UpdateDeviceUseCase(this._repository);

  /// Aktualisiert das Gerät mit den angegebenen Eigenschaften.
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
