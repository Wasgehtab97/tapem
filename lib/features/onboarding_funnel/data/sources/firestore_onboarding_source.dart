import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/gym_member_detail.dart';
import '../../domain/models/gym_member_summary.dart';

class FirestoreOnboardingSource {
  FirestoreOnboardingSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<int> countMembers(String gymId) async {
    final query = _firestore.collection('gyms').doc(gymId).collection('users');
    return _countQuery(query);
  }

  Future<GymMemberDetail?> fetchMemberDetail(
    String gymId,
    String memberNumber,
  ) async {
    final sanitizedNumber = _normalizeMemberNumber(memberNumber);
    final collection = _firestore.collection('gyms').doc(gymId).collection('users');

    final membershipSnapshot = await collection
        .where('memberNumber', isEqualTo: sanitizedNumber)
        .limit(1)
        .get();

    if (membershipSnapshot.docs.isEmpty) {
      return null;
    }

    final membershipDoc = membershipSnapshot.docs.first;
    final membershipData = membershipDoc.data();
    final createdAt = (membershipData['createdAt'] as Timestamp?)?.toDate();
    final summary = GymMemberSummary(
      userId: membershipDoc.id,
      memberNumber: sanitizedNumber,
      createdAt: createdAt,
    );

    final userRef = _firestore.collection('users').doc(summary.userId);
    final userSnapshot = await userRef.get();
    final userData = userSnapshot.data();
    final username = (userData?['username'] as String?)?.trim();
    final email = (userData?['email'] as String?)?.trim();
    final displayName = (username?.isNotEmpty ?? false)
        ? username
        : (email?.isNotEmpty ?? false)
            ? email
            : null;
    final userCreatedAt = (userData?['createdAt'] as Timestamp?)?.toDate();

    final trainingQuery = userRef.collection('trainingDayXP');
    final totalTrainingDays = await _countQuery(trainingQuery);

    return GymMemberDetail(
      summary: summary,
      displayName: displayName,
      email: email,
      userCreatedAt: userCreatedAt,
      totalTrainingDays: totalTrainingDays,
      hasCompletedFirstScan: totalTrainingDays > 0,
    );
  }

  Future<int> _countQuery(Query<Map<String, dynamic>> query) async {
    try {
      final aggregate = await query.count().get();
      return aggregate.count;
    } on FirebaseException catch (error) {
      if (error.code == 'unimplemented') {
        final snapshot = await query.get();
        return snapshot.docs.length;
      }
      rethrow;
    } on UnsupportedError {
      final snapshot = await query.get();
      return snapshot.docs.length;
    }
  }

  String _normalizeMemberNumber(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return '0000';
    }
    final normalized = digitsOnly.padLeft(4, '0');
    return normalized.substring(normalized.length - 4);
  }
}
