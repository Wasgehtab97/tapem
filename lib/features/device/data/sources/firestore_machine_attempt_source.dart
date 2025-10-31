import 'package:cloud_firestore/cloud_firestore.dart';

import '../dtos/machine_attempt_dto.dart';

class FirestoreMachineAttemptSource {
  final FirebaseFirestore _firestore;

  FirestoreMachineAttemptSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<MachineAttemptDto>> fetchAttempts({
    required String gymId,
    required String machineId,
    required DateTime startUtc,
    required DateTime endUtc,
    String? gender,
    int limit = 3,
  }) async {
    // Firestore requires ordering on `createdAt` when range filters are used.
    // To still surface the heaviest lifts for the leaderboard we fetch a
    // slightly larger window and sort locally afterwards.
    var queryLimit = limit;
    if (limit > 0) {
      final scaled = limit * 10;
      if (scaled > queryLimit) {
        queryLimit = scaled;
      }
      if (queryLimit > 60) {
        queryLimit = 60;
      }
    }

    Query<Map<String, dynamic>> query = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('machines')
        .doc(machineId)
        .collection('attempts')
        .where('isMulti', isEqualTo: false)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startUtc))
        .where('createdAt', isLessThan: Timestamp.fromDate(endUtc))
        .orderBy('createdAt', descending: true)
        .orderBy('e1rm', descending: true)
        .limit(queryLimit);

    if (gender != null) {
      query = query.where('gender', isEqualTo: gender);
    }

    final snap = await query.get();
    return snap.docs.map(MachineAttemptDto.fromDocument).toList();
  }
}
