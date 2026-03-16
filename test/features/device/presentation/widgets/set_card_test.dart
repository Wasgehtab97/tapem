import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/device/presentation/widgets/set_card.dart';
import 'package:tapem/features/device/providers/workout_day_controller_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';

class _MockDeviceProvider extends Mock
    with ChangeNotifier
    implements DeviceProvider {}

class _MockKeypadController extends Mock
    with ChangeNotifier
    implements OverlayNumericKeypadController {}

class _MockWorkoutDayController extends Mock
    with ChangeNotifier
    implements WorkoutDayController {}

class _FakeTextEditingController extends Fake
    implements TextEditingController {}

WorkoutDaySession _sessionFor(DeviceProvider provider) {
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

  setUpAll(() {
    registerFallbackValue(_FakeTextEditingController());
    registerFallbackValue(DeviceSetFieldFocus.weight);
  });

  late _MockDeviceProvider provider;
  late _MockKeypadController keypad;
  late _MockWorkoutDayController workoutController;
  late Map<String, dynamic> setData;

  setUp(() {
    provider = _MockDeviceProvider();
    keypad = _MockKeypadController();
    workoutController = _MockWorkoutDayController();
    setData = {
      'number': '1',
      'weight': '10',
      'reps': '8',
      'done': false,
      'drops': const [],
    };

    when(() => provider.isBodyweightMode).thenReturn(false);
    when(() => provider.focusedField).thenReturn(null);
    when(() => provider.focusedIndex).thenReturn(null);
    when(() => provider.focusedDropIndex).thenReturn(null);
    when(() => provider.focusRequestId).thenReturn(0);
    when(
      () => provider.requestFocus(
        index: any(named: 'index'),
        field: any(named: 'field'),
        dropIndex: any(named: 'dropIndex'),
      ),
    ).thenReturn(0);
    when(() => provider.ensureDropSlot(any())).thenReturn(0);
    when(() => provider.addDropToSet(any())).thenReturn(0);
    when(
      () => provider.updateDrop(
        any(),
        any(),
        weight: any(named: 'weight'),
        reps: any(named: 'reps'),
      ),
    ).thenAnswer((_) {});
    when(
      () => provider.updateSet(
        any(),
        weight: any(named: 'weight'),
        reps: any(named: 'reps'),
        dropWeight: any(named: 'dropWeight'),
        dropReps: any(named: 'dropReps'),
        isBodyweight: any(named: 'isBodyweight'),
      ),
    ).thenAnswer((_) {});
    when(() => provider.toggleSetDone(any())).thenReturn(true);
    when(() => provider.clearFocus()).thenReturn(0);
    when(() => workoutController.focusSession(any())).thenReturn(true);
    when(
      () => workoutController.sessionForKey(any()),
    ).thenReturn(_sessionFor(provider));
    when(
      () => keypad.openFor(any(), allowDecimal: any(named: 'allowDecimal')),
    ).thenAnswer((_) {});
    when(() => keypad.close()).thenAnswer((_) {});
  });

  Widget buildTestApp() {
    return riverpod.ProviderScope(
      overrides: [
        workoutDayControllerProvider.overrideWith((ref) => workoutController),
        overlayNumericKeypadControllerProvider.overrideWith((ref) => keypad),
      ],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SetCard(index: 0, set: setData, sessionKey: 'session-key'),
        ),
      ),
    );
  }

  testWidgets('tapping weight field focuses session before requesting focus', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final state = tester.state<SetCardState>(find.byType(SetCard));
    state.focusWeight();
    await tester.pump();

    verify(() => workoutController.focusSession('session-key')).called(1);
    verify(
      () => provider.requestFocus(
        index: 0,
        field: DeviceSetFieldFocus.weight,
        dropIndex: any(named: 'dropIndex'),
      ),
    ).called(1);
    verify(
      () => keypad.openFor(any(), allowDecimal: true),
    ).called(greaterThanOrEqualTo(1));
  });

  testWidgets('expanding extras focuses session before ensuring drop slot', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pump();

    verify(() => workoutController.focusSession('session-key')).called(1);
    verify(() => provider.ensureDropSlot(0)).called(1);
  });

  testWidgets('adding drop focuses session before provider mutation', (
    tester,
  ) async {
    setData['drops'] = [
      {'weight': '', 'reps': ''},
    ];

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pump();

    verify(() => provider.addDropToSet(0)).called(1);
    verify(
      () => provider.requestFocus(
        index: 0,
        field: DeviceSetFieldFocus.dropWeight,
        dropIndex: 0,
      ),
    ).called(1);
  });

  testWidgets('shows bodyweight icon inside weight field when mode is active', (
    tester,
  ) async {
    setData['weight'] = '';
    setData['isBodyweight'] = true;

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.accessibility_new_rounded), findsOneWidget);
  });
}
