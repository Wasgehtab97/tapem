import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
// ignore: implementation_imports
import 'package:hive/src/hive_impl.dart';
import 'package:tapem/core/services/training_summary_service.dart';

void main() {
  group('TrainingSummaryService caching & pagination', () {
    late FakeFirebaseFirestore firestore;
    late HiveInterface hive;
    late Directory tempDir;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      tempDir = await Directory.systemTemp.createTemp('training_summary_test');
      final hiveImpl = HiveImpl();
      hiveImpl.init(tempDir.path);
      hive = hiveImpl;
    });

    tearDown(() async {
      await hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('enforces Firestore read limits and uses Hive cache', () async {
      const userId = 'user-123';
      await _seedTrainingSummaries(firestore: firestore, userId: userId, count: 75);

      var readCount = 0;
      final coldService = TrainingSummaryService(
        firestore: firestore,
        ttl: Duration.zero,
        pageSize: 30,
        onRead: () => readCount++,
        hive: hive,
      );

      final initial = await coldService.loadSummaries(userId: userId);
      expect(initial.entries.length, equals(30));
      expect(initial.hasMore, isTrue);
      expect(initial.fromCache, isFalse);
      expect(readCount, equals(2), reason: 'daily + aggregate query');

      final warmService = TrainingSummaryService(
        firestore: firestore,
        ttl: const Duration(hours: 24),
        pageSize: 30,
        onRead: () => readCount++,
        hive: hive,
      );

      final cached = await warmService.loadSummaries(userId: userId);
      expect(cached.fromCache, isTrue);
      expect(cached.entries.length, equals(30));
      expect(cached.hasMore, isTrue);
      expect(readCount, equals(2), reason: 'no additional reads when cache valid');

      final nextPage = await warmService.loadSummaries(userId: userId, loadMore: true);
      expect(nextPage.fromCache, isFalse);
      expect(nextPage.entries.length, equals(60));
      expect(nextPage.hasMore, isTrue);
      expect(readCount, equals(3), reason: 'one extra daily read for loadMore');

      final finalPage = await warmService.loadSummaries(userId: userId, loadMore: true);
      expect(finalPage.entries.length, equals(75));
      expect(finalPage.hasMore, isFalse);
      expect(readCount, equals(4), reason: 'third daily page fetch');
    });
  });
}

Future<void> _seedTrainingSummaries({
  required FakeFirebaseFirestore firestore,
  required String userId,
  required int count,
}) async {
  final userRef = firestore.collection('trainingSummary').doc(userId);
  for (var i = 0; i < count; i++) {
    final date = DateTime(2024, 1, 1 + i);
    final dayKey = _formatDayKey(date);
    await userRef.collection('daily').doc(dayKey).set({
      'dateKey': dayKey,
      'date': Timestamp.fromDate(date),
      'logCount': i + 1,
      'totalSessions': i + 1,
      'favoriteExercises': const [],
      'muscleGroups': const [],
      'sessionCounts': {
        'session_$i': {
          'count': 1,
          'gymId': 'gym-a',
          'deviceId': 'device-a',
        },
      },
      'deviceCounts': {'device-a': i + 1},
    });
  }

  await userRef.collection('aggregate').doc('overview').set({
    'trainingDayCount': count,
    'averageTrainingDaysPerWeek': 4.2,
    'favoriteExercises': const [
      {'name': 'Squat', 'count': 10},
    ],
    'muscleGroups': const [
      {'name': 'Legs', 'count': 8},
    ],
    'totalSessions': count,
    'firstWorkoutDate': Timestamp.fromDate(DateTime(2024, 1, 1)),
    'lastWorkoutDate': Timestamp.fromDate(DateTime(2024, 1, 1 + count - 1)),
    'deviceCounts': const {'device-a': count},
  });
}

String _formatDayKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
