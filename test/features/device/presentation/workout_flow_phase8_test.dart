import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/core/services/workout_session_coordinator.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/device/presentation/services/workout_entry_orchestrator.dart';
import 'package:tapem/features/device/presentation/workout_finish_flow.dart';
import 'package:tapem/features/device/presentation/workout_manual_stop_flow.dart';
import 'package:tapem/features/story_session/domain/models/story_daily_xp.dart';
import 'package:tapem/features/story_session/domain/models/story_session_summary.dart';
import 'package:tapem/features/story_session/presentation/widgets/story_session_dialog.dart';
import 'package:tapem/features/story_session/presentation/widgets/story_session_highlights_listener.dart';
import 'package:tapem/features/story_session/story_session_service.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';
import 'package:tapem/features/training_details/domain/repositories/session_repository.dart';
import 'package:tapem/features/training_details/domain/usecases/get_sessions_for_date.dart';
import 'package:tapem/l10n/app_localizations.dart';

class _MockAuthProvider extends Mock implements AuthProvider {}

class _MockSettingsProvider extends Mock implements SettingsProvider {}

class _MockWorkoutDayController extends Mock implements WorkoutDayController {}

class _MockWorkoutSessionDurationService extends Mock
    with ChangeNotifier
    implements WorkoutSessionDurationService {}

class _MockStorySessionService extends Mock implements StorySessionService {}

class _MockDeviceProvider extends Mock implements DeviceProvider {}

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
    isGymOwner: false,
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
    totalXp: 150,
    generatedAt: DateTime(2026, 2, 13, 20, 0),
    achievements: const [],
    stats: const StorySessionStats(
      exerciseCount: 1,
      setCount: 4,
      durationMs: 30 * 60 * 1000,
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
    end: DateTime(2026, 2, 13, 19, 30),
    durationMs: 30 * 60 * 1000,
    sessionId: 'session-1',
  );
}

