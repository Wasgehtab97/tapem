import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/features/rest_stats/domain/models/rest_stat_summary.dart';

class RestStatsService {
  RestStatsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(
    String gymId,
    String userId,
  ) {
    return _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(userId)
        .collection('rest_stats');
  }

  String _docId(String deviceId, String? exerciseId) {
    if (exerciseId == null || exerciseId.isEmpty) {
      return deviceId;
    }
    return '${deviceId}__$exerciseId';
  }

  Future<void> recordSession({
    required String gymId,
    required String userId,
    required String deviceId,
    required String deviceName,
    String? exerciseId,
    String? exerciseName,
    required double averageActualRestMs,
    double? plannedRestMs,
    required DateTime sessionDate,
    int? setCount,
  }) async {
    final doc = _collection(gymId, userId).doc(_docId(deviceId, exerciseId));
    final normalizedSetCount = setCount ?? 0;
    final totalRestDuration = normalizedSetCount > 0
        ? averageActualRestMs * normalizedSetCount
        : averageActualRestMs;
    final payload = <String, dynamic>{
      'deviceId': deviceId,
      'deviceName': deviceName,
      'exerciseId': exerciseId ?? '',
      'exerciseName': exerciseName ?? '',
      'sampleCount': FieldValue.increment(1),
      'sumActualRestMs': FieldValue.increment(averageActualRestMs),
      'sumActualRestDurationMs': FieldValue.increment(totalRestDuration),
      'sumPlannedRestMs': FieldValue.increment(plannedRestMs ?? 0),
      'plannedSampleCount':
          FieldValue.increment(plannedRestMs != null ? 1 : 0),
      'lastSessionAt': Timestamp.fromDate(sessionDate),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (normalizedSetCount > 0) {
      payload['sumSetCount'] = FieldValue.increment(normalizedSetCount);
    }
    await doc.set(payload, SetOptions(merge: true));
  }

  Future<List<RestStatSummary>> fetchStats({
    required String gymId,
    required String userId,
  }) async {
    final snap = await _collection(gymId, userId)
        .orderBy('sumActualRestMs', descending: true)
        .get();
    return snap.docs.map(RestStatSummary.fromFirestore).toList();
  }
}

final restStatsServiceProvider = Provider<RestStatsService>((ref) {
  return RestStatsService(firestore: FirebaseFirestore.instance);
});
