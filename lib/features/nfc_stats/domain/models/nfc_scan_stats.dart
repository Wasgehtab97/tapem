import 'package:cloud_firestore/cloud_firestore.dart';

class NfcScanStats {
  const NfcScanStats({
    required this.totalScans,
    this.lastScanAt,
    this.lastGymId,
    this.lastDeviceId,
    this.lastExerciseId,
  });

  final int totalScans;
  final DateTime? lastScanAt;
  final String? lastGymId;
  final String? lastDeviceId;
  final String? lastExerciseId;

  factory NfcScanStats.empty() => const NfcScanStats(totalScans: 0);

  factory NfcScanStats.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return NfcScanStats.empty();
    final ts = data['lastScanAt'];
    return NfcScanStats(
      totalScans: (data['totalScans'] as num?)?.toInt() ?? 0,
      lastScanAt: ts is Timestamp ? ts.toDate() : null,
      lastGymId: data['lastGymId'] as String?,
      lastDeviceId: data['lastDeviceId'] as String?,
      lastExerciseId: data['lastExerciseId'] as String?,
    );
  }
}
