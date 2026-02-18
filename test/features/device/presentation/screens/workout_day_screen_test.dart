import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/bootstrap/navigation.dart';
import 'package:tapem/core/drafts/session_draft.dart';
import 'package:tapem/core/drafts/session_draft_repository.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/services/workout_session_coordinator.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';

import 'package:tapem/features/training_details/domain/repositories/session_repository.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';
import 'package:tapem/features/device/domain/usecases/get_device_by_nfc_code.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/device/presentation/screens/workout_day_screen.dart';
import 'package:tapem/features/device/presentation/widgets/session_rest_timer.dart';
import 'package:tapem/features/device/providers/device_riverpod.dart';
import 'package:tapem/features/device/providers/workout_day_controller_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';

import 'package:tapem/services/membership_service.dart';
import 'package:tapem/ui/timer/active_workout_timer.dart';

import '../../../../features/auth/helpers/fake_firestore.dart';

class _MockAuthProvider extends Mock
    with ChangeNotifier
    implements AuthProvider {}

class _MockMembershipService extends Mock implements MembershipService {}

class _MockDeviceRepository extends Mock implements DeviceRepository {}

class _FakeSessionDraftRepository implements SessionDraftRepository {
  final Map<String, SessionDraft> _drafts = {};

  @override
  Future<void> delete(String key) async {
    _drafts.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _drafts.clear();
  }

  @override
  Future<void> deleteExpired(int nowMs) async {
    _drafts.removeWhere((_, draft) => draft.updatedAt + draft.ttlMs < nowMs);
  }

  @override
  Future<SessionDraft?> get(String key) async {
    return _drafts[key];
  }

  @override
  Future<Map<String, SessionDraft>> getAll() async {
    return Map<String, SessionDraft>.from(_drafts);
  }

  @override
  Future<void> put(String key, SessionDraft draft) async {
    _drafts[key] = draft;
  }
}

class _MockSessionRepository extends Mock implements SessionRepository {}

