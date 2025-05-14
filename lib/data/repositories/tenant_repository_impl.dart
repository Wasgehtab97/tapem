// lib/data/repositories/tenant_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tapem/domain/models/gym_config.dart';
import 'package:tapem/domain/models/tenant.dart';
import 'package:tapem/domain/repositories/tenant_repository.dart';

class TenantRepositoryImpl implements TenantRepository {
  final FirebaseFirestore _fs;
  final SharedPreferences _prefs;

  static const _key = 'selected_gym';

  String? _gymId;
  GymConfig? _config;

  TenantRepositoryImpl(this._fs, this._prefs);

  @override
  Future<List<Tenant>> fetchAllTenants() async {
    final snap = await _fs.collection('gyms').get();
    return snap.docs.map((d) {
      final raw = d.data()['config'] as Map<String, dynamic>;
      return Tenant(gymId: d.id, config: GymConfig.fromMap(raw));
    }).toList();
  }

  @override
  Future<String?> getSavedGymId() async {
    return _prefs.getString(_key);
  }

  @override
  Future<void> switchTenant(String gymId) async {
    // 1) local persist
    await _prefs.setString(_key, gymId);
    // 2) load config from Firestore
    final doc = await _fs.collection('gyms').doc(gymId).get();
    if (doc.exists && doc.data()?['config'] is Map<String, dynamic>) {
      _config = GymConfig.fromMap(doc.data()!['config'] as Map<String, dynamic>);
    } else {
      _config = null;
    }
    _gymId = gymId;
  }

  @override
  GymConfig? get config => _config;

  @override
  String? get gymId => _gymId;
}
