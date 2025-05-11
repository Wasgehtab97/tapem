import 'package:shared_preferences/shared_preferences.dart';
import '../interfaces/tenant_repository.dart';
import 'firestore_tenant_repository.dart';
import '../../models/dto/gym_config_dto.dart';
import '../../models/domain/gym_config.dart';
import '../../models/domain/mappers.dart';

/// Service zum Laden und Cachen der Gym-Konfiguration.
/// 
/// - Lädt aktuell gültige GymConfig aus Firestore über [TenantRepository].
/// - Speichert die Roh-Daten in SharedPreferences (Cache).
/// - Bietet bei Netzwerk-Fehlern einen Fallback auf den zuletzt gecachten Wert.
class GymConfigService {
  final TenantRepository _repo;

  /// Konstruktor erlaubt Injektion eines anderen Repositories (z.B. für Tests).
  GymConfigService({TenantRepository? repository})
      : _repo = repository ?? FirestoreTenantRepository();

  // Keys für SharedPreferences
  static const _keyGymId         = 'gymConfig_gymId';
  static const _keyName          = 'gymConfig_name';
  static const _keyPrimaryHex    = 'gymConfig_primaryColorHex';
  static const _keyAccentHex     = 'gymConfig_accentColorHex';
  static const _keyLogoUrl       = 'gymConfig_logoUrl';

  /// Lädt die Konfiguration für [gymId] aus Firestore,
  /// cacht sie und gibt sie als Domain-Objekt zurück.
  /// Bei Fehlern wird versucht, den Cache zu nutzen.
  Future<GymConfig> loadConfig(String gymId) async {
    try {
      final dto = await _repo.fetchConfig(gymId);
      final config = toDomain(dto);
      await _saveToCache(dto);
      return config;
    } catch (e) {
      // Fallback auf Cache
      final cached = await _loadFromCache();
      if (cached != null) return cached;
      // Wenn kein Cache vorhanden ist, Fehler weiterreichen
      rethrow;
    }
  }

  /// Speichert die GymConfig-Daten aus [dto] in SharedPreferences.
  Future<void> _saveToCache(GymConfigDto dto) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGymId, dto.gymId);
    await prefs.setString(_keyName, dto.name);
    await prefs.setString(_keyPrimaryHex, dto.primaryColorHex);
    await prefs.setString(_keyAccentHex, dto.accentColorHex);
    await prefs.setString(_keyLogoUrl, dto.logoUrl);
  }

  /// Lädt die zuletzt gecachte GymConfig (oder null, falls nicht vorhanden).
  Future<GymConfig?> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final gymId      = prefs.getString(_keyGymId);
    final name       = prefs.getString(_keyName);
    final primaryHex = prefs.getString(_keyPrimaryHex);
    final accentHex  = prefs.getString(_keyAccentHex);
    final logoUrl    = prefs.getString(_keyLogoUrl);

    if ([gymId, name, primaryHex, accentHex, logoUrl].contains(null)) {
      return null;
    }

    // DTO aus Cache-Daten rekonstruieren
    final dto = GymConfigDto(
      gymId: gymId!,
      name: name!,
      primaryColorHex: primaryHex!,
      accentColorHex: accentHex!,
      logoUrl: logoUrl!,
    );

    return toDomain(dto);
  }

  /// Gibt die im Cache gespeicherte GymConfig zurück (ohne Firestore-Aufruf).
  Future<GymConfig?> getCachedConfig() => _loadFromCache();
}
