import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/features/device/providers/exercise_provider.dart';
import 'package:tapem/core/providers/settings_provider.dart';

import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/device/providers/workout_day_controller_provider.dart';
import 'package:tapem/features/device/presentation/widgets/device_session_section.dart';
import 'package:tapem/features/device/presentation/widgets/session_rest_timer.dart';

import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';

class _MockDeviceProvider extends Mock
    with ChangeNotifier
    implements DeviceProvider {}

class _MockAuthProvider extends Mock
    with ChangeNotifier
    implements AuthProvider {}

class _MockSettingsProvider extends Mock
    with ChangeNotifier
    implements SettingsProvider {}

class _MockExerciseProvider extends Mock
    with ChangeNotifier
    implements ExerciseProvider {}

class _MockKeypadController extends Mock
    with ChangeNotifier
    implements OverlayNumericKeypadController {}

class _MockWorkoutDayController extends Mock
    with ChangeNotifier
    implements WorkoutDayController {}

class _FakeTextEditingController extends Fake
    implements TextEditingController {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_FakeTextEditingController());
  });

  Future<void> pumpMultipleSessions(
    WidgetTester tester, {
    required DeviceProvider firstProvider,
    required DeviceProvider secondProvider,
  }) async {
    final auth = _MockAuthProvider();
    final settings = _MockSettingsProvider();

    final exercises = _MockExerciseProvider();
    final keypad = _MockKeypadController();
    final workout = _MockWorkoutDayController();

    when(() => auth.userId).thenReturn('user-1');
    when(() => settings.load(any())).thenAnswer((_) async {});

    when(() => exercises.exercises).thenReturn(const []);
    when(
      () => keypad.openFor(
        any(),
        allowDecimal: any(named: 'allowDecimal'),
        decimalStep: any(named: 'decimalStep'),
        integerStep: any(named: 'integerStep'),
      ),
    ).thenAnswer((_) {});
    when(() => keypad.close()).thenAnswer((_) {});
    when(() => workout.focusSession(any())).thenReturn(true);

    DeviceProvider stubProvider(DeviceProvider provider) {
      when(
        () => provider.loadDevice(
          gymId: any(named: 'gymId'),
          deviceId: any(named: 'deviceId'),
          exerciseId: any(named: 'exerciseId'),
          userId: any(named: 'userId'),
          initialSetCountOverride: any(named: 'initialSetCountOverride'),
        ),
      ).thenAnswer((_) async {});
      when(() => provider.device).thenReturn(null);
      when(() => provider.isLoading).thenReturn(false);
      when(() => provider.error).thenReturn(null);
      when(() => provider.isBodyweightMode).thenReturn(false);
      when(() => provider.toggleBodyweightMode()).thenAnswer((_) {});
      when(() => provider.xp).thenReturn(0);
      when(() => provider.level).thenReturn(1);
      when(() => provider.note).thenReturn('');
      when(() => provider.setNote(any())).thenAnswer((_) {});
      when(() => provider.sessionSnapshots).thenReturn(const []);
      when(() => provider.lastSessionSets).thenReturn(const []);
      when(() => provider.lastSessionDate).thenReturn(null);
      when(() => provider.lastSessionNote).thenReturn('');
      when(() => provider.sets).thenReturn(const []);
      when(
        () => provider.getSetCounts(),
      ).thenReturn((done: 0, filledNotDone: 0, emptyOrIncomplete: 0));
      when(() => provider.hasSessionToday).thenReturn(false);
      when(() => provider.isSaving).thenReturn(false);
      when(() => provider.addSet()).thenAnswer((_) {});
      when(() => provider.removeSet(any())).thenAnswer((_) {});
      when(() => provider.insertSetAt(any(), any())).thenAnswer((_) {});
      return provider;
    }

    stubProvider(firstProvider);
    stubProvider(secondProvider);

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => auth),
          settingsProvider.overrideWith((ref) => settings),
          exerciseProvider.overrideWith((ref) => exercises),
          workoutDayControllerProvider.overrideWith((ref) => workout),
          overlayNumericKeypadControllerProvider.overrideWith((ref) => keypad),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              children: [
                DeviceSessionSection(
                  key: const ValueKey('session-1'),
                  provider: firstProvider,
                  gymId: 'gym',
                  deviceId: 'device-a',
                  exerciseId: 'exercise-a',
                  userId: 'user-1',
                  displayIndex: 1,
                  sessionKey: 'session-1',
                ),
                DeviceSessionSection(
                  key: const ValueKey('session-2'),
                  provider: secondProvider,
                  gymId: 'gym',
                  deviceId: 'device-b',
                  exerciseId: 'exercise-b',
                  userId: 'user-1',
                  displayIndex: 2,
                  sessionKey: 'session-2',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('device session section no longer renders rest timer', (
    tester,
  ) async {
    final firstProvider = _MockDeviceProvider();
    final secondProvider = _MockDeviceProvider();

    await pumpMultipleSessions(
      tester,
      firstProvider: firstProvider,
      secondProvider: secondProvider,
    );

    expect(find.byType(SessionRestTimer), findsNothing);
  });

  testWidgets('session rest timer starts and pauses countdown', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: SessionRestTimer(initialSeconds: 90)),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('01:30'), findsOneWidget);

    final state = tester.state<SessionRestTimerState>(
      find.byType(SessionRestTimer),
    );
    expect(state.service.isRunning, isFalse);
    expect(state.service.remaining.value.inSeconds, 90);

    state.service.start();
    await tester.pump();
    expect(state.service.isRunning, isTrue);
    await tester.pump(const Duration(seconds: 1));
    final runningSeconds = state.service.remaining.value.inSeconds;
    expect(runningSeconds, lessThan(90));

    state.service.stop();
    await tester.pump();
    expect(state.service.isRunning, isFalse);
    final pausedSeconds = state.service.remaining.value.inSeconds;
    await tester.pump(const Duration(seconds: 1));

    // Paused timer should not continue counting down.
    expect(state.service.remaining.value.inSeconds, pausedSeconds);

    final size = tester.getSize(find.byType(SessionRestTimer));
    expect(size.height, lessThanOrEqualTo(72));
  });

  testWidgets('session rest timer duration selector opens duration sheet', (
    tester,
  ) async {
    var interactionCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SessionRestTimer(
              initialSeconds: 90,
              onInteraction: () => interactionCount++,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    await tester.longPress(find.byType(SessionRestTimer));
    await tester.pumpAndSettle();

    expect(interactionCount, 1);
    expect(find.text('Pausenzeit wählen'), findsOneWidget);
    expect(find.text('60s'), findsOneWidget);
    expect(find.text('90s'), findsWidgets);
    expect(find.text('120s'), findsOneWidget);
    expect(find.text('150s'), findsOneWidget);
    expect(find.text('180s'), findsOneWidget);

    await tester.tap(find.text('120s'));
    await tester.pumpAndSettle();

    expect(interactionCount, 2);
    expect(find.text('02:00'), findsOneWidget);
  });
}
