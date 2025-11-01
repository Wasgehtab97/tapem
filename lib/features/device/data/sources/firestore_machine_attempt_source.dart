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
    int limit = 3,
  }) async {
    // Firestore requires ordering on `createdAt` when range filters are used.
    // We fetch a slightly larger window and perform further filtering and
    // sorting on the client to avoid additional composite index requirements.
    var queryLimit = limit;
    if (limit > 0) {
      final scaled = limit * 20;
      if (scaled > queryLimit) {
        queryLimit = scaled;
      }
      if (queryLimit > 100) {
        queryLimit = 100;
      }
    }

    final effectiveLimit = queryLimit > 0 ? queryLimit : 50;

    final query = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('machines')
        .doc(machineId)
        .collection('attempts')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startUtc),
        )
        .where(
          'createdAt',
          isLessThan: Timestamp.fromDate(endUtc),
        )
        .orderBy('createdAt', descending: true)
        .limit(effectiveLimit);

    final snap = await query.get();
    return snap.docs.map(MachineAttemptDto.fromDocument).toList();
  }
}
