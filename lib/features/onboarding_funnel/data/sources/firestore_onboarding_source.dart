import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/gym_member_detail.dart';
import '../../domain/models/gym_member_summary.dart';

class FirestoreOnboardingSource {
  FirestoreOnboardingSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<int> countMembers(String gymId) async {
    final query = _firestore.collection('gyms').doc(gymId).collection('users');
    developer.log(
      'Counting members for gymId=$gymId',
      name: _logTag,
    );
    return _countQuery(query);
  }

  Future<GymMemberDetail?> fetchMemberDetail(
    String gymId,
    String memberNumber,
  ) async {
    final sanitizedNumber = _normalizeMemberNumber(memberNumber);
    final collection = _firestore.collection('gyms').doc(gymId).collection('users');
    developer.log(
      'Fetching member detail for input="$memberNumber" normalized="$sanitizedNumber"',
      name: _logTag,
    );

    final membershipDoc = await _findMembershipDocument(collection, sanitizedNumber);

    if (membershipDoc == null) {
      developer.log(
        'No membership found for normalized memberNumber=$sanitizedNumber',
        name: _logTag,
      );
      return null;
    }

    final membershipData = membershipDoc.data();
    final createdAt = (membershipData['createdAt'] as Timestamp?)?.toDate();
    final summary = GymMemberSummary(
      userId: membershipDoc.id,
      memberNumber: sanitizedNumber,
      createdAt: createdAt,
    );

    final userRef = _firestore.collection('users').doc(summary.userId);
    final userSnapshot = await userRef.get();
    developer.log(
      'Fetched membership for userId=${summary.userId}. Loading profile and training stats.',
      name: _logTag,
    );
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
    int totalTrainingDays;
    try {
      totalTrainingDays = await _countQuery(trainingQuery);
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        developer.log(
          'Permission denied when counting training days for userId=${summary.userId}. '
          'Defaulting trainingDays to 0.',
          name: _logTag,
          error: error,
        );
        totalTrainingDays = 0;
      } else {
        rethrow;
      }
    }
    developer.log(
      'Resolved onboarding detail for userId=${summary.userId}: '
      'memberNumber=$sanitizedNumber, trainingDays=$totalTrainingDays',
      name: _logTag,
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

  Future<int> _countQuery(Query<Map<String, dynamic>> query) async {
    try {
      final aggregate = await query.count().get();
      final count = aggregate.count;
      if (count != null) {
        developer.log(
          'Aggregate count available (value=$count)',
          name: _logTag,
        );
        return count;
      }
      final snapshot = await query.get();
      developer.log(
        'Aggregate count missing. Fallback snapshot size=${snapshot.docs.length}',
        name: _logTag,
      );
      return snapshot.docs.length;
    } on FirebaseException catch (error) {
      if (error.code == 'unimplemented') {
        final snapshot = await query.get();
        developer.log(
          'Aggregate not supported. Fallback snapshot size=${snapshot.docs.length}',
          name: _logTag,
        );
        return snapshot.docs.length;
      }
      rethrow;
    } on UnsupportedError {
      final snapshot = await query.get();
      developer.log(
        'Unsupported aggregate. Fallback snapshot size=${snapshot.docs.length}',
        name: _logTag,
      );
      return snapshot.docs.length;
    }
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _findMembershipDocument(
    CollectionReference<Map<String, dynamic>> collection,
    String sanitizedNumber,
  ) async {
    final attempts = <_MembershipLookupAttempt>[
      _MembershipLookupAttempt(
        description: 'memberNumber (string)',
        queryBuilder: () => collection
            .where('memberNumber', isEqualTo: sanitizedNumber)
            .limit(1),
      ),
      _MembershipLookupAttempt(
        description: 'memberNumberNormalized (string)',
        queryBuilder: () => collection
            .where('memberNumberNormalized', isEqualTo: sanitizedNumber)
            .limit(1),
      ),
    ];

    final numericValue = int.tryParse(sanitizedNumber);
    if (numericValue != null) {
      attempts.addAll([
        _MembershipLookupAttempt(
          description: 'memberNumber (numeric)',
          queryBuilder: () => collection
              .where('memberNumber', isEqualTo: numericValue)
              .limit(1),
        ),
        _MembershipLookupAttempt(
          description: 'memberNumberInt (numeric)',
          queryBuilder: () => collection
              .where('memberNumberInt', isEqualTo: numericValue)
              .limit(1),
        ),
        _MembershipLookupAttempt(
          description: 'memberNumberNumeric (numeric)',
          queryBuilder: () => collection
              .where('memberNumberNumeric', isEqualTo: numericValue)
              .limit(1),
        ),
      ]);
    }

    for (final attempt in attempts) {
      try {
        developer.log(
          'Attempting membership lookup using ${attempt.description}',
          name: _logTag,
        );
        final snapshot = await attempt.queryBuilder().get();
        if (snapshot.docs.isNotEmpty) {
          developer.log(
            'Membership lookup successful via ${attempt.description}',
            name: _logTag,
          );
          return snapshot.docs.first;
        }
      } on FirebaseException catch (error) {
        developer.log(
          'Firebase error during membership lookup via ${attempt.description}',
          name: _logTag,
          error: error,
        );
        rethrow;
      }
    }

    return null;
  }

  String _normalizeMemberNumber(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return '0000';
    }
    final normalized = digitsOnly.padLeft(4, '0');
    return normalized.substring(normalized.length - 4);
  }

  static const String _logTag = 'FirestoreOnboardingSource';
}

class _MembershipLookupAttempt {
  const _MembershipLookupAttempt({
    required this.description,
    required this.queryBuilder,
  });

  final String description;
  final Query<Map<String, dynamic>> Function() queryBuilder;
}
