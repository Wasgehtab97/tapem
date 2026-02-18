import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/observability/owner_query_budget_service.dart';
import 'package:tapem/features/report/data/training_day_repository.dart';
import 'package:tapem/features/report/domain/gym_member.dart';

void main() {
  group('TrainingDayRepository', () {
    late FakeFirebaseFirestore firestore;
    late OwnerQueryBudgetService queryBudgetService;
    late TrainingDayRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      queryBudgetService = OwnerQueryBudgetService();
      queryBudgetService.resetForTests();
      repository = TrainingDayRepository(
        firestore: firestore,
        queryBudgetService: queryBudgetService,
      );
    });

    test('watchGymMembers maps and filters gym members', () async {
      await firestore.doc('gyms/g1/users/u3').set({
        'memberNumber': '0003',
        'role': 'member',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 2, 1)),
      });
      await firestore.doc('gyms/g1/users/u1').set({
        'memberNumber': '0001',
        'role': 'gymowner',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      });
      await firestore.doc('gyms/g1/users/u2').set({
        'memberNumber': '',
        'role': 'member',
      });

      final members = await repository.watchGymMembers('g1').first;

      expect(members.length, 2);
      expect(members[0].id, 'u1');
      expect(members[0].memberNumber, '0001');
      expect(members[0].role, 'gymowner');
      expect(members[0].createdAt?.toUtc(), DateTime.utc(2026, 1, 1));
      expect(members[1].id, 'u3');
      expect(members[1].memberNumber, '0003');
    });

    test('watchGymMembers emits empty list when gym has no users', () async {
      final members = await repository.watchGymMembers('g-empty').first;
      expect(members, isEmpty);
    });

    test('fetchTrainingDayCounts tracks query budget metrics', () async {
      await firestore.doc('users/u1/trainingDayXP/d1').set({'xp': 10});
      await firestore.doc('users/u1/trainingDayXP/d2').set({'xp': 20});
      await firestore.doc('users/u2/trainingDayXP/d1').set({'xp': 30});

      final members = [
        GymMember(
          id: 'u1',
          memberNumber: '0001',
          role: 'member',
          createdAt: null,
        ),
        GymMember(
          id: 'u2',
          memberNumber: '0002',
          role: 'member',
          createdAt: null,
        ),
      ];

      final counts = await repository.fetchTrainingDayCounts(members);
      expect(counts['u1'], 2);
      expect(counts['u2'], 1);

      final metric = queryBudgetService.metrics.metricFor(
        'owner.report.members_training_day_counts',
      );
      expect(metric.runs, 1);
      expect(metric.lastQueries, 2);
      expect(metric.lastDocsRead, 2);
      expect(metric.lastBudgetExceeded, isFalse);
    });
  });
}
