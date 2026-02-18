import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/observability/owner_query_budget_service.dart';
import 'package:tapem/features/home/application/owner_workspace_provider.dart';

void main() {
  group('FirestoreOwnerWorkspaceRepository', () {
    late FakeFirebaseFirestore firestore;
    late OwnerQueryBudgetService queryBudgetService;
    late FirestoreOwnerWorkspaceRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      queryBudgetService = OwnerQueryBudgetService();
      queryBudgetService.resetForTests();
      repository = FirestoreOwnerWorkspaceRepository(
        firestore,
        queryBudgetService: queryBudgetService,
      );
    });

    test('loads owner KPI snapshot for a gym', () async {
      final now = DateTime.now().toUtc();
      await firestore.doc('gyms/g1/users/u_member_1').set({'role': 'member'});
      await firestore.doc('gyms/g1/users/u_member_2').set({'role': 'member'});
      await firestore.doc('gyms/g1/users/u_owner').set({'role': 'gymowner'});

      await firestore.doc('gyms/g1/devices/d1').set({'name': 'Rower'});
      await firestore.doc('gyms/g1/devices/d2').set({'name': 'Bike'});

      await firestore.doc('gyms/g1/feedback/f1').set({'isDone': false});
      await firestore.doc('gyms/g1/feedback/f2').set({'isDone': true});

      await firestore.doc('gyms/g1/surveys/s1').set({'status': 'open'});
      await firestore.doc('gyms/g1/surveys/s2').set({'status': 'closed'});

      await firestore.doc('gyms/g1/challenges/weekly/items/w_active').set({
        'start': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'end': Timestamp.fromDate(now.add(const Duration(days: 1))),
      });
      await firestore.doc('gyms/g1/challenges/weekly/items/w_future').set({
        'start': Timestamp.fromDate(now.add(const Duration(days: 1))),
        'end': Timestamp.fromDate(now.add(const Duration(days: 2))),
      });
      await firestore.doc('gyms/g1/challenges/weekly/items/w_invalid').set({
        'end': Timestamp.fromDate(now.add(const Duration(days: 1))),
      });
      await firestore.doc('gyms/g1/challenges/monthly/items/m_active').set({
        'start': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        'end': Timestamp.fromDate(now.add(const Duration(days: 2))),
      });
      await firestore.doc('gyms/g1/challenges/monthly/items/m_ended').set({
        'start': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
        'end': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      });

      final snapshot = await repository.loadSnapshot('g1');

      expect(snapshot.memberCount, 2);
      expect(snapshot.deviceCount, 2);
      expect(snapshot.openFeedbackCount, 1);
      expect(snapshot.openSurveyCount, 1);
      expect(snapshot.activeChallengeCount, 2);
      expect(
        snapshot.generatedAt.isAfter(now.subtract(const Duration(minutes: 1))),
        isTrue,
      );
      expect(snapshot.isEmpty, isFalse);

      final metric = queryBudgetService.metrics.metricFor(
        'owner.workspace.snapshot',
      );
      expect(metric.runs, 1);
      expect(metric.lastQueries, 6);
      expect(metric.lastBudgetExceeded, isFalse);
    });

    test('returns empty snapshot when gym has no relevant data', () async {
      final snapshot = await repository.loadSnapshot('g-empty');

      expect(snapshot.memberCount, 0);
      expect(snapshot.deviceCount, 0);
      expect(snapshot.openFeedbackCount, 0);
      expect(snapshot.openSurveyCount, 0);
      expect(snapshot.activeChallengeCount, 0);
      expect(snapshot.isEmpty, isTrue);
    });
  });
}
