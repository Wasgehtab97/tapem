import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tapem/core/observability/owner_query_budget_service.dart';

import '../domain/gym_member.dart';

class TrainingDayAccessDenied implements Exception {
  TrainingDayAccessDenied(this.userId);

  final String userId;

  @override
  String toString() => 'TrainingDayAccessDenied(userId: $userId)';
}

class TrainingDayRepository {
  TrainingDayRepository({
    FirebaseFirestore? firestore,
    OwnerQueryBudgetService? queryBudgetService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _queryBudgetService =
           queryBudgetService ?? OwnerQueryBudgetService.instance;

  final FirebaseFirestore _firestore;
  final OwnerQueryBudgetService _queryBudgetService;
  static const OwnerQueryBudget _trainingDayCountsBudget = OwnerQueryBudget(
    maxQueries: 250,
    maxDocsRead: 250,
  );

  Stream<List<GymMember>> watchGymMembers(String gymId) {
    return _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .orderBy('memberNumber')
        .snapshots()
        .map((snapshot) {
          final members = snapshot.docs
              .map(GymMember.fromSnapshot)
              .whereType<GymMember>()
              .where((member) => member.memberNumber.isNotEmpty)
              .toList(growable: false);
          return members;
        });
  }

  Future<Map<String, int>> fetchTrainingDayCounts(
    List<GymMember> members,
  ) async {
    return _queryBudgetService.track<Map<String, int>>(
      flow: 'owner.report.members_training_day_counts',
      budget: _trainingDayCountsBudget,
      command: (counter) async {
        if (members.isEmpty) {
          return const {};
        }

        const batchSize = 20;
        final result = <String, int>{};
        for (var i = 0; i < members.length; i += batchSize) {
          final chunk = members.skip(i).take(batchSize);
          final entries = await Future.wait(
            chunk.map((member) async {
              try {
                final aggregateQuery = _firestore
                    .collection('users')
                    .doc(member.id)
                    .collection('trainingDayXP')
                    .count();
                final snapshot = await aggregateQuery.get();
                counter.recordQueryResult(docsRead: 1);
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
          for (final entry in entries) {
            result[entry.key] = entry.value;
          }
        }

        return result;
      },
    );
  }
}
