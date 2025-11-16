import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart' as auth;
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/usecases/get_device_by_nfc_code.dart';
import 'package:tapem/features/nfc/domain/usecases/read_nfc_code.dart';
import 'package:tapem/features/nfc/widgets/global_nfc_listener.dart';
import 'package:tapem/main.dart';

class _MockNavigatorObserver extends Mock implements NavigatorObserver {}

class _MockReadNfcCode extends Mock implements ReadNfcCode {}

class _MockGetDeviceByNfcCode extends Mock implements GetDeviceByNfcCode {}

class _FakeRoute extends Fake implements Route<dynamic> {}

class _FakeAuthProvider extends ChangeNotifier implements auth.AuthProvider {
  String? _gymCode;

  void setGymCode(String? code) {
    _gymCode = code;
    notifyListeners();
  }

  @override
  bool get isLoading => false;

  @override
  bool get isLoggedIn => _gymCode != null;

  @override
  String? get userEmail => null;

  @override
  String? get userName => null;

  @override
  String get avatarKey => 'default';

  @override
  List<String>? get gymCodes =>
      _gymCode == null ? null : <String>[_gymCode!];

  @override
  String? get gymCode => _gymCode;

  @override
  String? get userId => null;

  @override
  String? get role => null;

  @override
  bool get isAdmin => false;

  @override
  DateTime? get createdAt => null;

  @override
  bool? get showInLeaderboard => null;

  @override
  bool? get publicProfile => null;

  @override
  String? get error => null;

  @override
  Future<void> login(String email, String password) async {}

  @override
  Future<void> register(String email, String password, String initialGymCode) async {}

  @override
  Future<void> logout() async {
    _gymCode = null;
  }

  @override
  Future<bool> setUsername(String username) async => true;

  @override
  Future<bool> checkUsernameAvailable(String username) async => true;

  @override
  Future<void> setShowInLeaderboard(bool value) async {}

  @override
  Future<void> setPublicProfile(bool value) async {}

  @override
  Future<void> setAvatarKey(String key) async {}

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<void> switchGym(String code) async {
    _gymCode = code;
  }

  @override
  Future<void> selectGym(String code) => switchGym(code);
}

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
    late _FakeAuthProvider authProvider;
    late StreamController<String> controller;

    setUp(() {
      reader = _MockReadNfcCode();
      getDevice = _MockGetDeviceByNfcCode();
      authProvider = _FakeAuthProvider()..setGymCode('gym-1');
      controller = StreamController<String>();
      when(() => reader.execute()).thenAnswer((_) => controller.stream);
    });

    tearDown(() async {
      await controller.close();
    });

    Future<void> pumpListener(WidgetTester tester, NavigatorObserver observer) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ReadNfcCode>.value(value: reader),
            Provider<GetDeviceByNfcCode>.value(value: getDevice),
            ChangeNotifierProvider<auth.AuthProvider>.value(value: authProvider),
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            navigatorObservers: [observer],
            routes: {
              AppRouter.exerciseList: (_) => const SizedBox(key: Key('exerciseListPage')),
              AppRouter.device: (_) => const SizedBox(key: Key('devicePage')),
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
      clearInteractions(observer);

      when(() => getDevice.execute('gym-1', 'tag-1')).thenAnswer((_) async => Device(
            uid: 'dev-1',
            id: 1,
            name: 'Row',
            isMulti: true,
          ));

      controller.add('tag-1');
      await tester.pump();
      await tester.pumpAndSettle();

      verify(() => getDevice.execute('gym-1', 'tag-1')).called(1);
      expect(find.byKey(const Key('exerciseListPage')), findsOneWidget);
    });

    testWidgets('navigates directly to device screen for single exercise devices', (tester) async {
      final observer = _MockNavigatorObserver();
      await pumpListener(tester, observer);
      clearInteractions(observer);

      when(() => getDevice.execute('gym-1', 'tag-2')).thenAnswer((_) async => Device(
            uid: 'dev-2',
            id: 2,
            name: 'Bench',
          ));

      controller.add('tag-2');
      await tester.pump();
      await tester.pumpAndSettle();

      verify(() => getDevice.execute('gym-1', 'tag-2')).called(1);
      expect(find.byKey(const Key('devicePage')), findsOneWidget);
    });

    testWidgets('does not query devices when no gym is selected', (tester) async {
      authProvider.setGymCode(null);
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
