import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/core/services/workout_session_coordinator.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/device/presentation/workout_finish_flow.dart';
import 'package:tapem/features/story_session/presentation/widgets/training_done_overlay.dart';
import 'package:tapem/l10n/app_localizations.dart';

class _MockAuthProvider extends Mock implements AuthProvider {}

class _MockSettingsProvider extends Mock implements SettingsProvider {}

class _MockWorkoutDayController extends Mock implements WorkoutDayController {}

class _MockDeviceProvider extends Mock implements DeviceProvider {}

WorkoutDaySession _session(DeviceProvider provider) {
  return WorkoutDaySession(
    key: 'session-key',
    gymId: 'gym-1',
    deviceId: 'device-1',
    exerciseId: 'exercise-1',
    exerciseName: 'Bench Press',
    userId: 'user-1',
    provider: provider,
    canSave: true,
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
  late _MockDeviceProvider deviceProvider;
  late GlobalKey<NavigatorState> navigatorKey;

  setUp(() {
    auth = _MockAuthProvider();
    settings = _MockSettingsProvider();
    controller = _MockWorkoutDayController();
    deviceProvider = _MockDeviceProvider();
    navigatorKey = GlobalKey<NavigatorState>();

    when(() => auth.userId).thenReturn('user-1');
    when(() => auth.gymCode).thenReturn('gym-1');
    when(() => auth.showInLeaderboard).thenReturn(true);
    when(() => auth.userName).thenReturn('Tester');

    when(
      () => deviceProvider.getSetCounts(),
    ).thenReturn((done: 1, filledNotDone: 0, emptyOrIncomplete: 0));
    when(() => settings.load('user-1')).thenAnswer((_) async {});
    when(
      () => controller.endDay(
        userId: any(named: 'userId'),
        gymId: any(named: 'gymId'),
        showInLeaderboard: any(named: 'showInLeaderboard'),
        userName: any(named: 'userName'),
        gender: any(named: 'gender'),
        bodyWeightKg: any(named: 'bodyWeightKg'),
        plannedRestSecondsBySession: any(named: 'plannedRestSecondsBySession'),
        finalizeReason: WorkoutFinalizeReason.manualSave,
        finalizeEndTime: any(named: 'finalizeEndTime'),
        sessionAnchorStartTime: any(named: 'sessionAnchorStartTime'),
        sessionAnchorDayKey: any(named: 'sessionAnchorDayKey'),
      ),
    ).thenAnswer(
      (_) async => const SaveAllSessionsResult(
        attempted: 1,
        saved: 1,
        failedSessions: <String, String?>{},
        savedSessionKeys: <String>['session-key'],
      ),
    );
  });

  tearDown(() {
    TrainingDoneOverlay.clear();
  });

  testWidgets(
    'save+navigate shows result snackbar safely after route replacement',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {
            '/': (_) => const Scaffold(body: Text('root')),
            AppRouter.home: (_) => const Scaffold(body: Text('home')),
          },
        ),
      );

      final context = tester.element(find.text('root'));
      final resultFuture = WorkoutFinishFlow.saveAndFinish(
        context: context,
        navigatorKey: navigatorKey,
        controller: controller,
        auth: auth,
        settings: settings,
        sessions: <WorkoutDaySession>[_session(deviceProvider)],
        fallbackGymId: 'gym-1',
        navigateToHomeProfileOnSuccess: true,
      );

      await tester.pump();
      expect(find.text('Trainingstag abschließen?'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final result = await resultFuture.timeout(const Duration(seconds: 1));
      await tester.pump();

      expect(result.status, WorkoutFinishStatus.completed);
      expect(find.text('home'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
