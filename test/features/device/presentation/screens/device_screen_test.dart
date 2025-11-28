import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/features/device/providers/exercise_provider.dart';

import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import 'package:tapem/features/device/domain/usecases/get_device_by_nfc_code.dart';
import 'package:tapem/features/device/presentation/screens/device_screen.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';
import 'package:tapem/ui/timer/session_timer_service.dart';
import 'package:tapem/services/membership_service.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';

class _MockDeviceProvider extends Mock
    with ChangeNotifier
    implements DeviceProvider {}

class _MockAuthProvider extends Mock
    with ChangeNotifier
    implements AuthProvider {}



class _MockExerciseProvider extends Mock
    with ChangeNotifier
    implements ExerciseProvider {}

class _FakeKeypadController extends ChangeNotifier
    implements OverlayNumericKeypadController {
  TextEditingController? _target;
  bool _isOpen = false;
  double _contentHeight = 0.0;

  @override
  bool allowDecimal = true;

  @override
  double decimalStep = 2.5;

  @override
  double integerStep = 1.0;

  @override
  bool get isOpen => _isOpen;

  @override
  TextEditingController? get target => _target;

  @override
  double get keypadContentHeight => _isOpen ? _contentHeight : 0.0;

  @override
  void close() {
    if (!_isOpen) {
      return;
    }
    _isOpen = false;
    _contentHeight = 0.0;
    notifyListeners();
  }

  @override
  void openFor(
    TextEditingController controller, {
    bool allowDecimal = true,
    double? decimalStep,
    double? integerStep,
  }) {
    _target = controller;
    this.allowDecimal = allowDecimal;
    if (decimalStep != null) {
      this.decimalStep = decimalStep;
    }
    if (integerStep != null) {
      this.integerStep = integerStep;
    }
    if (_isOpen) {
      return;
    }
    _isOpen = true;
    notifyListeners();
  }
}

class _MockSessionTimerService extends Mock
    with ChangeNotifier
    implements SessionTimerService {}

class _MockWorkoutSessionDurationService extends Mock
    with ChangeNotifier
    implements WorkoutSessionDurationService {}

class _MockGetDeviceByNfcCode extends Mock implements GetDeviceByNfcCode {}

class _MockMembershipService extends Mock implements MembershipService {}

class _FakeDevice extends Fake implements Device {}

class _FakeExercise extends Fake implements Exercise {}

