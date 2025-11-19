import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tapem/app_router.dart';
import 'package:tapem/bootstrap/legacy_provider_scope.dart';
import 'package:tapem/bootstrap/providers.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/branding_provider.dart';
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/features/report/domain/models/device_usage_stat.dart';
import 'package:tapem/features/report/domain/repositories/report_repository.dart';
import 'package:tapem/features/report/domain/usecases/get_all_log_timestamps.dart';
import 'package:tapem/features/report/domain/usecases/get_device_usage_stats.dart';
import 'package:tapem/features/splash/presentation/screens/splash_screen.dart';
import 'package:tapem/services/membership_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('legacy bootstrap wires provider and riverpod state for splash flow',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fakeAuth = _FakeAuthProvider();
    final fakeBranding = _FakeBrandingProvider();
    final fakeGym = _FakeGymProvider();

    // Dieser Aufbau dokumentiert, wie zukünftige Provider den Bridge-Flow
    // erweitern: Alle Riverpod-Abhängigkeiten (SharedPreferences etc.) werden
    // weiterhin über ProviderScope.overrides konfiguriert. Legacy-spezifische
    // Provider wie Auth-, Branding- oder GymProvider werden ausschließlich über
    // LegacyProviderScopeOverrides injiziert, damit der reale
    // Composition-Root (_LegacyRiverpodBridge) im Test aktiv bleibt.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          membershipServiceProvider.overrideWithValue(_FakeMembershipService()),
          getDeviceUsageStatsProvider.overrideWithValue(_FakeGetDeviceUsageStats()),
          getAllLogTimestampsProvider.overrideWithValue(_FakeGetAllLogTimestamps()),
        ],
        child: LegacyProviderScope(
          overrides: LegacyProviderScopeOverrides(
            authProvider: fakeAuth,
            brandingProvider: fakeBranding,
            gymProvider: fakeGym,
          ),
          child: MaterialApp(
            initialRoute: AppRouter.splash,
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case AppRouter.splash:
                  return MaterialPageRoute(builder: (_) => const SplashScreen());
                case AppRouter.home:
                  return MaterialPageRoute(builder: (_) => const _TestHomeScreen());
                default:
                  return MaterialPageRoute(
                    builder: (_) => const Scaffold(body: SizedBox.shrink()),
                  );
              }
            },
          ),
        ),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);

    final splashContext = tester.element(find.byType(SplashScreen));
    final splashContainer = ProviderScope.containerOf(splashContext);
    expect(splashContainer.read(authViewStateProvider).isLoading, isTrue);

    fakeAuth.completeUserLoad(userId: 'uid-1', gymCode: 'gym-a');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 801));
    await tester.pumpAndSettle();

    expect(find.byType(_TestHomeScreen), findsOneWidget);

    final homeContext = tester.element(find.byType(_TestHomeScreen));
    final homeContainer = ProviderScope.containerOf(homeContext);
    expect(homeContainer.read(authViewStateProvider).gymCode, 'gym-a');

    final switchResult = await fakeAuth.switchGym('gym-b');
    expect(switchResult.success, isTrue);
    await tester.pump();

    expect(homeContainer.read(authViewStateProvider).gymCode, 'gym-b');
  });
}

class _FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _isAdmin = false;
  GymContextStatus _status = GymContextStatus.loading;
  String? _gymCode;
  String? _userId;
  String? _error;

  void completeUserLoad({required String userId, required String gymCode}) {
    _isLoading = false;
    _isLoggedIn = true;
    _userId = userId;
    _gymCode = gymCode;
    _status = GymContextStatus.ready;
    _error = null;
    notifyListeners();
  }

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isLoggedIn => _isLoggedIn;

  @override
  bool get isAdmin => _isAdmin;

  @override
  String? get error => _error;

  @override
  GymContextStatus get gymContextStatus => _status;

  @override
  String? get gymCode => _gymCode;

  @override
  String? get userId => _userId;

  @override
  Future<void> reloadCurrentUser() async {}

  @override
  Future<GymSwitchResult> switchGym(String gymId) async {
    _gymCode = gymId;
    notifyListeners();
    return const GymSwitchResult.success();
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeBrandingProvider extends ChangeNotifier implements BrandingProvider {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGymProvider extends ChangeNotifier implements GymProvider {
  final List<String> switchedGymCodes = [];

  @override
  void dispose() {
    super.dispose();
  }

  @override
  noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #resetGymScopedState) {
      return null;
    }
    if (invocation.memberName == #lastRequestedGymId) {
      return switchedGymCodes.isEmpty ? null : switchedGymCodes.last;
    }
    if (invocation.memberName == #loadGymData && invocation.positionalArguments.isNotEmpty) {
      final gymId = invocation.positionalArguments.first as String;
      switchedGymCodes.add(gymId);
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class _FakeMembershipService implements MembershipService {
  @override
  Future<void> ensureMembership(String gymId, String uid) async {}
}

class _FakeGetDeviceUsageStats extends GetDeviceUsageStats {
  _FakeGetDeviceUsageStats() : super(_FakeReportRepository());

  @override
  Future<List<DeviceUsageStat>> execute(String gymId, {DateTime? since}) async =>
      const [];
}

class _FakeGetAllLogTimestamps extends GetAllLogTimestamps {
  _FakeGetAllLogTimestamps() : super(_FakeReportRepository());

  @override
  Future<List<DateTime>> execute(String gymId, {DateTime? since}) async => const [];
}

class _FakeReportRepository implements ReportRepository {
  @override
  Future<List<DateTime>> fetchAllLogTimestamps(String gymId, {DateTime? since}) async =>
      const [];

  @override
  Future<List<DeviceUsageStat>> fetchDeviceUsageStats(String gymId, {DateTime? since}) async =>
      const [];
}

class _TestHomeScreen extends StatelessWidget {
  const _TestHomeScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Home')),
    );
  }
}
