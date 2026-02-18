import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/core/services/workout_session_coordinator.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/device/presentation/workout_finish_flow.dart';
import 'package:tapem/features/device/presentation/workout_manual_stop_flow.dart';
import 'package:tapem/l10n/app_localizations.dart';

class _MockAuthProvider extends Mock implements AuthProvider {}

class _MockSettingsProvider extends Mock implements SettingsProvider {}

class _MockWorkoutDayController extends Mock implements WorkoutDayController {}

class _MockWorkoutSessionCoordinator extends Mock
    implements WorkoutSessionCoordinator {}

class _MockDeviceProvider extends Mock implements DeviceProvider {}

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

  late _MockAuthProvider auth;
  late _MockSettingsProvider settings;
  late _MockWorkoutDayController controller;
  late _MockWorkoutSessionCoordinator coordinator;
  late _MockDeviceProvider deviceProvider;
  late GlobalKey<NavigatorState> testNavigatorKey;
  late DateTime anchorStartAt;

  setUp(() {
    auth = _MockAuthProvider();
    settings = _MockSettingsProvider();
    controller = _MockWorkoutDayController();
    coordinator = _MockWorkoutSessionCoordinator();
    deviceProvider = _MockDeviceProvider();
    testNavigatorKey = GlobalKey<NavigatorState>();
    anchorStartAt = DateTime(2026, 2, 13, 18, 00);

    when(() => auth.userId).thenReturn('user-1');
    when(() => auth.gymCode).thenReturn('gym-1');
    when(() => coordinator.anchorDayKey).thenReturn('2026-02-13');
    when(() => coordinator.anchorStartAt).thenReturn(anchorStartAt);
    when(() => coordinator.isRunning).thenReturn(false);
    when(
      () => coordinator.setActiveContext(uid: 'user-1', gymId: 'gym-1'),
    ).thenAnswer((_) async {});
    when(
      () => coordinator.finishManuallyFromWorkoutSave(),
    ).thenAnswer((_) async {});
  });

  tearDown(() {
    WorkoutManualStopFlow.debugSetSaveAndFinishInvoker(null);
  });

  Future<void> pumpHarness(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: testNavigatorKey,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('profile stop discard finalizes and cancels active plan', (
    tester,
  ) async {
    await pumpHarness(tester);
    final context = tester.element(find.byType(Scaffold));

    when(
      () => controller.sessionsFor(userId: 'user-1', gymId: 'gym-1'),
    ).thenReturn(<WorkoutDaySession>[_session(provider: deviceProvider)]);
    when(
      () => coordinator.finishManuallyFromProfileStop(),
    ).thenAnswer((_) async {});
    when(
      () => controller.cancelActivePlan(
        userId: 'user-1',
        gymId: 'gym-1',
        date: anchorStartAt,
        dayKey: '2026-02-13',
      ),
    ).thenReturn(null);

    final statusFuture = WorkoutManualStopFlow.run(
      context: context,
      auth: auth,
      controller: controller,
      settings: settings,
      sessionCoordinator: coordinator,
      navigateToHomeProfileOnSuccess: false,
      customNavigatorKey: testNavigatorKey,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Verwerfen'));
    await tester.pumpAndSettle();

    expect(await statusFuture, WorkoutManualStopStatus.discarded);
    verify(() => coordinator.finishManuallyFromProfileStop()).called(1);
    verify(
      () => controller.cancelActivePlan(
        userId: 'user-1',
        gymId: 'gym-1',
        date: anchorStartAt,
        dayKey: '2026-02-13',
      ),
    ).called(1);
  });

  testWidgets('profile stop save uses shared save/finalize path', (
    tester,
  ) async {
    await pumpHarness(tester);
    final context = tester.element(find.byType(Scaffold));
    final sessions = <WorkoutDaySession>[_session(provider: deviceProvider)];

    when(
      () => controller.sessionsFor(userId: 'user-1', gymId: 'gym-1'),
    ).thenReturn(sessions);
    when(
      () => controller.getPlanContext(
        gymId: 'gym-1',
        date: anchorStartAt,
        dayKey: '2026-02-13',
      ),
    ).thenReturn(('plan-1', 'Upper Body'));

    var invokerCalls = 0;
    bool? navigateToProfile;
    String? capturedPlanId;
    String? capturedAnchorDayKey;
    DateTime? capturedAnchorStartTime;
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
      invokerCalls += 1;
      navigateToProfile = navigateToHomeProfileOnSuccess;
      capturedPlanId = planId;
      capturedAnchorDayKey = sessionAnchorDayKey;
      capturedAnchorStartTime = sessionAnchorStartTime;
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
      customNavigatorKey: testNavigatorKey,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(await statusFuture, WorkoutManualStopStatus.saved);
    expect(invokerCalls, 1);
    expect(navigateToProfile, isFalse);
    expect(capturedPlanId, 'plan-1');
    expect(capturedAnchorDayKey, '2026-02-13');
    expect(capturedAnchorStartTime, anchorStartAt);
  });

  testWidgets('workout-day save path reuses shared save/finalize invoker', (
    tester,
  ) async {
    await pumpHarness(tester);
    final context = tester.element(find.byType(Scaffold));

    when(
      () => controller.sessionsFor(userId: 'user-1', gymId: 'gym-1'),
    ).thenReturn(<WorkoutDaySession>[_session(provider: deviceProvider)]);
    when(
      () => controller.getPlanContext(
        gymId: 'gym-1',
        date: anchorStartAt,
        dayKey: '2026-02-13',
      ),
    ).thenReturn(null);

    var invokerCalls = 0;
    bool? navigateToProfile;
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
      invokerCalls += 1;
      navigateToProfile = navigateToHomeProfileOnSuccess;
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
      customNavigatorKey: testNavigatorKey,
    );

    expect(status, WorkoutManualStopStatus.saved);
    expect(invokerCalls, 1);
    expect(navigateToProfile, isTrue);
  });

  testWidgets('save path forces coordinator to idle when still running', (
    tester,
  ) async {
    await pumpHarness(tester);
    final context = tester.element(find.byType(Scaffold));

    when(() => coordinator.isRunning).thenReturn(true);
    when(
      () => controller.sessionsFor(userId: 'user-1', gymId: 'gym-1'),
    ).thenReturn(<WorkoutDaySession>[_session(provider: deviceProvider)]);
    when(
      () => controller.getPlanContext(
        gymId: 'gym-1',
        date: anchorStartAt,
        dayKey: '2026-02-13',
      ),
    ).thenReturn(null);

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
      customNavigatorKey: testNavigatorKey,
    );

    expect(status, WorkoutManualStopStatus.saved);
    verify(() => coordinator.finishManuallyFromWorkoutSave()).called(1);
  });

  testWidgets(
    'save path skips fallback finalize when coordinator already finalized',
    (tester) async {
      await pumpHarness(tester);
      final context = tester.element(find.byType(Scaffold));

      when(() => coordinator.isRunning).thenReturn(false);
      when(
        () => coordinator.finalizeReason,
      ).thenReturn(WorkoutFinalizeReason.manualSave.name);
      when(
        () => controller.sessionsFor(userId: 'user-1', gymId: 'gym-1'),
      ).thenReturn(<WorkoutDaySession>[_session(provider: deviceProvider)]);
      when(
        () => controller.getPlanContext(
          gymId: 'gym-1',
          date: anchorStartAt,
          dayKey: '2026-02-13',
        ),
      ).thenReturn(null);

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
        customNavigatorKey: testNavigatorKey,
      );

      expect(status, WorkoutManualStopStatus.saved);
      verifyNever(() => coordinator.finishManuallyFromWorkoutSave());
    },
  );

  testWidgets(
    'save path uses live coordinator from container for fallback finalization',
    (tester) async {
      await pumpHarness(tester);
      final context = tester.element(find.byType(Scaffold));
      final liveCoordinator = _MockWorkoutSessionCoordinator();

      when(
        () => liveCoordinator.setActiveContext(uid: 'user-1', gymId: 'gym-1'),
      ).thenAnswer((_) async {});
      when(
        () => liveCoordinator.finishManuallyFromWorkoutSave(),
      ).thenAnswer((_) async {});
      when(() => liveCoordinator.anchorDayKey).thenReturn('2026-02-13');
      when(() => liveCoordinator.anchorStartAt).thenReturn(anchorStartAt);

      when(() => coordinator.isRunning).thenReturn(true);
      when(
        () => coordinator.finishManuallyFromWorkoutSave(),
      ).thenThrow(StateError('disposed'));
      when(
        () => controller.sessionsFor(userId: 'user-1', gymId: 'gym-1'),
      ).thenReturn(<WorkoutDaySession>[_session(provider: deviceProvider)]);
      when(
        () => controller.getPlanContext(
          gymId: 'gym-1',
          date: anchorStartAt,
          dayKey: '2026-02-13',
        ),
      ).thenReturn(null);

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

      final container = ProviderContainer(
        overrides: [
          workoutSessionCoordinatorProvider.overrideWith(
            (ref) => liveCoordinator,
          ),
        ],
      );
      addTearDown(container.dispose);

      final status = await WorkoutManualStopFlow.saveFromWorkoutDay(
        context: context,
        auth: auth,
        controller: controller,
        settings: settings,
        sessionCoordinator: coordinator,
        customNavigatorKey: testNavigatorKey,
        container: container,
      );

      expect(status, WorkoutManualStopStatus.saved);
      verify(
        () => liveCoordinator.setActiveContext(uid: 'user-1', gymId: 'gym-1'),
      ).called(1);
      verify(() => liveCoordinator.finishManuallyFromWorkoutSave()).called(1);
    },
  );
}
