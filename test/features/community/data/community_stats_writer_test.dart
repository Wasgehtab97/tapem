import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tapem/features/community/data/community_stats_writer.dart';

void main() {
  group('CommunityStatsWriter', () {
    late FakeFirebaseFirestore firestore;
    late CommunityStatsWriter writer;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      writer = CommunityStatsWriter(firestore: firestore);
    });

    test('aggregates sessions per user and day into a single feed document',
        () async {
      final firstSets = [
        {
          'reps': 10,
          'weight': 50,
          'isBodyweight': false,
          'exerciseId': 'ex1',
        },
        {
          'reps': 8,
          'weight': 55,
          'isBodyweight': false,
          'exerciseId': 'ex1',
        },
      ];
      await writer.recordSession(
        gymId: 'gym1',
        sessionId: 's1',
        userId: 'user1',
        username: ' Alice ',
        avatarUrl: ' https://example.com/avatar.png ',
        localTimestamp: DateTime(2024, 11, 1, 8, 15),
        sets: firstSets,
      );

      final firstDoc = await firestore
          .collection('gyms')
          .doc('gym1')
          .collection('feed_events')
          .doc('2024-11-01_user1')
          .get();
      expect(firstDoc.exists, isTrue);
      final firstData = firstDoc.data()!;
      final firstTimestamp = firstData['createdAt'] as Timestamp?;

      expect(firstData['type'], 'day_summary');
      expect(firstData['userId'], 'user1');
      expect(firstData['username'], 'Alice');
      expect(firstData['avatarUrl'], 'https://example.com/avatar.png');
      expect(firstData['reps'], 18);
      expect(firstData['volume'], closeTo(940, 0.001));
      expect(firstData['sessionCount'], 1);
      expect(firstData['exerciseCount'], 1);
      expect(firstData['setCount'], 2);
      expect(firstTimestamp, isNotNull);

      final secondSets = [
        {
          'reps': 12,
          'weight': 40,
          'isBodyweight': false,
          'exerciseId': 'ex2',
        },
        {
          'reps': 14,
          'isBodyweight': true,
        },
      ];

      await writer.recordSession(
        gymId: 'gym1',
        sessionId: 's2',
        userId: 'user1',
        username: 'Alice',
        avatarUrl: 'https://example.com/avatar.png',
        localTimestamp: DateTime(2024, 11, 1, 20, 45),
        sets: secondSets,
      );

      final aggregatedDoc = await firestore
          .collection('gyms')
          .doc('gym1')
          .collection('feed_events')
          .doc('2024-11-01_user1')
          .get();
      final aggregatedData = aggregatedDoc.data()!;
      final updatedTimestamp = aggregatedData['createdAt'] as Timestamp?;

      expect(aggregatedData['reps'], 44);
      expect(aggregatedData['volume'], closeTo(1420, 0.001));
      expect(aggregatedData['sessionCount'], 2);
      expect(aggregatedData['exerciseCount'], 2);
      expect(aggregatedData['setCount'], 4);
      expect(updatedTimestamp, isNotNull);
      expect(
        updatedTimestamp!.millisecondsSinceEpoch,
        greaterThanOrEqualTo(firstTimestamp!.millisecondsSinceEpoch),
      );
    });
  });
}
