// lib/data/sources/gym/firestore_gym_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreGymSource {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('gyms');

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchDevices({
    String? nameQuery,
  }) {
    Query<Map<String, dynamic>> query = _col;
    if (nameQuery != null && nameQuery.isNotEmpty) {
      query = query.where('name', isGreaterThanOrEqualTo: nameQuery);
    }
    return query.get().then((snap) => snap.docs);
  }
}
