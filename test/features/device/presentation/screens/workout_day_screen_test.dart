import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/drafts/session_draft.dart';
import 'package:tapem/core/drafts/session_draft_repository.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/training_plan_provider.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/device/presentation/screens/workout_day_screen.dart';
import 'package:tapem/services/membership_service.dart';

import '../../../../features/auth/helpers/fake_firestore.dart';

class _MockAuthProvider extends Mock implements AuthProvider {}

class _MockTrainingPlanProvider extends Mock
    with ChangeNotifier
    implements TrainingPlanProvider {}

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(DateTime(2023));
  });

  late WorkoutDayController controller;
  late _MockAuthProvider authProvider;
  late _MockTrainingPlanProvider trainingPlanProvider;
  late _MockMembershipService membership;

  setUp(() {
    final firestore = FakeFirebaseFirestore();
    membership = _MockMembershipService();
    when(() => membership.ensureMembership(any(), any()))
        .thenAnswer((_) async {});
    controller = WorkoutDayController(
      firestore: firestore,
      membership: membership,
      createDraftRepository: () => _FakeSessionDraftRepository(),
    );
    authProvider = _MockAuthProvider();
    when(() => authProvider.userId).thenReturn('user-1');
    trainingPlanProvider = _MockTrainingPlanProvider();
    when(() => trainingPlanProvider.entryForDate(any(), any(), any()))
        .thenReturn(null);
  });

  tearDown(() {
    controller.dispose();
  });

  testWidgets('closing a secondary screen keeps the shared session alive',
      (tester) async {
    final renderedSessionKeys = <String>[];

    Widget buildScreen() {
      return WorkoutDayScreen(
        gymId: 'gym-1',
        deviceId: 'device-1',
        exerciseId: 'exercise-1',
        sessionBuilder: (context, session, plannedEntry) {
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
          ChangeNotifierProvider<TrainingPlanProvider>.value(
            value: trainingPlanProvider,
          ),
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

    await navigator.pop();
    await tester.pumpAndSettle();

    expect(controller.activeSessions(), hasLength(1));
    expect(find.byKey(ValueKey(sessionKey)), findsOneWidget);
    expect(
      renderedSessionKeys.where((key) => key == sessionKey).length,
      greaterThanOrEqualTo(2),
    );
  });
}
