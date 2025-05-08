// lib/core/tenant/tenant_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/domain/gym_config.dart';
import '../models/domain/device.dart';
import '../models/domain/mappers.dart';
import '../models/dto/device_dto.dart';
import 'interfaces/tenant_repository.dart';
import 'services/firestore_tenant_repository.dart';

/// Verwaltet den aktuellen Gym-Kontext (Tenant).
class TenantService {
  // Singleton-Instanz
  static final TenantService _instance = TenantService._internal();
  factory TenantService() => _instance;
  TenantService._internal();

  static const _gymIdKey = 'currentGymId';
  String? _gymId;
  GymConfig? _config;
  final TenantRepository _repo = FirestoreTenantRepository();

  /// Initialisiert den Tenant mit der angegebenen gymId und lädt die Konfiguration.
  Future<void> init(String gymId) async {
    _gymId = gymId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gymIdKey, gymId);

    // Konfiguration aus Firestore holen und in Domain-Model mappen
    final dto = await _repo.fetchConfig(gymId);
    _config = toDomain(dto);
  }

  /// Aktuell gesetzte Gym-ID
  String? get gymId => _gymId;

  /// Gym-spezifische Konfiguration
  GymConfig? get config => _config;

  /// Gym wechseln und neue Konfiguration laden
  Future<void> switchGym(String newGymId) async {
    await init(newGymId);
  }

  /// Gibt alle Geräte des aktuellen Gyms als Domain-Modelle per Stream zurück.
  Stream<List<Device>> getDeviceStream() {
    if (_gymId == null) {
      throw Exception('GymId ist nicht initialisiert');
    }
    return FirebaseFirestore.instance
        .collection('gyms')
        .doc(_gymId)
        .collection('devices')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => toDomainDevice(DeviceDto.fromJson(d.data())))
            .toList());
  }
}
