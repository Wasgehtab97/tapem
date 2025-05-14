// lib/domain/repositories/admin_repository.dart

import '../models/device_model.dart';

/// Schnittstelle für Admin-Operationen (Geräte-Verwaltung).
abstract class AdminRepository {
  /// Liefert alle Geräte.
  Future<List<DeviceModel>> fetchDevices();

  /// Erstellt ein neues Gerät und gibt dessen Dokument-ID zurück.
  Future<String> createDevice({
    required String name,
    required String exerciseMode,
  });

  /// Aktualisiert ein bestehendes Gerät.
  Future<void> updateDevice({
    required String documentId,
    required String name,
    required String exerciseMode,
    required String secretCode,
  });
}
