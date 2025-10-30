import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/gym_member_detail.dart';
import '../../domain/models/gym_member_summary.dart';
import '../../domain/utils/member_number_formatter.dart';

class FirestoreOnboardingSource {
  FirestoreOnboardingSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<int> countMembers(String gymId) async {
    final query = _firestore.collection('gyms').doc(gymId).collection('users');
    developer.log(
      'Counting members for gym=$gymId',
      name: 'FirestoreOnboardingSource',
    );
    return _countQuery(query);
  }

  Future<GymMemberDetail?> fetchMemberDetail(
    String gymId,
    String memberNumber,
  ) async {
    final sanitizedNumber = MemberNumberFormatter.normalize(memberNumber);
    developer.log(
      'Fetching member detail for gym=$gymId number=$sanitizedNumber',
      name: 'FirestoreOnboardingSource',
    );
    final collection = _firestore.collection('gyms').doc(gymId).collection('users');

    QuerySnapshot<Map<String, dynamic>> membershipSnapshot = await collection
        .where('memberNumber', isEqualTo: sanitizedNumber)
        .limit(1)
        .get();

    if (membershipSnapshot.docs.isEmpty) {
      final numericValue = int.tryParse(sanitizedNumber);
      if (numericValue != null) {
        developer.log(
          'No string match found, retrying with numeric value=$numericValue',
          name: 'FirestoreOnboardingSource',
        );
        membershipSnapshot = await collection
            .where('memberNumber', isEqualTo: numericValue)
            .limit(1)
            .get();
      }
    }

    if (membershipSnapshot.docs.isEmpty) {
      developer.log(
        'No member found for number=$sanitizedNumber',
        name: 'FirestoreOnboardingSource',
      );
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

    developer.log(
      'Member detail loaded for userId=${summary.userId}, totalTrainingDays=$totalTrainingDays',
      name: 'FirestoreOnboardingSource',
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
      developer.log(
        'Executing count aggregate for query=$query',
        name: 'FirestoreOnboardingSource',
      );
      final aggregate = await query.count().get();
      final count = aggregate.count;
      if (count != null) {
        developer.log(
          'Aggregate count succeeded with value=$count',
          name: 'FirestoreOnboardingSource',
        );
        return count;
      }
      final snapshot = await query.get();
      developer.log(
        'Aggregate count returned null, fallback snapshot length=${snapshot.docs.length}',
        name: 'FirestoreOnboardingSource',
      );
      return snapshot.docs.length;
    } on FirebaseException catch (error) {
      if (error.code == 'unimplemented') {
        final snapshot = await query.get();
        developer.log(
          'Aggregate count unsupported, fallback snapshot length=${snapshot.docs.length}',
          name: 'FirestoreOnboardingSource',
          level: 900,
          error: error,
        );
        return snapshot.docs.length;
      }
      developer.log(
        'Aggregate count failed with FirebaseException ${error.code}',
        name: 'FirestoreOnboardingSource',
        level: 1000,
        error: error,
        stackTrace: error.stackTrace,
      );
      rethrow;
    } on UnsupportedError catch (error, stackTrace) {
      final snapshot = await query.get();
      developer.log(
        'Aggregate count unsupported by platform, fallback snapshot length=${snapshot.docs.length}',
        name: 'FirestoreOnboardingSource',
        level: 900,
        error: error,
        stackTrace: stackTrace,
      );
      return snapshot.docs.length;
    }
  }
}
