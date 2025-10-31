import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/gym_member.dart';

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
          final snapshot = await _firestore
              .collection('users')
              .doc(member.id)
              .collection('trainingDayXP')
              .count()
              .get();
          return MapEntry(member.id, snapshot.count ?? 0);
        } on FirebaseException catch (error, stackTrace) {
          debugPrint(
            'Failed to load training day count for ${member.id}: ${error.message ?? error.code}',
          );
          debugPrintStack(stackTrace: stackTrace);
          return MapEntry(member.id, 0);
        } catch (error, stackTrace) {
          debugPrint(
            'Failed to load training day count for ${member.id}: $error',
          );
          debugPrintStack(stackTrace: stackTrace);
          return MapEntry(member.id, 0);
        }
      }),
    );

    return {for (final entry in entries) entry.key: entry.value};
  }
}
