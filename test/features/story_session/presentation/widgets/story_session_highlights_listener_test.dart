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
  _FakeGetSessionsForDate() : super(_MockSessionRepository());

  @override
  Future<List<Session>> execute({
    required String userId,
    required DateTime date,
    bool fromCacheOnly = false,
  }) async {
    return const <Session>[];
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
}
