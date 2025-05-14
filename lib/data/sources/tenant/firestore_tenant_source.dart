import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/domain/models/tenant.dart';
import 'package:tapem/domain/models/gym_config.dart';

/// Firestore-Source für Tenants.
class FirestoreTenantSource {
  final FirebaseFirestore _fs;
  FirestoreTenantSource([FirebaseFirestore? firestore])
      : _fs = firestore ?? FirebaseFirestore.instance;

  /// Holt alle Dokumente aus `gyms` und baut Tenant-Objekte.
  Future<List<Tenant>> fetchAll() async {
    final snap = await _fs.collection('gyms').get();
    return snap.docs.map((d) {
      final cfgMap = d.data()['config'] as Map<String, dynamic>;
      return Tenant.fromMap({'config': cfgMap}, id: d.id);
    }).toList();
  }

  /// Holt die Config für ein bestimmtes Gym und gibt sie zurück.
  Future<GymConfig?> loadConfig(String gymId) async {
    final doc = await _fs.collection('gyms').doc(gymId).get();
    if (!doc.exists || doc.data()==null) return null;
    return GymConfig.fromMap(doc.data()!['config'] as Map<String, dynamic>);
  }
}
