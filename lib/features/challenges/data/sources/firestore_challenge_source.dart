import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:async/async.dart';
import '../../domain/models/challenge.dart';
import '../../domain/models/badge.dart';

class FirestoreChallengeSource {
  final FirebaseFirestore _firestore;

  FirestoreChallengeSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<Challenge>> watchActiveChallenges(String gymId) {
    final now = Timestamp.fromDate(DateTime.now());
    final weekly = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('weekly')
        .where('start', isLessThanOrEqualTo: now)
        .where('end', isGreaterThanOrEqualTo: now)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Challenge.fromMap(d.id, d.data())).toList());
    final monthly = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('monthly')
        .where('start', isLessThanOrEqualTo: now)
        .where('end', isGreaterThanOrEqualTo: now)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Challenge.fromMap(d.id, d.data())).toList());

    return StreamZip([weekly, monthly])
        .map((lists) => [...lists[0], ...lists[1]]);
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
