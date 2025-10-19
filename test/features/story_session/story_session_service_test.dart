import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/time/logic_day.dart';
import 'package:tapem/features/story_session/data/story_session_summary_store.dart';
import 'package:tapem/features/story_session/domain/models/story_achievement.dart';
import 'package:tapem/features/story_session/domain/models/story_session_summary.dart';
import 'package:tapem/features/story_session/story_session_service.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';

class _EphemeralSummaryStore extends StorySessionSummaryStore {
  const _EphemeralSummaryStore();

  @override
  Future<StorySessionSummary?> read(
    String gymId,
    String userId,
    String dayKey,
  ) async {
    return null;
  }

  @override
  Future<void> write(StorySessionSummary summary) async {}
}

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

    test('produces new-device and new-exercise badges for first-time usage', () async {
      final sessions = [
        Session(
          sessionId: 'deadlift-session',
          deviceId: 'device-deadlift',
          deviceName: 'Eleiko Deadlift Platform',
          deviceDescription: 'Deadlift area',
          isMulti: false,
          exerciseId: null,
          exerciseName: null,
          timestamp: DateTime(2025, 10, 18, 6, 0),
          note: '',
          sets: const [
            SessionSet(weight: 100, reps: 5, setNumber: 1),
          ],
        ),
        Session(
          sessionId: 'flys-session',
          deviceId: 'device-flys',
          deviceName: 'Precor Fly Machine',
          deviceDescription: 'Chest fly machine',
          isMulti: true,
          exerciseId: 'exercise-flys',
          exerciseName: 'Flys',
          timestamp: DateTime(2025, 10, 18, 7, 0),
          note: '',
          sets: const [
            SessionSet(weight: 40, reps: 12, setNumber: 1),
          ],
        ),
      ];

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
      expect(
        highlights.any((a) =>
            a.type == StoryAchievementType.newDevice &&
            a.deviceName == 'Eleiko Deadlift Platform'),
        isTrue,
      );
      expect(
        highlights.any((a) =>
            a.type == StoryAchievementType.newExercise &&
            a.deviceName == 'Precor Fly Machine' &&
            a.exerciseName == 'Flys'),
        isTrue,
      );
    });

    test('keeps same-day PR achievements after rebuilding summary twice', () async {
      service = StorySessionService(
        firestore: firestore,
        summaryStore: const _EphemeralSummaryStore(),
        now: () => DateTime(2025, 10, 18, 20, 0),
      );

      final sessions = [
        Session(
          sessionId: 'squat-session',
          deviceId: 'device-squat',
          deviceName: 'Eleiko Power Rack',
          deviceDescription: 'Main squat rack',
          isMulti: true,
          exerciseId: 'exercise-squat',
          exerciseName: 'Back Squat',
          timestamp: DateTime(2025, 10, 18, 6, 30),
          note: '',
          sets: const [
            SessionSet(weight: 140, reps: 3, setNumber: 1),
          ],
        ),
        Session(
          sessionId: 'bench-session',
          deviceId: 'device-bench',
          deviceName: 'Hammer Strength Bench',
          deviceDescription: 'Competition bench',
          isMulti: true,
          exerciseId: 'exercise-bench',
          exerciseName: 'Bench Press',
          timestamp: DateTime(2025, 10, 18, 7, 45),
          note: '',
          sets: const [
            SessionSet(weight: 90, reps: 5, setNumber: 1),
          ],
        ),
      ];

      final firstSummary = await service.getSummary(
        gymId: gymId,
        userId: userId,
        date: date,
        sessions: sessions,
      );

      expect(firstSummary, isNotNull);
      final firstPrs = firstSummary!.achievements
          .where((a) => a.type == StoryAchievementType.personalRecord)
          .toList();
      expect(firstPrs, hasLength(2));
      final firstIdentifiers = firstPrs
          .map((a) => '${a.deviceName}::${a.exerciseName}')
          .toSet();

      await firestore
          .collection('gyms')
          .doc(gymId)
          .collection('users')
          .doc(userId)
          .collection('session_stories')
          .doc(dayKey)
          .delete();

      final rebuiltSummary = await service.getSummary(
        gymId: gymId,
        userId: userId,
        date: date,
        sessions: sessions,
      );

      expect(rebuiltSummary, isNotNull);
      final rebuiltPrs = rebuiltSummary!.achievements
          .where((a) => a.type == StoryAchievementType.personalRecord)
          .toList();
      expect(rebuiltPrs, hasLength(2));
      final rebuiltIdentifiers = rebuiltPrs
          .map((a) => '${a.deviceName}::${a.exerciseName}')
          .toSet();

      expect(rebuiltIdentifiers, equals(firstIdentifiers));
    });
  });
}
