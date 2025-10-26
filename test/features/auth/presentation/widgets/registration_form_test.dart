import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/auth/domain/models/user_data.dart';
import 'package:tapem/features/auth/presentation/widgets/registration_form.dart';
import 'package:tapem/features/gym/domain/usecases/validate_gym_code.dart';
import 'package:tapem/l10n/app_localizations.dart';

import '../../helpers/fakes.dart';
import '../../helpers/recording_navigator_observer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final user = UserData(
    id: 'uid-1',
    email: 'user@example.com',
    userName: 'tester',
    gymCodes: <String>['gym-1'],
    showInLeaderboard: true,
    publicProfile: true,
    role: 'member',
    createdAt: DateTime(2023, 1, 1),
  );

  Future<AuthProvider> createProvider({
    required FakeFirebaseAuthManager authManager,
    required FakeAuthRepository repository,
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final provider = AuthProvider(
      repo: repository,
      authManager: authManager,
      sessionDraftRepository: FakeSessionDraftRepository(),
    );
    await Future<void>.delayed(Duration.zero);
    return provider;
  }

  Widget buildApp(
    AuthProvider provider,
    Widget child, {
    RecordingNavigatorObserver? observer,
  }) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: provider,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
        routes: <String, WidgetBuilder>{
          AppRouter.home: (_) => const Scaffold(body: Text('home')),
        },
        navigatorObservers:
            observer != null ? <NavigatorObserver>[observer] : const [],
      ),
    );
  }

  group('RegistrationForm', () {
    testWidgets('registers successfully and navigates to home',
        (WidgetTester tester) async {
      final authManager = FakeFirebaseAuthManager(currentUser: null,
          onGetClaims: (_) async => const <String, dynamic>{'role': 'member'});
      final repository = FakeAuthRepository(
        onRegister: (String email, String password, String gymId) async {
          expect(email, 'user@example.com');
          expect(password, 'password123');
          expect(gymId, 'GYM1');
          authManager.currentUserSetter =
              FakeFirebaseUser(uid: user.id, email: user.email);
          return user;
        },
        onGetCurrentUser: () async => user,
      );
      final provider = await createProvider(
        authManager: authManager,
        repository: repository,
      );

      final observer = RecordingNavigatorObserver();
      await tester.pumpWidget(
        buildApp(
          provider,
          RegistrationForm(
            validateGymCode: (_) async {},
          ),
          observer: observer,
        ),
      );
      await tester.pump();

      final BuildContext context = tester.element(find.byType(RegistrationForm));
      final loc = AppLocalizations.of(context)!;

      await tester.enterText(
        find.widgetWithText(TextFormField, loc.emailFieldLabel),
        'user@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, loc.passwordFieldLabel),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, loc.gymCodeFieldLabel),
        'GYM1',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, loc.registerButton));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(provider.isLoggedIn, isTrue);
      expect(
        observer.pushedRoutes
            .map((Route<dynamic> route) => route.settings.name)
            .whereType<String>()
            .contains(AppRouter.home),
        isTrue,
      );
    });

    testWidgets('shows error when gym code is invalid',
        (WidgetTester tester) async {
      final authManager = FakeFirebaseAuthManager(currentUser: null);
      final repository = FakeAuthRepository(
        onRegister: (_, __, ___) async => user,
        onGetCurrentUser: () async => user,
      );
      final provider = await createProvider(
        authManager: authManager,
        repository: repository,
      );

      await tester.pumpWidget(
        buildApp(
          provider,
          RegistrationForm(
            validateGymCode: (_) =>
                Future<void>.error(GymNotFoundException()),
          ),
        ),
      );
      await tester.pump();

      final BuildContext context = tester.element(find.byType(RegistrationForm));
      final loc = AppLocalizations.of(context)!;

      await tester.enterText(
        find.widgetWithText(TextFormField, loc.emailFieldLabel),
        'user@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, loc.passwordFieldLabel),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, loc.gymCodeFieldLabel),
        'INVALID',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, loc.registerButton));
      await tester.pump();

      expect(find.text(loc.gymCodeInvalid), findsOneWidget);
      expect(provider.isLoggedIn, isFalse);
    });

    testWidgets('locks the form after three invalid attempts',
        (WidgetTester tester) async {
      final authManager = FakeFirebaseAuthManager(currentUser: null);
      final repository = FakeAuthRepository(
        onRegister: (_, __, ___) async => user,
        onGetCurrentUser: () async => user,
      );
      final provider = await createProvider(
        authManager: authManager,
        repository: repository,
      );

      await tester.pumpWidget(
        buildApp(
          provider,
          RegistrationForm(
            validateGymCode: (_) =>
                Future<void>.error(GymNotFoundException()),
          ),
        ),
      );
      await tester.pump();

      final BuildContext context = tester.element(find.byType(RegistrationForm));
      final loc = AppLocalizations.of(context)!;

      Future<void> attempt() async {
        await tester.enterText(
          find.widgetWithText(TextFormField, loc.emailFieldLabel),
          'user@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, loc.passwordFieldLabel),
          'password123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, loc.gymCodeFieldLabel),
          'INVALID',
        );
        await tester.tap(
          find.widgetWithText(ElevatedButton, loc.registerButton),
        );
        await tester.pump();
      }

      await attempt();
      await attempt();
      await attempt();

      await tester.pump();

      final ElevatedButton button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, loc.registerButton),
      );
      expect(button.onPressed, isNull);
      expect(find.text(loc.gymCodeLockedMessage), findsOneWidget);
    });
  });
}
