// lib/features/history/data/sources/firestore_history_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../dtos/workout_log_dto.dart';

/// Liefert alle Workout-Logs für ein Gerät [deviceId] im Gym [gymId] und User [userId].
class FirestoreHistorySource {
  final FirebaseFirestore _firestore;

  FirestoreHistorySource([FirebaseFirestore? instance])
    : _firestore = instance ?? FirebaseFirestore.instance;

  Future<List<WorkoutLogDto>> getLogs({
    required String gymId,
    required String deviceId,
    required String userId,
    String? exerciseId,
  }) async {
    var query = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('logs')
        .where('userId', isEqualTo: userId);
    if (exerciseId != null) {
      query = query.where('exerciseId', isEqualTo: exerciseId);
    }
    // Composite index on userId+exerciseId+timestamp may be required.
    final snapshot = await query.orderBy('timestamp', descending: true).get();

    return snapshot.docs.map((doc) => WorkoutLogDto.fromDocument(doc)).toList();
  }

  Future<void> backfillSetNumbers(List<WorkoutLogDto> dtos) async {
    final batch = _firestore.batch();
    for (var i = 0; i < dtos.length; i++) {
      batch.update(dtos[i].reference, {
        'setNumber': i + 1,
        'backfilled': true,
      });
    }
    await batch.commit();
  }
}
