import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/challenge.dart';
import '../../domain/models/badge.dart';

class FirestoreChallengeSource {
  final FirebaseFirestore _firestore;

  FirestoreChallengeSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<Challenge>> watchActiveChallenges() {
    final now = Timestamp.fromDate(DateTime.now());
    final query = _firestore
        .collection('challenges')
        .where('start', isLessThanOrEqualTo: now)
        .where('end', isGreaterThanOrEqualTo: now);
    return query.snapshots().map((snap) => snap.docs
        .map((d) => Challenge.fromMap(d.id, d.data()))
        .toList());
  }

  Stream<List<Badge>> watchBadges(String userId) {
    final col = _firestore.collection('users').doc(userId).collection('badges');
    return col
        .orderBy('awardedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Badge.fromMap(d.id, d.data())).toList());
  }
}
