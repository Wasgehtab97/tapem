// lib/features/gym/data/sources/firestore_gym_source.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/gym_config.dart';

class FirestoreGymSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sucht in 'gyms' nach dem Dokument mit Feld 'code' == [code].
  Future<GymConfig?> getGymByCode(String code) async {
    final query = await _firestore
        .collection('gyms')
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return GymConfig.fromMap(doc.id, doc.data());
  }
}
