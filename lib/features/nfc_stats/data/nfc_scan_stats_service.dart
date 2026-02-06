import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/features/nfc_stats/domain/models/nfc_scan_stats.dart';

class NfcScanStatsService {
  NfcScanStatsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('nfc_scan_stats')
        .doc('summary');
  }

  Future<NfcScanStats> fetchStats({required String userId}) async {
    final snap = await _doc(userId).get();
    if (!snap.exists) {
      return NfcScanStats.empty();
    }
    return NfcScanStats.fromFirestore(snap);
  }

  Future<void> recordScan({
    required String userId,
    String? gymId,
    String? deviceId,
    String? exerciseId,
  }) async {
    final payload = <String, dynamic>{
      'totalScans': FieldValue.increment(1),
      'lastScanAt': FieldValue.serverTimestamp(),
      if (gymId != null) 'lastGymId': gymId,
      if (deviceId != null) 'lastDeviceId': deviceId,
      if (exerciseId != null) 'lastExerciseId': exerciseId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _doc(userId).set(payload, SetOptions(merge: true));
  }
}
