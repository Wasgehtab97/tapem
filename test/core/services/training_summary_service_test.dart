import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/services/training_summary_service.dart';

void main() {
  group('TrainingSummaryService', () {
    test('reuses cached page within TTL window', () async {
      final firestore = FakeFirebaseFirestore();
      final userRef = firestore.collection('trainingSummary').doc('user');
      await userRef.collection('daily').doc('2024-04-10').set({
        'dateKey': '2024-04-10',
        'date': Timestamp.fromDate(DateTime(2024, 4, 10)),
        'logCount': 3,
        'totalSessions': 2,
        'sessionCounts': {
          'session-1': {'count': 2, 'gymId': 'gym-1', 'deviceId': 'device-1'},
          'session-2': {'count': 1, 'gymId': 'gym-1', 'deviceId': 'device-2'},
        },
        'deviceCounts': {
          'device-1': {'count': 3},
        },
        'favoriteExercises': [
          {'name': 'Bench Press', 'count': 3},
        ],
        'muscleGroups': [
          {'name': 'Chest', 'count': 3},
        ],
      });
      await userRef.collection('aggregate').doc('overview').set({
        'trainingDayCount': 1,
        'averageTrainingDaysPerWeek': 2.5,
        'favoriteExercises': [
          {'name': 'Bench Press', 'count': 5},
        ],
        'muscleGroups': [
          {'name': 'Chest', 'count': 5},
        ],
      });

      var readCount = 0;
      final service = TrainingSummaryService(
        firestore: firestore,
        ttl: const Duration(minutes: 10),
        onRead: () => readCount += 1,
      );

      final first = await service.loadSummaries(userId: 'user');
      expect(first.entries, hasLength(1));
      expect(first.aggregate.favoriteExercises, isNotEmpty);
      final sessionInfo = first.entries.first.sessionCounts['session-1'];
      expect(sessionInfo?.count, 2);
      expect(sessionInfo?.gymId, 'gym-1');
      expect(readCount, 2); // one for the page and one for the aggregate

      final second = await service.loadSummaries(userId: 'user');
      expect(second.fromCache, isTrue);
      expect(readCount, 2, reason: 'cached result should not trigger reads');
    });

    test('loadMore fetches additional page with cursor', () async {
      final firestore = FakeFirebaseFirestore();
      final userRef = firestore.collection('trainingSummary').doc('user');
      for (var i = 0; i < 3; i++) {
        final date = DateTime(2024, 4, 10 - i);
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        await userRef.collection('daily').doc(key).set({
          'dateKey': key,
          'date': Timestamp.fromDate(date),
          'logCount': 1,
          'totalSessions': 1,
          'sessionCounts': {
            'session-$i': {'count': 1, 'gymId': 'gym-$i', 'deviceId': 'device-$i'},
          },
          'deviceCounts': {
            'device-$i': {'count': 1},
          },
          'favoriteExercises': [
            {'name': 'Exercise $i', 'count': 1},
          ],
          'muscleGroups': [
            {'name': 'Group $i', 'count': 1},
          ],
        });
      }
      await userRef.collection('aggregate').doc('overview').set({
        'trainingDayCount': 3,
        'averageTrainingDaysPerWeek': 1.5,
        'favoriteExercises': [
          {'name': 'Exercise 0', 'count': 2},
        ],
        'muscleGroups': [
          {'name': 'Group 0', 'count': 2},
        ],
      });

      final service = TrainingSummaryService(
        firestore: firestore,
        ttl: const Duration(minutes: 10),
        pageSize: 2,
      );

      final first = await service.loadSummaries(userId: 'user');
      expect(first.entries, hasLength(2));
      expect(first.hasMore, isTrue);

      final second = await service.loadSummaries(
        userId: 'user',
        loadMore: true,
      );
      expect(second.entries, hasLength(3));
      expect(second.hasMore, isFalse);
      expect(second.aggregate.trainingDayCount, 3);
    });
  });
}
