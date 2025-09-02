import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../dtos/session_dto.dart';

/// Liest alle Log‐Einträge (collectionGroup "logs") für ein Datum aus.
class FirestoreSessionSource {
  final FirebaseFirestore _firestore;

  FirestoreSessionSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<SessionDto>> getSessionsForDate({
    required String userId,
    required DateTime date,
  }) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));

    debugPrint('FirestoreSessionSource: read path=collectionGroup/logs owner=' +
        userId +
        ' start=' +
        start.toString() +
        ' end=' +
        end.toString());

    try {
      final snap = await _firestore
          .collectionGroup('logs')
          .where('userId', isEqualTo: userId)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      debugPrint('FirestoreSessionSource: success path=collectionGroup/logs owner=' +
          userId +
          ' docs=' +
          snap.docs.length.toString());

      return snap.docs.map((doc) => SessionDto.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      debugPrint('FirestoreSessionSource: failure path=collectionGroup/logs owner=' +
          userId +
          ' code=' +
          e.code);
      rethrow;
    }
  }

  Future<void> backfillSetNumbers(List<SessionDto> dtos) async {
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
