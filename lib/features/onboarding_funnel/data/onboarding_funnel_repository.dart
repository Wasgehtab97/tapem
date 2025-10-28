import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models/onboarding_member_summary.dart';

class OnboardingFunnelRepository {
  OnboardingFunnelRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<int> getRegisteredMemberCount(String gymId) async {
    final query = _firestore.collection('gyms').doc(gymId).collection('users');
    try {
      final aggregate = await query.count().get();
      return aggregate.count;
    } catch (_) {
      final snapshot = await query.get();
      return snapshot.size;
    }
  }

  Future<OnboardingMemberSummary?> getMemberByNumber(
    String gymId,
    String memberNumber,
  ) async {
    final sanitized = memberNumber.padLeft(4, '0');
    final membershipQuery = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .where('memberNumber', isEqualTo: sanitized)
        .limit(1)
        .get();

    if (membershipQuery.docs.isEmpty) {
      return null;
    }

    final membershipDoc = membershipQuery.docs.first;
    final membershipData = membershipDoc.data();
    final onboardingAssignedAt =
        (membershipData['onboardingAssignedAt'] as Timestamp?)?.toDate();
    final userId = membershipDoc.id;

    final userSnapshot = await _firestore.collection('users').doc(userId).get();
    final userData = userSnapshot.data();

    final trainingQuery =
        _firestore.collection('users').doc(userId).collection('trainingDayXP');
    int trainingDays;
    try {
      final aggregate = await trainingQuery.count().get();
      trainingDays = aggregate.count;
    } catch (_) {
      final trainingSnapshot = await trainingQuery.get();
      trainingDays = trainingSnapshot.size;
    }

    return OnboardingMemberSummary(
      userId: userId,
      memberNumber: sanitized,
      displayName: userData?['username'] as String?,
      email: userData?['email'] as String?,
      registeredAt: (userData?['createdAt'] as Timestamp?)?.toDate(),
      onboardingAssignedAt: onboardingAssignedAt,
      trainingDays: trainingDays,
    );
  }
}