WorkoutDaySession _session({
  required DeviceProvider provider,
  bool canSave = true,
}) {
  return WorkoutDaySession(
    key: 'session-key',
    gymId: 'gym-1',
    deviceId: 'device-1',
    exerciseId: 'exercise-1',
    exerciseName: 'Bench Press',
    userId: 'user-1',
    provider: provider,
    canSave: canSave,
    isSaving: false,
    isLoading: false,
    hasSessionToday: false,
    error: null,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(DateTime(2026, 2, 13));
    registerFallbackValue(_completionEvent());
  });

  late _MockAuthProvider auth;
  late _MockSettingsProvider settings;
  late _MockWorkoutDayController controller;
  late _MockWorkoutSessionDurationService durationService;
  late _MockStorySessionService storyService;
  late _MockDeviceProvider deviceProvider;
  late WorkoutSessionCoordinator coordinator;
  late StreamController<WorkoutSessionCompletionEvent> completionStream;

  late bool timerRunning;
  late DateTime? timerStartTime;
  late WorkoutSessionCompletionEvent completionEvent;
  late StorySessionSummary summary;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    auth = _MockAuthProvider();
    settings = _MockSettingsProvider();
    controller = _MockWorkoutDayController();
    durationService = _MockWorkoutSessionDurationService();
    storyService = _MockStorySessionService();
    deviceProvider = _MockDeviceProvider();
    completionStream =
        StreamController<WorkoutSessionCompletionEvent>.broadcast();

    timerRunning = false;
    timerStartTime = null;
    completionEvent = _completionEvent();
    summary = _summary();

    when(() => auth.userId).thenReturn('user-1');
    when(() => auth.gymCode).thenReturn('gym-1');
    when(() => auth.showInLeaderboard).thenReturn(true);
    when(() => auth.userName).thenReturn('Tester');

    when(
      () => controller.sessionsFor(userId: 'user-1', gymId: 'gym-1'),
    ).thenReturn(<WorkoutDaySession>[_session(provider: deviceProvider)]);
    when(
      () => controller.getPlanContext(
        gymId: any(named: 'gymId'),
        date: any(named: 'date'),
        dayKey: any(named: 'dayKey'),
      ),
    ).thenReturn(null);
    when(
      () => controller.addOrFocusSession(
        gymId: any(named: 'gymId'),
        deviceId: any(named: 'deviceId'),
        exerciseId: any(named: 'exerciseId'),
        exerciseName: any(named: 'exerciseName'),
        userId: any(named: 'userId'),
      ),
    ).thenReturn(_session(provider: deviceProvider));

    when(() => durationService.isRunning).thenAnswer((_) => timerRunning);
    when(() => durationService.startTime).thenAnswer((_) => timerStartTime);
    when(
      () => durationService.start(
        uid: any(named: 'uid'),
        gymId: any(named: 'gymId'),
      ),
    ).thenAnswer((_) async {
      timerRunning = true;
      timerStartTime ??= DateTime(2026, 2, 13, 18, 0);
    });
    when(
      () => durationService.registerSetCompletion(
        completedAt: any(named: 'completedAt'),
      ),
    ).thenAnswer((_) async {});
    when(() => durationService.discard()).thenAnswer((_) async {
      timerRunning = false;
      timerStartTime = null;
    });
    when(
      () => durationService.completionStream,
    ).thenAnswer((_) => completionStream.stream);
    when(
      () => durationService.getPendingCompletions(userId: any(named: 'userId')),
    ).thenAnswer((_) async => const <WorkoutSessionCompletionEvent>[]);
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

    coordinator = WorkoutSessionCoordinator(
      durationService: durationService,
      inactivityDelay: const Duration(minutes: 60),
    );
  });

  tearDown(() async {
    WorkoutManualStopFlow.debugSetSaveAndFinishInvoker(null);
    coordinator.dispose();
    await completionStream.close();
  });

  Future<GlobalKey<NavigatorState>> pumpHarness(WidgetTester tester) async {
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
    return navigatorKey;
  }

  Future<void> expectHighlightsDialog(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 1700));
    expect(find.byType(StorySessionDialog), findsOneWidget);
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.pop();
    await tester.pumpAndSettle();
    verify(() => durationService.acknowledgeCompletion(any())).called(1);
  }

  testWidgets('profile-play -> saetze -> training speichern -> highlights', (
    tester,
  ) async {
    await pumpHarness(tester);
    final context = tester.element(find.byType(Scaffold));
    var navigateToProfile = false;

    await coordinator.startFromProfilePlay(uid: 'user-1', gymId: 'gym-1');
    await coordinator.onSetCompleted(uid: 'user-1', gymId: 'gym-1');
    expect(coordinator.isRunning, isTrue);
    expect(timerRunning, isTrue);

    WorkoutManualStopFlow.debugSetSaveAndFinishInvoker(({
      required context,
      required navigatorKey,
      required controller,
      required auth,
      required settings,
      required sessions,
      required fallbackGymId,
      required navigateToHomeProfileOnSuccess,
      container,
      planId,
      planName,
      sessionAnchorDayKey,
      sessionAnchorStartTime,
    }) async {
      navigateToProfile = navigateToHomeProfileOnSuccess;
      completionStream.add(completionEvent);
      return const WorkoutFinishResult(
        status: WorkoutFinishStatus.completed,
        saveResult: SaveAllSessionsResult(
          attempted: 1,
          saved: 1,
          failedSessions: <String, String?>{},
          savedSessionKeys: <String>['session-key'],
        ),
      );
    });

    final status = await WorkoutManualStopFlow.saveFromWorkoutDay(
      context: context,
      auth: auth,
      controller: controller,
      settings: settings,
      sessionCoordinator: coordinator,
    );

    expect(status, WorkoutManualStopStatus.saved);
    expect(navigateToProfile, isTrue);
    expect(coordinator.isRunning, isFalse);
    await expectHighlightsDialog(tester);
  });

  testWidgets('profile-play -> profil-stop(save) -> highlights', (
    tester,
  ) async {
    await pumpHarness(tester);
    final context = tester.element(find.byType(Scaffold));
    var navigateToProfile = true;

    await coordinator.startFromProfilePlay(uid: 'user-1', gymId: 'gym-1');
    await coordinator.onSetCompleted(uid: 'user-1', gymId: 'gym-1');

    WorkoutManualStopFlow.debugSetSaveAndFinishInvoker(({
      required context,
      required navigatorKey,
      required controller,
      required auth,
      required settings,
      required sessions,
      required fallbackGymId,
      required navigateToHomeProfileOnSuccess,
      container,
      planId,
      planName,
      sessionAnchorDayKey,
      sessionAnchorStartTime,
    }) async {
      navigateToProfile = navigateToHomeProfileOnSuccess;
      completionStream.add(completionEvent);
      return const WorkoutFinishResult(
        status: WorkoutFinishStatus.completed,
        saveResult: SaveAllSessionsResult(
          attempted: 1,
          saved: 1,
          failedSessions: <String, String?>{},
          savedSessionKeys: <String>['session-key'],
        ),
      );
    });

    final statusFuture = WorkoutManualStopFlow.run(
      context: context,
      auth: auth,
      controller: controller,
      settings: settings,
      sessionCoordinator: coordinator,
      navigateToHomeProfileOnSuccess: false,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(await statusFuture, WorkoutManualStopStatus.saved);
    expect(navigateToProfile, isFalse);
    expect(coordinator.isRunning, isFalse);
    await expectHighlightsDialog(tester);
  });

  testWidgets('gym-start -> erster satz startet timer -> save -> highlights', (
    tester,
  ) async {
    await pumpHarness(tester);
    final context = tester.element(find.byType(Scaffold));
    final orchestrator = WorkoutEntryOrchestrator();

    final result = await orchestrator.addOrFocusFromExternalSource(
      controller: controller,
      coordinator: coordinator,
      gymId: 'gym-1',
      deviceId: 'device-gym',
      exerciseId: 'exercise-gym',
      exerciseName: 'Gym Exercise',
      userId: 'user-1',
    );

    expect(result.isDuplicate, isFalse);
    expect(coordinator.isRunning, isFalse);
    expect(timerRunning, isFalse);

    await coordinator.onFirstSetCompleted(uid: 'user-1', gymId: 'gym-1');
    expect(coordinator.isRunning, isTrue);
    expect(timerRunning, isTrue);

    WorkoutManualStopFlow.debugSetSaveAndFinishInvoker(({
      required context,
      required navigatorKey,
      required controller,
      required auth,
      required settings,
      required sessions,
      required fallbackGymId,
      required navigateToHomeProfileOnSuccess,
      container,
      planId,
      planName,
      sessionAnchorDayKey,
      sessionAnchorStartTime,
    }) async {
      completionStream.add(completionEvent);
      return const WorkoutFinishResult(
        status: WorkoutFinishStatus.completed,
        saveResult: SaveAllSessionsResult(
          attempted: 1,
          saved: 1,
          failedSessions: <String, String?>{},
          savedSessionKeys: <String>['session-key'],
        ),
      );
    });

    final status = await WorkoutManualStopFlow.saveFromWorkoutDay(
      context: context,
      auth: auth,
      controller: controller,
      settings: settings,
      sessionCoordinator: coordinator,
    );
    expect(status, WorkoutManualStopStatus.saved);
    expect(coordinator.isRunning, isFalse);
    await expectHighlightsDialog(tester);
  });

  testWidgets('nfc-start -> erster satz startet timer -> save -> highlights', (
    tester,
  ) async {
    await pumpHarness(tester);
    final context = tester.element(find.byType(Scaffold));
    final orchestrator = WorkoutEntryOrchestrator();

    final result = await orchestrator.addOrFocusFromExternalSource(
      controller: controller,
      coordinator: coordinator,
      gymId: 'gym-1',
      deviceId: 'device-nfc',
      exerciseId: 'device-nfc',
      exerciseName: 'NFC Exercise',
      userId: 'user-1',
    );

    expect(result.isDuplicate, isFalse);
    expect(coordinator.isRunning, isFalse);
    expect(timerRunning, isFalse);

    await coordinator.onFirstSetCompleted(uid: 'user-1', gymId: 'gym-1');
    expect(coordinator.isRunning, isTrue);
    expect(timerRunning, isTrue);

    WorkoutManualStopFlow.debugSetSaveAndFinishInvoker(({
      required context,
      required navigatorKey,
      required controller,
      required auth,
      required settings,
      required sessions,
      required fallbackGymId,
      required navigateToHomeProfileOnSuccess,
      container,
      planId,
      planName,
      sessionAnchorDayKey,
      sessionAnchorStartTime,
    }) async {
      completionStream.add(completionEvent);
      return const WorkoutFinishResult(
        status: WorkoutFinishStatus.completed,
        saveResult: SaveAllSessionsResult(
          attempted: 1,
          saved: 1,
          failedSessions: <String, String?>{},
          savedSessionKeys: <String>['session-key'],
        ),
      );
    });

    final status = await WorkoutManualStopFlow.saveFromWorkoutDay(
      context: context,
      auth: auth,
      controller: controller,
      settings: settings,
      sessionCoordinator: coordinator,
    );
    expect(status, WorkoutManualStopStatus.saved);
    expect(coordinator.isRunning, isFalse);
    await expectHighlightsDialog(tester);
  });

  testWidgets(
    'performance smoke: finalize + highlights flow settles within budget',
    (tester) async {
      await pumpHarness(tester);
      final context = tester.element(find.byType(Scaffold));

      await coordinator.startFromProfilePlay(uid: 'user-1', gymId: 'gym-1');
      await coordinator.onSetCompleted(uid: 'user-1', gymId: 'gym-1');

      WorkoutManualStopFlow.debugSetSaveAndFinishInvoker(({
        required context,
        required navigatorKey,
        required controller,
        required auth,
        required settings,
        required sessions,
        required fallbackGymId,
        required navigateToHomeProfileOnSuccess,
        container,
        planId,
        planName,
        sessionAnchorDayKey,
        sessionAnchorStartTime,
      }) async {
        completionStream.add(completionEvent);
        return const WorkoutFinishResult(
          status: WorkoutFinishStatus.completed,
          saveResult: SaveAllSessionsResult(
            attempted: 1,
            saved: 1,
            failedSessions: <String, String?>{},
            savedSessionKeys: <String>['session-key'],
          ),
        );
      });

      final stopwatch = Stopwatch()..start();
      final status = await WorkoutManualStopFlow.saveFromWorkoutDay(
        context: context,
        auth: auth,
        controller: controller,
        settings: settings,
        sessionCoordinator: coordinator,
      );
      expect(status, WorkoutManualStopStatus.saved);
      await expectHighlightsDialog(tester);
      stopwatch.stop();

      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 8)));
    },
  );
}
