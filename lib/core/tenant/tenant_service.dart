// lib/core/tenant/tenant_service.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dto/gym_config_dto.dart';
import '../models/dto/device_dto.dart';
import '../models/domain/gym_config.dart';
import '../models/domain/device.dart';
import '../models/domain/mappers.dart';
import 'interfaces/tenant_repository.dart';
import 'services/firestore_tenant_repository.dart';

/// Verwaltet den aktuellen Gym-Kontext (Tenant) inkl. Offline-Caching.
class TenantService {
  // --- Singleton ---
  static final TenantService _instance = TenantService._internal();
  factory TenantService() => _instance;
  TenantService._internal();

  // --- Keys für SharedPreferences ---
  static const String gymIdKey = 'currentGymId';
  static const String configKeyPrefix = 'gymConfig_';

  String?    _gymId;
  GymConfig? _config;
  final TenantRepository _repo = FirestoreTenantRepository();

  /// Lädt und cached die GymConfig für [gymId].
  Future<void> init(String gymId) async {
    _gymId = gymId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(gymIdKey, gymId);

    GymConfigDto dto;
    try {
      // 1) Konfiguration aus Firestore holen
      dto = await _repo.fetchConfig(gymId);
      // 2) DTO als JSON cachen
      final rawJson = jsonEncode(dto.toJson());
      await prefs.setString('$configKeyPrefix$gymId', rawJson);
    } catch (e) {
      // 3) Fallback: aus lokalem Cache laden
      final cached = prefs.getString('$configKeyPrefix$gymId');
      if (cached == null) {
        rethrow; // kein Cache → tatsächlicher Fehler
      }
      final map = jsonDecode(cached) as Map<String, dynamic>;
      dto = GymConfigDto.fromJson(map);
    }

    // 4) Mapping ins Domain-Model
    _config = toDomain(dto);
  }

  /// Aktuell gesetzte Gym-ID
  String? get gymId => _gymId;

  /// Aktuell geladene Gym-Konfiguration
  GymConfig? get config => _config;

  /// Wechsel zu einem anderen Gym (erneutes Laden)
  Future<void> switchGym(String newGymId) => init(newGymId);

  /// Stream aller Geräte des aktuellen Gyms als Domain-Modelle
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
