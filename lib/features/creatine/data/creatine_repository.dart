import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CreatineRepository {
  final FirebaseFirestore _firestore;
  CreatineRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) {
    final u = uid.trim();
    if (u.isEmpty) {
      throw StateError('Anmeldung erforderlich');
    }
    return _firestore.collection('users').doc(u).collection('creatine_intakes');
  }

  Future<Set<String>> fetchDatesForYear(String uid, int year) async {
    final start = '$year-01-01';
    final end = '$year-12-31';
    final col = _col(uid);
    final snap = await col
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: start)
        .where(FieldPath.documentId, isLessThanOrEqualTo: end)
        .get();
    return snap.docs.map((d) => d.id).toSet();
  }

  Future<void> setIntake(String uid, String dateKey) async {
    final key = _requireDateKey(dateKey);
    await _col(uid).doc(key).set({
      'uid': uid,
      'dateKey': key,
      'ts': FieldValue.serverTimestamp(),
      'source': 'manual',
    });
  }

  Future<void> deleteIntake(String uid, String dateKey) async {
    final key = _requireDateKey(dateKey);
    await _col(uid).doc(key).delete();
  }

  String _requireDateKey(String dateKey) {
    final key = dateKey.trim();
    final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!regex.hasMatch(key)) {
      throw StateError('Ungültiges Datum');
    }
    return key;
  }
}

String currentUidOrFail() {
  final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
  if (uid.isEmpty) {
    throw StateError('Anmeldung erforderlich');
  }
  return uid;
}

String toDateKeyLocal(DateTime d) {
  final local = d.toLocal();
  final normalized = DateTime(local.year, local.month, local.day);
  return DateFormat('yyyy-MM-dd').format(normalized);
}
