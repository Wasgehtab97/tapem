import '../models/device_model.dart';

/// Schnittstelle für Gerätemanagement (User-Seite).
abstract class DeviceRepository {
  /// Registriert ein neues Gerät.
  Future<String> registerDevice({
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

  /// Lädt alle Geräte.
  Future<List<DeviceModel>> loadAllDevices();
}
