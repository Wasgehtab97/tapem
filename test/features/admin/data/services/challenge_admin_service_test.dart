import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/observability/owner_action_observability_service.dart';
import 'package:tapem/core/services/admin_audit_logger.dart';
import 'package:tapem/features/admin/data/services/challenge_admin_service.dart';

void main() {
  group('ChallengeAdminService', () {
    late FakeFirebaseFirestore firestore;
    late OwnerActionObservabilityService observability;
    late ChallengeAdminService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      observability = OwnerActionObservabilityService.instance;
      observability.resetForTests();
      service = ChallengeAdminService(
        firestore: firestore,
        auditLogger: AdminAuditLogger(firestore: firestore),
        observability: observability,
      );
    });

    test('creates weekly challenge and writes admin audit', () async {
      final result = await service.createChallenge(
        const ChallengeAdminCreateInput(
          gymId: 'gym-a',
          actorUid: 'owner-1',
          title: 'Weekly Push',
          description: 'Push at least 20 sets',
          goalType: AdminChallengeGoalType.deviceSets,
          deviceIds: <String>['d1', 'd2', 'd2'],
          minSets: 20,
          xpReward: 50,
          period: AdminChallengePeriod.weekly,
          periodValue: 8,
          year: 2026,
        ),
      );

      expect(result.challengeId, isNotEmpty);
      final challengeDoc = await firestore
          .collection('gyms')
          .doc('gym-a')
          .collection('challenges')
          .doc('weekly')
          .collection('items')
          .doc(result.challengeId)
          .get();
      expect(challengeDoc.exists, isTrue);
      final data = challengeDoc.data()!;
      expect(data['title'], 'Weekly Push');
      expect(data['description'], 'Push at least 20 sets');
      expect(data['minSets'], 20);
      expect(data['xpReward'], 50);
      expect(data['goalType'], 'device_sets');
      expect((data['deviceIds'] as List).length, 2);
      expect(data['startWeek'], 8);
      expect(data['endWeek'], 8);
      expect(data['start'], isA<Timestamp>());
      expect(data['end'], isA<Timestamp>());

      final auditDocs = await firestore
          .collection('gyms')
          .doc('gym-a')
          .collection('adminAudit')
          .get();
      expect(auditDocs.docs.length, 1);
      final auditData = auditDocs.docs.first.data();
      expect(auditData['action'], 'challenge_create');
      expect(auditData['actorUid'], 'owner-1');
      expect(auditData['metadata'], containsPair('challengeType', 'weekly'));
      expect(
        auditData['metadata'],
        containsPair('challengeId', result.challengeId),
      );
      expect(auditData['metadata'], containsPair('deviceCount', 3));
      expect(
        auditData['metadata'],
        containsPair('challengeGoalType', 'deviceSets'),
      );

      final metric = observability.metrics.metricFor('owner.challenges.create');
      expect(metric.attempts, 1);
      expect(metric.successes, 1);
      expect(metric.failures, 0);
    });

    test('creates monthly challenge in monthly collection', () async {
      final result = await service.createChallenge(
        const ChallengeAdminCreateInput(
          gymId: 'gym-a',
          actorUid: 'owner-1',
          title: 'Monthly Cardio',
          description: 'Cardio month',
          goalType: AdminChallengeGoalType.deviceSets,
          deviceIds: <String>['bike'],
          minSets: 10,
          xpReward: 80,
          period: AdminChallengePeriod.monthly,
          periodValue: 11,
          year: 2026,
        ),
      );

      final challengeDoc = await firestore
          .collection('gyms')
          .doc('gym-a')
          .collection('challenges')
          .doc('monthly')
          .collection('items')
          .doc(result.challengeId)
          .get();
      expect(challengeDoc.exists, isTrue);
      final data = challengeDoc.data()!;
      expect(data['startMonth'], 11);
      expect(data['endMonth'], 11);
    });

    test('loads campaigns from weekly and monthly collections', () async {
      await service.createChallenge(
        const ChallengeAdminCreateInput(
          gymId: 'gym-a',
          actorUid: 'owner-1',
          title: 'Weekly One',
          description: 'Weekly challenge',
          goalType: AdminChallengeGoalType.deviceSets,
          deviceIds: <String>['d1'],
          minSets: 10,
          xpReward: 60,
          period: AdminChallengePeriod.weekly,
          periodValue: 8,
          year: 2026,
        ),
      );
      await service.createChallenge(
        const ChallengeAdminCreateInput(
          gymId: 'gym-a',
          actorUid: 'owner-1',
          title: 'Monthly One',
          description: 'Monthly challenge',
          goalType: AdminChallengeGoalType.totalReps,
          targetReps: 900,
          xpReward: 100,
          period: AdminChallengePeriod.monthly,
          periodValue: 3,
          year: 2026,
        ),
      );

      final campaigns = await service.loadChallengeCampaigns(gymId: 'gym-a');
      expect(campaigns.length, 2);
      expect(
        campaigns.any((entry) => entry.period == AdminChallengePeriod.weekly),
        isTrue,
      );
      expect(
        campaigns.any((entry) => entry.period == AdminChallengePeriod.monthly),
        isTrue,
      );
    });

    test('creates workout frequency challenge for 4 calendar weeks', () async {
      final result = await service.createChallenge(
        const ChallengeAdminCreateInput(
          gymId: 'gym-a',
          actorUid: 'owner-1',
          title: '4 Week Streak',
          description: 'Train 12 times in 4 calendar weeks',
          goalType: AdminChallengeGoalType.workoutFrequency,
          targetWorkouts: 12,
          durationWeeks: 4,
          xpReward: 120,
          period: AdminChallengePeriod.weekly,
          periodValue: 5,
          year: 2026,
        ),
      );

      final challengeDoc = await firestore
          .collection('gyms')
          .doc('gym-a')
          .collection('challenges')
          .doc('weekly')
          .collection('items')
          .doc(result.challengeId)
          .get();
      expect(challengeDoc.exists, isTrue);
      final data = challengeDoc.data()!;
      expect(data['goalType'], 'workout_days');
      expect(data['targetWorkouts'], 12);
      expect(data['durationWeeks'], 4);
      expect(data['deviceIds'], isEmpty);
      expect(data['minSets'], 0);

      final start = (data['start'] as Timestamp).toDate();
      final end = (data['end'] as Timestamp).toDate();
      expect(end.difference(start).inDays, 27);
    });

    test('creates total reps challenge', () async {
      final result = await service.createChallenge(
        const ChallengeAdminCreateInput(
          gymId: 'gym-a',
          actorUid: 'owner-1',
          title: 'Rep Storm',
          description: 'Collect 1200 reps',
          goalType: AdminChallengeGoalType.totalReps,
          targetReps: 1200,
          xpReward: 140,
          period: AdminChallengePeriod.monthly,
          periodValue: 3,
          year: 2026,
        ),
      );

      final challengeDoc = await firestore
          .collection('gyms')
          .doc('gym-a')
          .collection('challenges')
          .doc('monthly')
          .collection('items')
          .doc(result.challengeId)
          .get();
      final data = challengeDoc.data()!;
      expect(data['goalType'], 'total_reps');
      expect(data['targetReps'], 1200);
      expect(data['targetVolume'], 0);
      expect(data['targetDistinctDevices'], 0);
      expect(data['deviceIds'], isEmpty);
    });

    test('creates total volume challenge', () async {
      final result = await service.createChallenge(
        const ChallengeAdminCreateInput(
          gymId: 'gym-a',
          actorUid: 'owner-1',
          title: 'Volume Storm',
          description: 'Collect volume',
          goalType: AdminChallengeGoalType.totalVolume,
          targetVolume: 24000,
          xpReward: 160,
          period: AdminChallengePeriod.weekly,
          periodValue: 7,
          year: 2026,
        ),
      );

      final challengeDoc = await firestore
          .collection('gyms')
          .doc('gym-a')
          .collection('challenges')
          .doc('weekly')
          .collection('items')
          .doc(result.challengeId)
          .get();
      final data = challengeDoc.data()!;
      expect(data['goalType'], 'total_volume');
      expect(data['targetVolume'], 24000);
      expect(data['targetReps'], 0);
      expect(data['targetDistinctDevices'], 0);
    });

    test('creates device variety challenge', () async {
      final result = await service.createChallenge(
        const ChallengeAdminCreateInput(
          gymId: 'gym-a',
          actorUid: 'owner-1',
          title: 'Explorer',
          description: 'Use many devices',
          goalType: AdminChallengeGoalType.deviceVariety,
          targetDistinctDevices: 6,
          xpReward: 125,
          period: AdminChallengePeriod.weekly,
          periodValue: 14,
          year: 2026,
        ),
      );

      final challengeDoc = await firestore
          .collection('gyms')
          .doc('gym-a')
          .collection('challenges')
          .doc('weekly')
          .collection('items')
          .doc(result.challengeId)
          .get();
      final data = challengeDoc.data()!;
      expect(data['goalType'], 'device_variety');
      expect(data['targetDistinctDevices'], 6);
      expect(data['targetReps'], 0);
      expect(data['targetVolume'], 0);
    });

    test('rejects invalid input before write', () async {
      await expectLater(
        () => service.createChallenge(
          const ChallengeAdminCreateInput(
            gymId: 'gym-a',
            actorUid: 'owner-1',
            title: 'Invalid',
            description: 'Invalid',
            goalType: AdminChallengeGoalType.deviceSets,
            deviceIds: <String>[],
            minSets: 0,
            xpReward: 0,
            period: AdminChallengePeriod.weekly,
            periodValue: 99,
            year: 2026,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );

      final weekly = await firestore
          .collection('gyms')
          .doc('gym-a')
          .collection('challenges')
          .doc('weekly')
          .collection('items')
          .get();
      expect(weekly.docs, isEmpty);

      final metric = observability.metrics.metricFor('owner.challenges.create');
      expect(metric.attempts, 0);
    });

    test('rejects workout frequency challenge with monthly period', () async {
      await expectLater(
        () => service.createChallenge(
          const ChallengeAdminCreateInput(
            gymId: 'gym-a',
            actorUid: 'owner-1',
            title: 'Invalid Workout',
            description: 'Should fail',
            goalType: AdminChallengeGoalType.workoutFrequency,
            targetWorkouts: 6,
            durationWeeks: 4,
            xpReward: 100,
            period: AdminChallengePeriod.monthly,
            periodValue: 2,
            year: 2026,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects device variety challenge with invalid target', () async {
      await expectLater(
        () => service.createChallenge(
          const ChallengeAdminCreateInput(
            gymId: 'gym-a',
            actorUid: 'owner-1',
            title: 'Invalid Variety',
            description: 'Should fail',
            goalType: AdminChallengeGoalType.deviceVariety,
            targetDistinctDevices: 1,
            xpReward: 100,
            period: AdminChallengePeriod.weekly,
            periodValue: 2,
            year: 2026,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
