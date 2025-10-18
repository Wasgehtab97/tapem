import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/time/logic_day.dart';
import 'package:tapem/features/story_session/domain/models/story_achievement.dart';
import 'package:tapem/features/story_session/story_session_service.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorySessionService', () {
    late FakeFirebaseFirestore firestore;
    late StorySessionService service;

    const gymId = 'gym-1';
    const userId = 'user-1';
    final date = DateTime(2025, 10, 18, 8, 0);
    final dayKey = logicDayKey(date);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      firestore = FakeFirebaseFirestore();
      service = StorySessionService(
        firestore: firestore,
        now: () => DateTime(2025, 10, 18, 12, 0),
      );
    });

    test('rebuilds highlights when remote summary lacks achievements', () async {
      final sessions = [
        Session(
          sessionId: 's1',
          deviceId: 'device-a',
          deviceName: 'Eleiko Rack',
          deviceDescription: 'Barbell station',
          isMulti: false,
          exerciseId: null,
          exerciseName: null,
          timestamp: DateTime(2025, 10, 18, 6, 0),
          note: '',
          sets: [
            SessionSet(weight: 60, reps: 5, setNumber: 1),
          ],
          startTime: DateTime(2025, 10, 18, 6, 0),
          endTime: DateTime(2025, 10, 18, 6, 30),
          durationMs: 30 * 60 * 1000,
        ),
        Session(
          sessionId: 's2',
          deviceId: 'device-b',
          deviceName: 'Precor Butterfly',
          deviceDescription: 'Chest machine',
          isMulti: false,
          exerciseId: null,
          exerciseName: null,
          timestamp: DateTime(2025, 10, 18, 7, 0),
          note: '',
          sets: [
            SessionSet(weight: 30, reps: 12, setNumber: 1),
          ],
          startTime: DateTime(2025, 10, 18, 7, 0),
          endTime: DateTime(2025, 10, 18, 7, 20),
          durationMs: 20 * 60 * 1000,
        ),
      ];

      await firestore
          .collection('gyms')
          .doc(gymId)
          .collection('users')
          .doc(userId)
          .collection('session_stories')
          .doc(dayKey)
          .set({
        'totalXp': 50,
        'generatedAt': Timestamp.fromDate(DateTime(2025, 10, 18, 11, 0)),
        'achievements': [],
        'stats': {
          'exerciseCount': 2,
          'setCount': 2,
          'durationMs': (30 + 20) * 60 * 1000,
        },
      });

      final summary = await service.getSummary(
        gymId: gymId,
        userId: userId,
        date: date,
        sessions: sessions,
      );

      expect(summary, isNotNull);
      final highlights = summary!.achievements
          .where((a) => a.type != StoryAchievementType.dailyXp)
          .toList();
      expect(highlights, hasLength(2));
      expect(highlights.every((a) => a.type == StoryAchievementType.newDevice), isTrue);

      final secondCall = await service.getSummary(
        gymId: gymId,
        userId: userId,
        date: date,
        sessions: sessions,
      );

      final secondHighlights = secondCall!.achievements
          .where((a) => a.type != StoryAchievementType.dailyXp)
          .toList();
      expect(secondHighlights, hasLength(2));
    });
  });
}
