// lib/features/gym/data/sources/firestore_gym_source.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/gym_config.dart';
import '../../domain/models/branding.dart';

class FirestoreGymSource {
  final FirebaseFirestore _firestore;

  FirestoreGymSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Sucht in 'gyms' nach dem Dokument mit Feld 'code' == [code].
  Future<GymConfig?> getGymByCode(String code) async {
    final query =
        await _firestore
            .collection('gyms')
            .where('code', isEqualTo: code)
            .limit(1)
            .get();

    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return GymConfig.fromMap(doc.id, doc.data());
  }

  /// Liefert das Gym-Dokument mit der angegebenen [id].
  Future<GymConfig?> getGymById(String id) async {
    final doc = await _firestore.collection('gyms').doc(id).get();
    if (!doc.exists) return null;
    return GymConfig.fromMap(doc.id, doc.data()!);
  }

  /// Listet alle Gyms für die öffentliche Auswahl.
  Future<List<GymConfig>> listGyms() async {
    QuerySnapshot<Map<String, dynamic>> query;
    try {
      query = await _firestore.collection('gyms').orderBy('name').get();
    } catch (_) {
      query = await _firestore
          .collection('gyms')
          .orderBy('name')
          .get(const GetOptions(source: Source.cache));
    }
    return query.docs
        .map((doc) => GymConfig.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Gibt die Branding-Konfiguration des Gyms zurück.
  Future<Branding?> getBranding(String gymId) async {
    final doc =
        await _firestore
            .collection('gyms')
            .doc(gymId)
            .collection('config')
            .doc('branding')
            .get();
    if (!doc.exists) return null;
    return Branding.fromMap(doc.data()!);
  }
}