AuthViewState _testAuthViewState() {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(DateTime(2023));
    registerFallbackValue(
      Session(
        sessionId: 'dummy',
        gymId: 'gym',
        userId: 'user',
        deviceId: 'device',
        deviceName: 'Device',
        note: 'Note',
        timestamp: DateTime.now(),
        sets: [],
      ),
    );
  });

  late WorkoutDayController controller;
  late _MockAuthProvider authProvider;
  late WorkoutSessionDurationService durationService;
  late WorkoutSessionCoordinator sessionCoordinator;
  late FakeFirebaseFirestore firestore;

  late _MockMembershipService membership;
  late _MockDeviceRepository deviceRepository;
  late _MockSessionRepository sessionRepository;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    firestore = FakeFirebaseFirestore();
    membership = _MockMembershipService();
    deviceRepository = _MockDeviceRepository();
    sessionRepository = _MockSessionRepository();
    when(
      () => membership.ensureMembership(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => deviceRepository.getDeviceByNfcCode(any(), any()),
    ).thenAnswer((_) async => null);
    when(
      () => sessionRepository.saveSession(session: any(named: 'session')),
    ).thenAnswer((_) async {});

    controller = WorkoutDayController(
      firestore: firestore,
      membership: membership,
      sessionRepository: sessionRepository,
      createDraftRepository: () => _FakeSessionDraftRepository(),
    );
    durationService = WorkoutSessionDurationService(firestore: firestore);
    sessionCoordinator = WorkoutSessionCoordinator(
      durationService: durationService,
    );
    authProvider = _MockAuthProvider();
    when(() => authProvider.userId).thenReturn('user-1');
    when(() => authProvider.gymCode).thenReturn('gym-1');
    when(() => authProvider.showInLeaderboard).thenReturn(true);
    when(() => authProvider.userName).thenReturn('user');
  });

  Widget buildHarness({
    required Widget child,
    List<NavigatorObserver> observers = const <NavigatorObserver>[],
  }) {
    return riverpod.ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((ref) => authProvider),
        authViewStateProvider.overrideWith((ref) => _testAuthViewState()),
        workoutDayControllerProvider.overrideWith((ref) => controller),
        workoutSessionDurationServiceProvider.overrideWith(
          (ref) => durationService,
        ),
        workoutSessionCoordinatorProvider.overrideWith(
          (ref) => sessionCoordinator,
        ),
        membershipServiceProvider.overrideWith((ref) => membership),
        getDeviceByNfcCodeProvider.overrideWith(
          (ref) => GetDeviceByNfcCode(deviceRepository),
        ),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<WorkoutDayController>.value(value: controller),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          navigatorObservers: observers,
          onGenerateRoute: (settings) {
            if (settings.name == AppRouter.home) {
              final tabIndex = settings.arguments as int?;
              return MaterialPageRoute<void>(
                builder: (_) =>
                    Scaffold(body: Text('home-tab-${tabIndex ?? -1}')),
                settings: settings,
              );
            }
            return null;
          },
          home: child,
        ),
      ),
    );
  }

  testWidgets('tapping add exercise footer navigates back to gym tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(
        child: const WorkoutDayScreen(
          gymId: 'gym-1',
          deviceId: 'device-1',
          exerciseId: 'exercise-1',
          sessionBuilder: _minimalSessionBuilder,
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(controller.activeSessions(), hasLength(1));

    await tester.tap(find.text('Übung hinzufügen'));
    await tester.pumpAndSettle();

    expect(find.text('home-tab-0'), findsOneWidget);
  });

  testWidgets('closing a secondary screen keeps the shared session alive', (
    tester,
  ) async {
    final renderedSessionKeys = <String>[];

    Widget buildScreen() {
      return WorkoutDayScreen(
        gymId: 'gym-1',
        deviceId: 'device-1',
        exerciseId: 'exercise-1',
        sessionBuilder: (context, session, displayIndex) {
          renderedSessionKeys.add(session.key);
          return Text('session-${session.key}', key: ValueKey(session.key));
        },
      );
    }

    await tester.pumpWidget(buildHarness(child: buildScreen()));

    await tester.pump();
    await tester.pump();

    expect(controller.activeSessions(), hasLength(1));
    final sessionKey = controller.activeSessions().first.key;
    expect(renderedSessionKeys, contains(sessionKey));

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(MaterialPageRoute(builder: (_) => buildScreen()));

    await tester.pump();
    await tester.pump();

    expect(controller.activeSessions(), hasLength(1));

    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(controller.activeSessions(), hasLength(1));
    expect(
      renderedSessionKeys.where((key) => key == sessionKey).length,
      greaterThanOrEqualTo(2),
    );
  });

  testWidgets(
    'popping the workout screen keeps the session so new devices show prior cards',
    (tester) async {
      Widget buildScreen(String deviceId) {
        return WorkoutDayScreen(
          gymId: 'gym-1',
          deviceId: deviceId,
          exerciseId: 'exercise-1',
          sessionBuilder: (context, session, displayIndex) {
            return Text('session-${session.key}', key: ValueKey(session.key));
          },
        );
      }

      await tester.pumpWidget(buildHarness(child: buildScreen('device-1')));
      await tester.pump();
      await tester.pump();

      expect(controller.activeSessions(), hasLength(1));
      final firstSessionKey = controller.activeSessions().first.key;

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        MaterialPageRoute(builder: (_) => buildScreen('device-2')),
      );
      await tester.pump();
      await tester.pump();

      final activeSessions = controller.activeSessions();
      expect(activeSessions, hasLength(2));
      final sessionKeys = activeSessions.map((session) => session.key).toList();
      expect(sessionKeys, contains(firstSessionKey));

      final newSessionKey = sessionKeys.firstWhere(
        (key) => key != firstSessionKey,
      );
      expect(sessionKeys, contains(firstSessionKey));
      expect(sessionKeys, contains(newSessionKey));
    },
  );

  testWidgets(
    'stale workout route after finalized session redirects to profile and avoids re-entry',
    (tester) async {
      await sessionCoordinator.markSessionFinalized(
        reason: WorkoutFinalizeReason.autoInactivity,
        finalizedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildHarness(
          child: const WorkoutDayScreen(
            gymId: 'gym-1',
            deviceId: 'device-1',
            exerciseId: 'exercise-1',
            sessionBuilder: _minimalSessionBuilder,
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('home-tab-1'), findsOneWidget);
      expect(controller.activeSessions(), isEmpty);
    },
  );

  testWidgets(
    'fresh workout route after finalized session can start a new workout context',
    (tester) async {
      await sessionCoordinator.markSessionFinalized(
        reason: WorkoutFinalizeReason.autoInactivity,
        finalizedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildHarness(
          child: WorkoutDayScreen(
            gymId: 'gym-1',
            deviceId: 'device-1',
            exerciseId: 'exercise-1',
            entryRequestedAtMs: DateTime.now().millisecondsSinceEpoch,
            sessionBuilder: _minimalSessionBuilder,
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(controller.activeSessions(), hasLength(1));
    },
  );
}

Widget _minimalSessionBuilder(
  BuildContext context,
  WorkoutDaySession session,
  int displayIndex,
) {
  return Text('session-${session.key}', key: ValueKey(session.key));
}
