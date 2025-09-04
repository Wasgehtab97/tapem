import 'package:cloud_firestore/cloud_firestore.dart';

class CreatineRepository {
  final FirebaseFirestore _firestore;
  CreatineRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) {
    return _firestore.collection('users').doc(uid).collection('creatine_intakes');
  }

  Future<Set<String>> fetchDatesForYear(String uid, int year) async {
    final start = '$year-01-01';
    final end = '$year-12-31';
    final snap = await _col(uid)
        .where('dateKey', isGreaterThanOrEqualTo: start)
        .where('dateKey', isLessThanOrEqualTo: end)
        .get();
    return snap.docs.map((d) => d.id).toSet();
  }

  Future<void> setIntake(String uid, String dateKey) async {
    await _col(uid).doc(dateKey).set({
      'uid': uid,
      'dateKey': dateKey,
      'ts': FieldValue.serverTimestamp(),
      'source': 'manual',
    });
  }

  Future<void> deleteIntake(String uid, String dateKey) async {
    await _col(uid).doc(dateKey).delete();
  }
}
