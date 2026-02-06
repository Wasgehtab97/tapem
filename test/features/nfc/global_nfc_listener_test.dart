import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/usecases/get_device_by_nfc_code.dart';
import 'package:tapem/features/nfc/domain/usecases/read_nfc_code.dart';
import 'package:tapem/features/nfc/widgets/global_nfc_listener.dart';
import 'package:tapem/bootstrap/navigation.dart';
import 'package:tapem/features/device/providers/workout_day_controller_provider.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';
import 'package:tapem/features/nfc/providers/nfc_providers.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/device/providers/device_riverpod.dart';
import 'package:tapem/core/providers/auth_provider.dart' as auth;

class _MockNavigatorObserver extends Mock implements NavigatorObserver {}
class _MockReadNfcCode extends Mock implements ReadNfcCode {}
class _MockGetDeviceByNfcCode extends Mock implements GetDeviceByNfcCode {}
class _FakeRoute extends Fake implements Route<dynamic> {}
class _MockWorkoutDayController extends Mock with ChangeNotifier implements WorkoutDayController {}
class _MockWorkoutSessionDurationService extends Mock with ChangeNotifier implements WorkoutSessionDurationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_FakeRoute());
    const nfcManagerChannel = MethodChannel('plugins.flutter.io/nfc_manager');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      nfcManagerChannel,
      (MethodCall call) async => null,
    );
  });

  tearDownAll(() {
    const nfcManagerChannel = MethodChannel('plugins.flutter.io/nfc_manager');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(nfcManagerChannel, null);
  });

  group('GlobalNfcListener', () {
    late _MockReadNfcCode reader;
    late _MockGetDeviceByNfcCode getDevice;
    late _MockWorkoutDayController workoutController;
    late _MockWorkoutSessionDurationService timerService;
    late StreamController<String> controller;
    late String? currentGymCode;
    late String? currentUserId;
    late bool timerIsRunning;

    setUp(() {
      reader = _MockReadNfcCode();
      getDevice = _MockGetDeviceByNfcCode();
      workoutController = _MockWorkoutDayController();
      timerService = _MockWorkoutSessionDurationService();
      controller = StreamController<String>();
      currentGymCode = 'gym-1';
      currentUserId = 'user-1';
      timerIsRunning = false;

      when(() => reader.execute()).thenAnswer((_) => controller.stream);
      when(() => timerService.isRunning).thenAnswer((_) => timerIsRunning);
    });

    tearDown(() async {
      await controller.close();
    });

    Future<void> pumpListener(WidgetTester tester, NavigatorObserver observer) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            readNfcCodeProvider.overrideWithValue(reader),
            getDeviceByNfcCodeProvider.overrideWithValue(getDevice),
            workoutDayControllerProvider.overrideWith((ref) => workoutController),
            workoutSessionDurationServiceProvider.overrideWith((ref) => timerService),
            authControllerProvider.overrideWith((ref) {
              final mock = _MockActualAuthProvider();
              when(() => mock.gymCode).thenReturn(currentGymCode);
              when(() => mock.userId).thenReturn(currentUserId);
              return mock;
            }),
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            navigatorObservers: [observer],
            routes: {
              AppRouter.exerciseList: (_) => const SizedBox(key: Key('exerciseListPage')),
              AppRouter.workoutDay: (_) => const SizedBox(key: Key('workoutDayPage')),
              AppRouter.home: (context) {
                final args = ModalRoute.of(context)?.settings.arguments;
                return SizedBox(key: Key('homePage-$args'));
              },
            },
            home: GlobalNfcListener(child: Container()),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('ignores empty NFC payloads', (tester) async {
      final observer = _MockNavigatorObserver();
      await pumpListener(tester, observer);
      clearInteractions(observer);

      controller.add('');
      await tester.pump();

      verifyNever(() => observer.didPush(any(), any()));
      verifyNever(() => getDevice.execute(any<String>(), any<String>()));
    });

    testWidgets('navigates to exercise list when device is multi exercise', (tester) async {
      final observer = _MockNavigatorObserver();
      await pumpListener(tester, observer);

      when(() => getDevice.execute('gym-1', 'tag-1')).thenAnswer((_) async => Device(
            uid: 'dev-1',
            id: 1,
            name: 'Row',
            isMulti: true,
          ));

      controller.add('tag-1');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      verify(() => getDevice.execute('gym-1', 'tag-1')).called(1);
      expect(find.byKey(const Key('exerciseListPage')), findsOneWidget);
    });

    testWidgets('adds session and navigates to workout day for single exercise if timer not running', (tester) async {
      final observer = _MockNavigatorObserver();
      timerIsRunning = false;
      await pumpListener(tester, observer);

      when(() => getDevice.execute('gym-1', 'tag-2')).thenAnswer((_) async => Device(
            uid: 'dev-2',
            id: 2,
            name: 'Bench',
          ));
      
      when(() => workoutController.addOrFocusSession(
        gymId: any(named: 'gymId'),
        deviceId: any(named: 'deviceId'),
        exerciseId: any(named: 'exerciseId'),
        exerciseName: any(named: 'exerciseName'),
        userId: any(named: 'userId'),
      )).thenReturn(FakeWorkoutDaySession());

      controller.add('tag-2');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      verify(() => workoutController.addOrFocusSession(
        gymId: 'gym-1',
        deviceId: 'dev-2',
        exerciseId: 'dev-2',
        exerciseName: 'Bench',
        userId: 'user-1',
      )).called(1);
      expect(find.byKey(const Key('workoutDayPage')), findsOneWidget);
    });

    testWidgets('adds session and navigates to home tab 2 if timer is running', (tester) async {
      final observer = _MockNavigatorObserver();
      timerIsRunning = true;
      await pumpListener(tester, observer);

      when(() => getDevice.execute('gym-1', 'tag-2')).thenAnswer((_) async => Device(
            uid: 'dev-2',
            id: 2,
            name: 'Bench',
          ));
      
      when(() => workoutController.addOrFocusSession(
        gymId: any(named: 'gymId'),
        deviceId: any(named: 'deviceId'),
        exerciseId: any(named: 'exerciseId'),
        exerciseName: any(named: 'exerciseName'),
        userId: any(named: 'userId'),
      )).thenReturn(FakeWorkoutDaySession());

      controller.add('tag-2');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('homePage-2')), findsOneWidget);
    });

    testWidgets('does not query devices when no gym is selected', (tester) async {
      currentGymCode = null;
      final observer = _MockNavigatorObserver();
      await pumpListener(tester, observer);
      clearInteractions(observer);

      controller.add('tag-3');
      await tester.pump();

      verifyNever(() => getDevice.execute(any<String>(), any<String>()));
      verifyNever(() => observer.didPush(any(), any()));
    });
  });
}

class FakeWorkoutDaySession extends Fake implements WorkoutDaySession {}
class _MockActualAuthProvider extends Mock implements auth.AuthProvider {}
