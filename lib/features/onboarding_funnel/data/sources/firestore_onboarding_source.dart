import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/gym_member_detail.dart';
import '../../domain/models/gym_member_summary.dart';
import '../../domain/utils/member_number_utils.dart';
import '../../utils/onboarding_funnel_logger.dart';

class FirestoreOnboardingSource {
  FirestoreOnboardingSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<int> countMembers(String gymId) async {
    final query = _firestore.collection('gyms').doc(gymId).collection('users');
    logOnboardingFunnel(
      'countMembers:start',
      scope: 'OnboardingFunnel.FirestoreSource',
      data: {'gymId': gymId},
    );
    final count = await _countQuery(
      query,
      debugName: 'gyms/$gymId/users',
    );
    logOnboardingFunnel(
      'countMembers:success',
      scope: 'OnboardingFunnel.FirestoreSource',
      data: {'gymId': gymId, 'count': count},
    );
    return count;
  }

  Future<GymMemberDetail?> fetchMemberDetail(
    String gymId,
    String memberNumber,
  ) async {
    final normalized = normalizeMemberNumber(memberNumber);
    logOnboardingFunnel(
      'fetchMemberDetail:start',
      scope: 'OnboardingFunnel.FirestoreSource',
      data: {
        'gymId': gymId,
        'input': memberNumber,
        'normalized': normalized,
      },
    );

    if (normalized == null) {
      logOnboardingFunnel(
        'fetchMemberDetail:skip-empty',
        scope: 'OnboardingFunnel.FirestoreSource',
        data: {'gymId': gymId, 'input': memberNumber},
      );
      return null;
    }

    final collection = _firestore.collection('gyms').doc(gymId).collection('users');

    QuerySnapshot<Map<String, dynamic>> membershipSnapshot = await collection
        .where('memberNumber', isEqualTo: normalized)
        .limit(1)
        .get();

    if (membershipSnapshot.docs.isEmpty) {
      final numericMemberNumber = int.tryParse(normalized);
      if (numericMemberNumber != null) {
        logOnboardingFunnel(
          'fetchMemberDetail:fallback-numeric-query',
          scope: 'OnboardingFunnel.FirestoreSource',
          data: {
            'gymId': gymId,
            'normalized': normalized,
            'numeric': numericMemberNumber,
          },
        );
        membershipSnapshot = await collection
            .where('memberNumber', isEqualTo: numericMemberNumber)
            .limit(1)
            .get();
      }
    }

    if (membershipSnapshot.docs.isEmpty) {
      logOnboardingFunnel(
        'fetchMemberDetail:not-found',
        scope: 'OnboardingFunnel.FirestoreSource',
        data: {
          'gymId': gymId,
          'normalized': normalized,
        },
      );
      return null;
    }

    final membershipDoc = membershipSnapshot.docs.first;
    final membershipData = membershipDoc.data();
    final createdAt = (membershipData['createdAt'] as Timestamp?)?.toDate();
    final summary = GymMemberSummary(
      userId: membershipDoc.id,
      memberNumber: normalized,
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
    final totalTrainingDays = await _countQuery(
      trainingQuery,
      debugName: 'users/${summary.userId}/trainingDayXP',
    );

    logOnboardingFunnel(
      'fetchMemberDetail:success',
      scope: 'OnboardingFunnel.FirestoreSource',
      data: {
        'gymId': gymId,
        'userId': summary.userId,
        'memberNumber': summary.memberNumber,
        'trainingDays': totalTrainingDays,
      },
    );

    return GymMemberDetail(
      summary: summary,
      displayName: displayName,
      email: email,
      userCreatedAt: userCreatedAt,
      totalTrainingDays: totalTrainingDays,
      hasCompletedFirstScan: totalTrainingDays > 0,
    );
  }

  Future<int> _countQuery(
    Query<Map<String, dynamic>> query, {
    required String debugName,
  }) async {
    logOnboardingFunnel(
      'countQuery:start',
      scope: 'OnboardingFunnel.FirestoreSource',
      data: {'query': debugName},
    );
    try {
      final aggregate = await query.count().get();
      final count = aggregate.count;
      if (count != null) {
        logOnboardingFunnel(
          'countQuery:aggregate',
          scope: 'OnboardingFunnel.FirestoreSource',
          data: {
            'query': debugName,
            'count': count,
          },
        );
        return count;
      }
      final snapshot = await query.get();
      final fallbackCount = snapshot.docs.length;
      logOnboardingFunnel(
        'countQuery:aggregate-null-fallback',
        scope: 'OnboardingFunnel.FirestoreSource',
        data: {'query': debugName, 'count': fallbackCount},
      );
      return fallbackCount;
    } on FirebaseException catch (error, stack) {
      if (error.code == 'unimplemented') {
        final snapshot = await query.get();
        final fallbackCount = snapshot.docs.length;
        logOnboardingFunnel(
          'countQuery:fallback-unimplemented',
          scope: 'OnboardingFunnel.FirestoreSource',
          data: {'query': debugName, 'count': fallbackCount},
        );
        return fallbackCount;
      }
      logOnboardingFunnel(
        'countQuery:error',
        scope: 'OnboardingFunnel.FirestoreSource',
        data: {'query': debugName},
        error: error,
        stackTrace: stack,
      );
      rethrow;
    } on UnsupportedError catch (error, stack) {
      final snapshot = await query.get();
      final fallbackCount = snapshot.docs.length;
      logOnboardingFunnel(
        'countQuery:fallback-unsupported',
        scope: 'OnboardingFunnel.FirestoreSource',
        data: {'query': debugName, 'count': fallbackCount},
        error: error,
        stackTrace: stack,
      );
      return fallbackCount;
    }
  }
}