class _FakeTextEditingController extends Fake implements TextEditingController {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_FakeDevice());
    registerFallbackValue(_FakeExercise());
    registerFallbackValue(_FakeTextEditingController());
    registerFallbackValue(DeviceSetFieldFocus.weight);
    registerFallbackValue(Duration.zero);
  });

  late _MockDeviceProvider deviceProvider;
  late _MockAuthProvider authProvider;

  late _MockExerciseProvider exerciseProvider;
  late OverlayNumericKeypadController keypadController;
  late _MockGetDeviceByNfcCode getDeviceByNfcCode;
  late _MockMembershipService membershipService;
  late _MockSessionTimerService sessionTimerService;
  late _MockWorkoutSessionDurationService workoutSessionDurationService;
  late Device device;
  late List<Map<String, dynamic>> sets;

  setUp(() {
    deviceProvider = _MockDeviceProvider();
    authProvider = _MockAuthProvider();

    exerciseProvider = _MockExerciseProvider();
    keypadController = _FakeKeypadController();
    getDeviceByNfcCode = _MockGetDeviceByNfcCode();
    membershipService = _MockMembershipService();
    sessionTimerService = _MockSessionTimerService();
    workoutSessionDurationService = _MockWorkoutSessionDurationService();
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
    when(() => deviceProvider.hasMoreSnapshots).thenReturn(false);
    when(() => deviceProvider.lastSessionSets).thenReturn(const []);
    when(() => deviceProvider.lastSessionDate).thenReturn(null);
    when(() => deviceProvider.lastSessionNote).thenReturn('');
    when(() => deviceProvider.hasSessionToday).thenReturn(false);
    when(() => deviceProvider.isSaving).thenReturn(false);
    when(() => deviceProvider.getSetCounts())
        .thenReturn((done: 0, filledNotDone: 0, emptyOrIncomplete: sets.length));
    when(() => deviceProvider.completeAllFilledNotDone()).thenReturn(0);
    when(() => deviceProvider.completedCount).thenReturn(0);
    when(() => deviceProvider.prefetchSnapshots(
          gymId: any(named: 'gymId'),
          deviceId: any(named: 'deviceId'),
          userId: any(named: 'userId'),
          target: any(named: 'target'),
        )).thenAnswer((_) {});
    when(() => deviceProvider.loadMoreSnapshots(
          gymId: any(named: 'gymId'),
          deviceId: any(named: 'deviceId'),
          userId: any(named: 'userId'),
          pageSize: any(named: 'pageSize'),
        )).thenAnswer((_) async {});
    when(
      () => deviceProvider.saveWorkoutSession(
        gymId: any(named: 'gymId'),
        userId: any(named: 'userId'),
        showInLeaderboard: any(named: 'showInLeaderboard'),
        userName: any(named: 'userName'),
        gender: any(named: 'gender'),
        bodyWeightKg: any(named: 'bodyWeightKg'),
        autoFinalize: any(named: 'autoFinalize'),
      ),
    ).thenAnswer((_) async => true);
    when(() => deviceProvider.lastSessionId).thenReturn(null);
    when(() => deviceProvider.updateAutoSavePreference(any())).thenAnswer((_) {});
    when(() => deviceProvider.level).thenReturn(1);
    when(() => deviceProvider.xp).thenReturn(0);
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

    when(() => exerciseProvider.exercises).thenReturn([
          Exercise(id: 'ex', name: 'Exercise', userId: 'user'),
        ]);



    when(() => getDeviceByNfcCode.execute(any(), any()))
        .thenAnswer((_) async => null);
    when(() => membershipService.ensureMembership(any(), any()))
        .thenAnswer((_) async {});

    final remainingNotifier = ValueNotifier(Duration.zero);
    final runningNotifier = ValueNotifier(false);
    when(() => sessionTimerService.remaining).thenReturn(remainingNotifier);
    when(() => sessionTimerService.running).thenReturn(runningNotifier);
    when(() => sessionTimerService.total).thenReturn(const Duration(minutes: 2));
    when(() => sessionTimerService.selectedDuration)
        .thenReturn(const Duration(minutes: 2));
    when(() => sessionTimerService.addTickListener(any())).thenAnswer((_) {});
    when(() => sessionTimerService.removeTickListener(any())).thenAnswer((_) {});
    when(() => sessionTimerService.changeDuration(any())).thenAnswer((_) {});
    when(() => sessionTimerService.start()).thenAnswer((_) {});
    when(() => sessionTimerService.startWith(any())).thenAnswer((_) {});
    when(() => sessionTimerService.stop()).thenAnswer((_) {});

    when(() => workoutSessionDurationService.isRunning).thenReturn(false);
    when(() => workoutSessionDurationService.tickStream)
        .thenAnswer((_) => const Stream<Duration>.empty());
    when(() => workoutSessionDurationService.elapsed)
        .thenReturn(Duration.zero);
  });

  Widget buildTestApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DeviceProvider>.value(value: deviceProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),

        ChangeNotifierProvider<ExerciseProvider>.value(value: exerciseProvider),
        ChangeNotifierProvider<OverlayNumericKeypadController>.value(
          value: keypadController,
        ),
        ChangeNotifierProvider<SessionTimerService>.value(
          value: sessionTimerService,
        ),
        ChangeNotifierProvider<WorkoutSessionDurationService>.value(
          value: workoutSessionDurationService,
        ),
        Provider<GetDeviceByNfcCode>.value(value: getDeviceByNfcCode),
        Provider<MembershipService>.value(value: membershipService),
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
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final addFinder = find.text('Set hinzufügen');
    expect(addFinder, findsWidgets);
    await tester.tap(addFinder.first);
    await tester.pump();

    verify(() => deviceProvider.addSet()).called(1);
  });

  testWidgets('tapping remove set calls provider.removeSet', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final dismissibleFinder = find.byType(Dismissible).first;
    await tester.drag(dismissibleFinder, const Offset(-500, 0));
    await tester.pumpAndSettle();

    verify(() => deviceProvider.removeSet(0)).called(1);
  });
}
