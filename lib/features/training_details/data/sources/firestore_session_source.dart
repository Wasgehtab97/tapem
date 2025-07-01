import 'package:cloud_firestore/cloud_firestore.dart';
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

    final snap = await _firestore
        .collectionGroup('logs')
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    return snap.docs.map((doc) => SessionDto.fromFirestore(doc)).toList();
  }
}
