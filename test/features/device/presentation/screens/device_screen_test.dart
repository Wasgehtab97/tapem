import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/providers/exercise_provider.dart';
import 'package:tapem/core/providers/training_plan_provider.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import 'package:tapem/features/device/presentation/screens/device_screen.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';

class _MockDeviceProvider extends Mock
    with ChangeNotifier
    implements DeviceProvider {}

class _MockAuthProvider extends Mock
    with ChangeNotifier
    implements AuthProvider {}

class _MockTrainingPlanProvider extends Mock
    with ChangeNotifier
    implements TrainingPlanProvider {}

class _MockExerciseProvider extends Mock
    with ChangeNotifier
    implements ExerciseProvider {}

class _MockKeypadController extends Mock
    with ChangeNotifier
    implements OverlayNumericKeypadController {}

class _FakeDevice extends Fake implements Device {}

class _FakeExercise extends Fake implements Exercise {}

class _FakeTextEditingController extends Fake implements TextEditingController {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_FakeDevice());
    registerFallbackValue(_FakeExercise());
    registerFallbackValue(_FakeTextEditingController());
  });

  late _MockDeviceProvider deviceProvider;
  late _MockAuthProvider authProvider;
  late _MockTrainingPlanProvider trainingPlanProvider;
  late _MockExerciseProvider exerciseProvider;
  late _MockKeypadController keypadController;
  late Device device;
  late List<Map<String, dynamic>> sets;

  setUp(() {
    deviceProvider = _MockDeviceProvider();
    authProvider = _MockAuthProvider();
    trainingPlanProvider = _MockTrainingPlanProvider();
    exerciseProvider = _MockExerciseProvider();
    keypadController = _MockKeypadController();
    device = Device(uid: 'd1', id: 1, name: 'Test Device');
    sets = [
      {
        'number': '1',
        'weight': '10',
        'reps': '8',
        'done': false,
        'isBodyweight': false,
        'drops': const [],
      },
    ];

    when(() => deviceProvider.isLoading).thenReturn(false);
    when(() => deviceProvider.error).thenReturn(null);
    when(() => deviceProvider.device).thenReturn(device);
    when(() => deviceProvider.sets).thenAnswer((_) => sets);
    when(() => deviceProvider.sessionSnapshots).thenReturn(const []);
    when(() => deviceProvider.lastSessionSets).thenReturn(const []);
    when(() => deviceProvider.lastSessionDate).thenReturn(null);
    when(() => deviceProvider.lastSessionNote).thenReturn('');
    when(() => deviceProvider.hasSessionToday).thenReturn(false);
    when(() => deviceProvider.isSaving).thenReturn(false);
    when(() => deviceProvider.getSetCounts())
        .thenReturn((done: 0, filledNotDone: 0, emptyOrIncomplete: sets.length));
    when(() => deviceProvider.completeAllFilledNotDone()).thenReturn(0);
    when(() => deviceProvider.completedCount).thenReturn(0);
    when(
      () => deviceProvider.saveWorkoutSession(
        gymId: any(named: 'gymId'),
        userId: any(named: 'userId'),
        showInLeaderboard: any(named: 'showInLeaderboard'),
        autoFinalize: any(named: 'autoFinalize'),
      ),
    ).thenAnswer((_) async => true);
    when(() => deviceProvider.lastSessionId).thenReturn(null);
    when(() => deviceProvider.updateAutoSavePreference(any())).thenAnswer((_) {});
    when(() => deviceProvider.level).thenReturn(1);
    when(() => deviceProvider.isBodyweightMode).thenReturn(false);
    when(() => deviceProvider.focusedField).thenReturn(null);
    when(() => deviceProvider.focusedIndex).thenReturn(null);
    when(() => deviceProvider.focusedDropIndex).thenReturn(null);
    when(() => deviceProvider.focusRequestId).thenReturn(0);
    when(
      () => deviceProvider.requestFocus(
        index: any(named: 'index'),
        field: any(named: 'field'),
        dropIndex: any(named: 'dropIndex'),
      ),
    ).thenReturn(0);
    when(() => deviceProvider.ensureDropSlot(any())).thenReturn(0);
    when(() => deviceProvider.addDropToSet(any())).thenReturn(0);
    when(() => deviceProvider.updateDrop(any(), any(), weight: any(named: 'weight'), reps: any(named: 'reps')))
        .thenAnswer((_) {});
    when(
      () => deviceProvider.updateSet(
        any(),
        weight: any(named: 'weight'),
        reps: any(named: 'reps'),
        dropWeight: any(named: 'dropWeight'),
        dropReps: any(named: 'dropReps'),
        isBodyweight: any(named: 'isBodyweight'),
      ),
    ).thenAnswer((_) {});
    when(() => deviceProvider.note).thenReturn('');
    when(() => deviceProvider.setNote(any())).thenAnswer((_) {});
    when(() => deviceProvider.addSet()).thenAnswer((_) {});
    when(() => deviceProvider.removeSet(any())).thenAnswer((invocation) {
      final index = invocation.positionalArguments.first as int;
      if (index >= 0 && index < sets.length) {
        sets.removeAt(index);
      }
    });
    when(() => deviceProvider.insertSetAt(any(), any())).thenAnswer((_) {});
    when(
      () => deviceProvider.loadDevice(
        gymId: any(named: 'gymId'),
        deviceId: any(named: 'deviceId'),
        exerciseId: any(named: 'exerciseId'),
        userId: any(named: 'userId'),
        forceRefresh: any(named: 'forceRefresh'),
      ),
    ).thenAnswer((_) async {});

    when(() => authProvider.userId).thenReturn('user');
    when(() => authProvider.showInLeaderboard).thenReturn(true);

    when(() => exerciseProvider.exercises).thenReturn(const [
          Exercise(id: 'ex', name: 'Exercise', userId: 'user'),
        ]);

    when(() => trainingPlanProvider.plans).thenReturn(const []);
    when(() => trainingPlanProvider.isLoading).thenReturn(false);
    when(() => trainingPlanProvider.activePlanId).thenReturn(null);
    when(() => trainingPlanProvider.loadPlans(any(), any()))
        .thenAnswer((_) async {});
    when(() => trainingPlanProvider.setActivePlan(any()))
        .thenAnswer((_) async {});

    when(() => keypadController.openFor(
          any(),
          allowDecimal: any(named: 'allowDecimal'),
          decimalStep: any(named: 'decimalStep'),
          integerStep: any(named: 'integerStep'),
        )).thenAnswer((_) {});
    when(() => keypadController.close()).thenAnswer((_) {});
  });

  Widget _buildTestApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DeviceProvider>.value(value: deviceProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<TrainingPlanProvider>.value(
          value: trainingPlanProvider,
        ),
        ChangeNotifierProvider<ExerciseProvider>.value(value: exerciseProvider),
        ChangeNotifierProvider<OverlayNumericKeypadController>.value(
          value: keypadController,
        ),
      ],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DeviceScreen(
          gymId: 'gym',
          deviceId: 'd1',
          exerciseId: 'ex',
        ),
      ),
    );
  }

  testWidgets('tapping add set calls provider.addSet', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    final addFinder = find.text('Set hinzufügen');
    expect(addFinder, findsWidgets);
    await tester.tap(addFinder.first);
    await tester.pump();

    verify(() => deviceProvider.addSet()).called(1);
  });

  testWidgets('tapping remove set calls provider.removeSet', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    final dismissibleFinder = find.byType(Dismissible).first;
    await tester.drag(dismissibleFinder, const Offset(-500, 0));
    await tester.pumpAndSettle();

    verify(() => deviceProvider.removeSet(0)).called(1);
  });
}
