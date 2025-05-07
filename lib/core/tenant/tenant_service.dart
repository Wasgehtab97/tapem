// lib/core/tenant/tenant_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'models/gym_config.dart';

/// Verwaltet den aktuellen Gym-Kontext (Tenant).
class TenantService {
  static final TenantService _instance = TenantService._internal();
  factory TenantService() => _instance;
  TenantService._internal();

  static const _gymIdKey = 'currentGymId';
  String? _gymId;
  GymConfig? _config;

  /// Initialisiert den Tenant mit der angegebenen gymId.
  Future<void> init(String gymId) async {
    _gymId = gymId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gymIdKey, gymId);
    // Hier ggf. Config aus Firestore laden:
    //_config = await fetchConfigFromFirestore(gymId);
  }

  /// Aktuell gesetzte Gym-ID
  String? get gymId => _gymId;

  /// Gym-spezifische Konfiguration
  GymConfig? get config => _config;

  /// Gym wechseln
  Future<void> switchGym(String newGymId) async {
    await init(newGymId);
  }

  // Beispiel-Methode, um Config aus Firestore zu holen
  // Future<GymConfig> fetchConfigFromFirestore(String gymId) async { … }
}
