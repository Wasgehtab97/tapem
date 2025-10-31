import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/gym_member.dart';

class TrainingDayAccessDenied implements Exception {
  TrainingDayAccessDenied(this.userId);

  final String userId;

  @override
  String toString() => 'TrainingDayAccessDenied(userId: $userId)';
}

class TrainingDayRepository {
  TrainingDayRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<Map<String, int>> fetchTrainingDayCounts(
    List<GymMember> members,
  ) async {
    if (members.isEmpty) {
      return const {};
    }

    final entries = await Future.wait(
      members.map((member) async {
        try {
          final aggregateQuery = _firestore
              .collection('users')
              .doc(member.id)
              .collection('trainingDayXP')
              .count();
          final snapshot = await aggregateQuery.get();
          return MapEntry(member.id, snapshot.count ?? 0);
        } on FirebaseException catch (error, stackTrace) {
          if (error.code == 'permission-denied') {
            throw TrainingDayAccessDenied(member.id);
          }
          debugPrint(
            'Failed to load training day count for ${member.id}: ${error.message ?? error.code}',
          );
          debugPrintStack(stackTrace: stackTrace);
          rethrow;
        } catch (error, stackTrace) {
          debugPrint(
            'Failed to load training day count for ${member.id}: $error',
          );
          debugPrintStack(stackTrace: stackTrace);
          rethrow;
        }
      }),
    );

    return {for (final entry in entries) entry.key: entry.value};
  }
}
