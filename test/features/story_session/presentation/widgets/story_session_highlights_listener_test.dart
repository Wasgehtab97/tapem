import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/services/workout_session_coordinator.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';
import 'package:tapem/features/story_session/domain/models/story_daily_xp.dart';
import 'package:tapem/features/story_session/domain/models/story_session_summary.dart';
import 'package:tapem/features/story_session/presentation/widgets/story_session_dialog.dart';
import 'package:tapem/features/story_session/presentation/widgets/story_session_highlights_listener.dart';
import 'package:tapem/features/story_session/story_session_service.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';
import 'package:tapem/features/training_details/domain/repositories/session_repository.dart';
import 'package:tapem/features/training_details/domain/usecases/get_sessions_for_date.dart';
import 'package:tapem/l10n/app_localizations.dart';

class _MockWorkoutSessionDurationService extends Mock
    with ChangeNotifier
    implements WorkoutSessionDurationService {}

class _MockWorkoutSessionCoordinator extends Mock
    with ChangeNotifier
    implements WorkoutSessionCoordinator {}

class _MockStorySessionService extends Mock implements StorySessionService {}

class _MockSessionRepository extends Mock implements SessionRepository {}

class _FakeGetSessionsForDate extends GetSessionsForDate {
  _FakeGetSessionsForDate({
    Future<List<Session>> Function({
      required String userId,
      required DateTime date,
      required bool fromCacheOnly,
    })?
    loader,
  }) : _loader = loader,
       super(_MockSessionRepository());

  final Future<List<Session>> Function({
    required String userId,
    required DateTime date,
    required bool fromCacheOnly,
  })?
  _loader;

  @override
  Future<List<Session>> execute({
    required String userId,
    required DateTime date,
    bool fromCacheOnly = false,
  }) async {
    final loader = _loader;
    if (loader != null) {
      return loader(userId: userId, date: date, fromCacheOnly: fromCacheOnly);
    }
    return <Session>[_session()];
  }
}

AuthViewState _authState() {
  return const AuthViewState(
    isLoading: false,
    isLoggedIn: true,
    isGuest: false,
    isAdmin: false,
    isCoach: false,
    gymContextStatus: GymContextStatus.ready,
    gymCode: 'gym-1',
    userId: 'user-1',
    error: null,
  );
}

StorySessionSummary _summary() {
  return StorySessionSummary(
    gymId: 'gym-1',
    userId: 'user-1',
    dayKey: '2026-02-13',
    totalXp: 120,
    generatedAt: DateTime(2026, 2, 13, 20, 0),
    achievements: const [],
    stats: const StorySessionStats(
      exerciseCount: 2,
      setCount: 8,
      durationMs: 45 * 60 * 1000,
    ),
    dailyXp: const StoryDailyXp.empty(),
  );
}

Session _session() {
  return Session(
    sessionId: 'session-1',
    gymId: 'gym-1',
    userId: 'user-1',
    deviceId: 'device-1',
    deviceName: 'Device 1',
    exerciseId: 'exercise-1',
    exerciseName: 'Exercise 1',
    timestamp: DateTime(2026, 2, 13, 19, 0),
    note: '',
    sets: <SessionSet>[SessionSet(weight: 60, reps: 8, setNumber: 1)],
    startTime: DateTime(2026, 2, 13, 19, 0),
    endTime: DateTime(2026, 2, 13, 19, 45),
    durationMs: 45 * 60 * 1000,
  );
}

