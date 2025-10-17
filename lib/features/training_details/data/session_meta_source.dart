import 'package:cloud_firestore/cloud_firestore.dart';

class DayMetaSnapshot {
  DayMetaSnapshot({required this.data, required this.isFromCache});

  final Map<String, dynamic>? data;
  final bool isFromCache;
}

class SessionMetaSource {
  final FirebaseFirestore _firestore;
  SessionMetaSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> upsertMeta({
    required String gymId,
    required String uid,
    required String sessionId,
    required Map<String, dynamic> meta,
  }) async {
    await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(uid)
        .collection('session_meta')
        .doc(sessionId)
        .set(meta, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getMetaBySessionId({
    required String gymId,
    required String uid,
    required String sessionId,
    bool fromCacheOnly = false,
  }) async {
    final options = fromCacheOnly
        ? const GetOptions(source: Source.cache)
        : const GetOptions(source: Source.serverAndCache);

    final doc = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(uid)
        .collection('session_meta')
        .doc(sessionId)
        .get(options);
    return doc.data();
  }

  Future<void> deleteMeta({
    required String gymId,
    required String uid,
    required String sessionId,
  }) async {
    await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(uid)
        .collection('session_meta')
        .doc(sessionId)
        .delete();
  }

  Future<Map<String, dynamic>?> getMetaByDayKey({
    required String gymId,
    required String uid,
    required String dayKey,
    bool fromCacheOnly = false,
  }) async {
    final options = fromCacheOnly
        ? const GetOptions(source: Source.cache)
        : const GetOptions(source: Source.serverAndCache);

    final snap = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(uid)
        .collection('session_meta')
        .where('dayKey', isEqualTo: dayKey)
        .limit(1)
        .get(options);
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data();
  }

  Stream<DayMetaSnapshot> watchMetaByDayKey({
    required String gymId,
    required String uid,
    required String dayKey,
  }) {
    final query = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(uid)
        .collection('session_meta')
        .where('dayKey', isEqualTo: dayKey)
        .limit(1);

    return query
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => DayMetaSnapshot(
              data: snapshot.docs.isEmpty ? null : snapshot.docs.first.data(),
              isFromCache: snapshot.metadata.isFromCache,
            ));
  }
}
