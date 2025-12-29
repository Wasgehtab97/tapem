import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/drafts/session_draft.dart';
import 'package:tapem/core/drafts/session_draft_repository.dart';
import 'package:tapem/core/providers/auth_provider.dart';

import 'package:tapem/features/training_details/domain/repositories/session_repository.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/device/presentation/models/workout_device_selection.dart';
import 'package:tapem/features/device/presentation/screens/workout_day_screen.dart';
import 'package:tapem/features/device/presentation/widgets/session_rest_timer.dart';

import 'package:tapem/services/membership_service.dart';
import 'package:tapem/ui/timer/active_workout_timer.dart';

import '../../../../features/auth/helpers/fake_firestore.dart';

class _MockAuthProvider extends Mock implements AuthProvider {}



class _MockMembershipService extends Mock implements MembershipService {}

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
    _drafts.removeWhere(
      (_, draft) => draft.updatedAt + draft.ttlMs < nowMs,
    );
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(DateTime(2023));
    registerFallbackValue(Session(
      sessionId: 'dummy',
      gymId: 'gym',
      userId: 'user',
      deviceId: 'device',
      deviceName: 'Device',
      note: 'Note',
      timestamp: DateTime.now(),
      sets: [],
    ));
  });

  late WorkoutDayController controller;
  late _MockAuthProvider authProvider;

  late _MockMembershipService membership;
  late _MockSessionRepository sessionRepository;

  setUp(() {
    final firestore = FakeFirebaseFirestore();
    membership = _MockMembershipService();
    sessionRepository = _MockSessionRepository();
    when(() => membership.ensureMembership(any(), any()))
        .thenAnswer((_) async {});
    when(() => sessionRepository.saveSession(session: any(named: 'session')))
        .thenAnswer((_) async {});

    controller = WorkoutDayController(
      firestore: firestore,
      membership: membership,
      sessionRepository: sessionRepository,
      createDraftRepository: () => _FakeSessionDraftRepository(),
    );
    authProvider = _MockAuthProvider();
    when(() => authProvider.userId).thenReturn('user-1');

  });

  tearDown(() {
    controller.dispose();
  });

  testWidgets('tapping add button opens selector and adds session', (tester) async {
    final observer = _InterceptingNavigatorObserver(
      selection: const WorkoutDeviceSelection(
        gymId: 'gym-1',
        deviceId: 'device-2',
        exerciseId: 'exercise-2',
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WorkoutDayController>.value(value: controller),
          Provider<AuthProvider>.value(value: authProvider),

        ],
        child: MaterialApp(
          navigatorObservers: [observer],
          home: const WorkoutDayScreen(
            gymId: 'gym-1',
            deviceId: 'device-1',
            exerciseId: 'exercise-1',
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(controller.activeSessions(), hasLength(1));

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(controller.activeSessions(), hasLength(2));
    expect(
      controller.activeSessions().where(
            (session) =>
                session.deviceId == 'device-2' &&
                session.exerciseId == 'exercise-2',
          ),
      isNotEmpty,
    );
  });



  testWidgets('closing a secondary screen keeps the shared session alive',
      (tester) async {
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

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WorkoutDayController>.value(value: controller),
          Provider<AuthProvider>.value(value: authProvider),

        ],
        child: MaterialApp(home: buildScreen()),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(controller.activeSessions(), hasLength(1));
    final sessionKey = controller.activeSessions().first.key;
    expect(find.byKey(ValueKey(sessionKey)), findsOneWidget);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(
      MaterialPageRoute(builder: (_) => buildScreen()),
    );

    await tester.pump();
    await tester.pump();

    expect(controller.activeSessions(), hasLength(1));

    navigator.pop();
    await tester.pumpAndSettle();

    expect(controller.activeSessions(), hasLength(1));
    expect(find.byKey(ValueKey(sessionKey)), findsOneWidget);
    expect(
      renderedSessionKeys.where((key) => key == sessionKey).length,
      greaterThanOrEqualTo(2),
    );
  });

  testWidgets(
      'popping the workout screen keeps the session so new devices show prior cards',
      (tester) async {
    Future<void> pumpWorkoutScreen(String deviceId) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<WorkoutDayController>.value(
              value: controller,
            ),
            Provider<AuthProvider>.value(value: authProvider),

          ],
          child: MaterialApp(
            home: WorkoutDayScreen(
              gymId: 'gym-1',
              deviceId: deviceId,
              exerciseId: 'exercise-1',
              sessionBuilder: (context, session, displayIndex) {
                return Text('session-${session.key}', key: ValueKey(session.key));
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();
    }

    await pumpWorkoutScreen('device-1');

    expect(controller.activeSessions(), hasLength(1));
    final firstSessionKey = controller.activeSessions().first.key;
    expect(find.byKey(ValueKey(firstSessionKey)), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await pumpWorkoutScreen('device-2');

    final activeSessions = controller.activeSessions();
    expect(activeSessions, hasLength(2));
    final sessionKeys = activeSessions.map((session) => session.key).toList();
    expect(sessionKeys, contains(firstSessionKey));

    final newSessionKey = sessionKeys.firstWhere((key) => key != firstSessionKey);
    expect(find.byKey(ValueKey(firstSessionKey)), findsOneWidget);
    expect(find.byKey(ValueKey(newSessionKey)), findsOneWidget);
  });
}

class _InterceptingNavigatorObserver extends NavigatorObserver {
  _InterceptingNavigatorObserver({required this.selection});

  final WorkoutDeviceSelection selection;
  bool _handled = false;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (_handled) return;
    if (previousRoute != null && route is MaterialPageRoute<dynamic>) {
      route.navigator?.pop(selection);
      _handled = true;
    }
  }
}