WorkoutSessionCompletionEvent _completionEvent() {
  return WorkoutSessionCompletionEvent(
    gymId: 'gym-1',
    userId: 'user-1',
    dayKey: '2026-02-13',
    start: DateTime(2026, 2, 13, 19, 0),
    end: DateTime(2026, 2, 13, 19, 45),
    durationMs: 45 * 60 * 1000,
    sessionId: 'session-1',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(DateTime(2026, 2, 13));
    registerFallbackValue(_completionEvent());
  });

  testWidgets(
    'acknowledges pending completion only after highlights dialog closes',
    (tester) async {
      final durationService = _MockWorkoutSessionDurationService();
      final coordinator = _MockWorkoutSessionCoordinator();
      final storyService = _MockStorySessionService();
      final streamCtrl =
          StreamController<WorkoutSessionCompletionEvent>.broadcast();
      addTearDown(streamCtrl.close);

      final event = _completionEvent();
      final summary = _summary();

      when(
        () => durationService.completionStream,
      ).thenAnswer((_) => streamCtrl.stream);
      when(
        () =>
            durationService.getPendingCompletions(userId: any(named: 'userId')),
      ).thenAnswer((_) async => <WorkoutSessionCompletionEvent>[event]);
      when(
        () => durationService.acknowledgeCompletion(any()),
      ).thenAnswer((_) async {});
      when(
        () => storyService.getSummary(
          gymId: any(named: 'gymId'),
          userId: any(named: 'userId'),
          date: any(named: 'date'),
          sessions: any(named: 'sessions'),
          fallbackDurationMs: any(named: 'fallbackDurationMs'),
        ),
      ).thenAnswer((_) async => summary);

      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewStateProvider.overrideWith((ref) => _authState()),
            workoutSessionDurationServiceProvider.overrideWith(
              (ref) => durationService,
            ),
            workoutSessionCoordinatorProvider.overrideWith(
              (ref) => coordinator,
            ),
            storySessionServiceProvider.overrideWithValue(storyService),
            storyHighlightsGetSessionsForDateProvider.overrideWith(
              (ref) => _FakeGetSessionsForDate(),
            ),
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: StorySessionHighlightsListener(
              navigatorKey: navigatorKey,
              child: const Scaffold(body: SizedBox.shrink()),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1700));

      expect(find.byType(StorySessionDialog), findsOneWidget);
      verifyNever(() => durationService.acknowledgeCompletion(any()));

      navigatorKey.currentState?.pop();
      await tester.pumpAndSettle();

      final captured = verify(
        () => durationService.acknowledgeCompletion(captureAny()),
      ).captured;
      expect(captured, hasLength(1));
      expect(
        (captured.first as WorkoutSessionCompletionEvent).sessionId,
        event.sessionId,
      );
    },
  );

  testWidgets('deduplicates replay + stream event for same completion', (
    tester,
  ) async {
    final durationService = _MockWorkoutSessionDurationService();
    final coordinator = _MockWorkoutSessionCoordinator();
    final storyService = _MockStorySessionService();
    final streamCtrl =
        StreamController<WorkoutSessionCompletionEvent>.broadcast();
    addTearDown(streamCtrl.close);

    final event = _completionEvent();
    final summary = _summary();
    var summaryCalls = 0;

    when(
      () => durationService.completionStream,
    ).thenAnswer((_) => streamCtrl.stream);
    when(
      () => durationService.getPendingCompletions(userId: any(named: 'userId')),
    ).thenAnswer((_) async => <WorkoutSessionCompletionEvent>[event]);
    when(
      () => durationService.acknowledgeCompletion(any()),
    ).thenAnswer((_) async {});
    when(
      () => storyService.getSummary(
        gymId: any(named: 'gymId'),
        userId: any(named: 'userId'),
        date: any(named: 'date'),
        sessions: any(named: 'sessions'),
        fallbackDurationMs: any(named: 'fallbackDurationMs'),
      ),
    ).thenAnswer((_) async {
      summaryCalls += 1;
      return summary;
    });

    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewStateProvider.overrideWith((ref) => _authState()),
          workoutSessionDurationServiceProvider.overrideWith(
            (ref) => durationService,
          ),
          workoutSessionCoordinatorProvider.overrideWith((ref) => coordinator),
          storySessionServiceProvider.overrideWithValue(storyService),
          storyHighlightsGetSessionsForDateProvider.overrideWith(
            (ref) => _FakeGetSessionsForDate(),
          ),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StorySessionHighlightsListener(
            navigatorKey: navigatorKey,
            child: const Scaffold(body: SizedBox.shrink()),
          ),
        ),
      ),
    );

    await tester.pump();
    streamCtrl.add(event);
    await tester.pump(const Duration(milliseconds: 1700));

    expect(find.byType(StorySessionDialog), findsOneWidget);
    navigatorKey.currentState?.pop();
    await tester.pumpAndSettle();

    expect(summaryCalls, 1);
    verify(() => durationService.acknowledgeCompletion(any())).called(1);
  });

  testWidgets(
    'retries pending completion after transient summary build failure',
    (tester) async {
      final durationService = _MockWorkoutSessionDurationService();
      final coordinator = _MockWorkoutSessionCoordinator();
      final storyService = _MockStorySessionService();
      final streamCtrl =
          StreamController<WorkoutSessionCompletionEvent>.broadcast();
      addTearDown(streamCtrl.close);

      final event = _completionEvent();
      final summary = _summary();
      var pendingCalls = 0;
      var summaryCalls = 0;

      when(
        () => durationService.completionStream,
      ).thenAnswer((_) => streamCtrl.stream);
      when(
        () =>
            durationService.getPendingCompletions(userId: any(named: 'userId')),
      ).thenAnswer((_) async {
        pendingCalls += 1;
        // Initial replay on listener bind: no pending events yet.
        if (pendingCalls == 1) {
          return const <WorkoutSessionCompletionEvent>[];
        }
        return <WorkoutSessionCompletionEvent>[event];
      });
      when(
        () => durationService.acknowledgeCompletion(any()),
      ).thenAnswer((_) async {});
      when(
        () => storyService.getSummary(
          gymId: any(named: 'gymId'),
          userId: any(named: 'userId'),
          date: any(named: 'date'),
          sessions: any(named: 'sessions'),
          fallbackDurationMs: any(named: 'fallbackDurationMs'),
        ),
      ).thenAnswer((_) async {
        summaryCalls += 1;
        if (summaryCalls == 1) {
          throw Exception('temporary summary failure');
        }
        return summary;
      });

      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewStateProvider.overrideWith((ref) => _authState()),
            workoutSessionDurationServiceProvider.overrideWith(
              (ref) => durationService,
            ),
            workoutSessionCoordinatorProvider.overrideWith(
              (ref) => coordinator,
            ),
            storySessionServiceProvider.overrideWithValue(storyService),
            storyHighlightsGetSessionsForDateProvider.overrideWith(
              (ref) => _FakeGetSessionsForDate(),
            ),
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: StorySessionHighlightsListener(
              navigatorKey: navigatorKey,
              child: const Scaffold(body: SizedBox.shrink()),
            ),
          ),
        ),
      );

      await tester.pump();
      streamCtrl.add(event);

      // First attempt fails, no dialog yet.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(StorySessionDialog), findsNothing);

      // Retry should replay pending and eventually show the dialog.
      await tester.pump(const Duration(milliseconds: 2400));
      expect(find.byType(StorySessionDialog), findsOneWidget);

      navigatorKey.currentState?.pop();
      await tester.pumpAndSettle();

      expect(summaryCalls, greaterThanOrEqualTo(2));
      verify(() => durationService.acknowledgeCompletion(any())).called(1);
    },
  );

  testWidgets(
    'defers empty-session popup and replays once sessions become available',
    (tester) async {
      final durationService = _MockWorkoutSessionDurationService();
      final coordinator = _MockWorkoutSessionCoordinator();
      final storyService = _MockStorySessionService();
      final streamCtrl =
          StreamController<WorkoutSessionCompletionEvent>.broadcast();
      addTearDown(streamCtrl.close);

      final event = _completionEvent();
      final summary = _summary();
      var pendingCalls = 0;
      var sessionReads = 0;
      var summaryCalls = 0;

      when(
        () => durationService.completionStream,
      ).thenAnswer((_) => streamCtrl.stream);
      when(
        () =>
            durationService.getPendingCompletions(userId: any(named: 'userId')),
      ).thenAnswer((_) async {
        pendingCalls += 1;
        if (pendingCalls == 1) {
          return const <WorkoutSessionCompletionEvent>[];
        }
        return <WorkoutSessionCompletionEvent>[event];
      });
      when(
        () => durationService.acknowledgeCompletion(any()),
      ).thenAnswer((_) async {});
      when(
        () => storyService.getSummary(
          gymId: any(named: 'gymId'),
          userId: any(named: 'userId'),
          date: any(named: 'date'),
          sessions: any(named: 'sessions'),
          fallbackDurationMs: any(named: 'fallbackDurationMs'),
        ),
      ).thenAnswer((_) async {
        summaryCalls += 1;
        return summary;
      });

      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewStateProvider.overrideWith((ref) => _authState()),
            workoutSessionDurationServiceProvider.overrideWith(
              (ref) => durationService,
            ),
            workoutSessionCoordinatorProvider.overrideWith(
              (ref) => coordinator,
            ),
            storySessionServiceProvider.overrideWithValue(storyService),
            storyHighlightsGetSessionsForDateProvider.overrideWith((ref) {
              return _FakeGetSessionsForDate(
                loader:
                    ({
                      required String userId,
                      required DateTime date,
                      required bool fromCacheOnly,
                    }) async {
                      sessionReads += 1;
                      if (sessionReads <= 3) {
                        return const <Session>[];
                      }
                      return <Session>[_session()];
                    },
              );
            }),
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: StorySessionHighlightsListener(
              navigatorKey: navigatorKey,
              child: const Scaffold(body: SizedBox.shrink()),
            ),
          ),
        ),
      );

      await tester.pump();
      streamCtrl.add(event);

      // First run sees empty cache and must not display a 0/0/0 summary.
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.byType(StorySessionDialog), findsNothing);
      expect(summaryCalls, 0);
      verifyNever(() => durationService.acknowledgeCompletion(any()));

      // Replay after retry delay should load sessions and show dialog.
      await tester.pump(const Duration(milliseconds: 2400));
      expect(find.byType(StorySessionDialog), findsOneWidget);
      expect(summaryCalls, 1);

      navigatorKey.currentState?.pop();
      await tester.pumpAndSettle();

      verify(() => durationService.acknowledgeCompletion(any())).called(1);
    },
  );
}
