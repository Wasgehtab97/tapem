import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/auth/domain/models/user_data.dart';
import 'package:tapem/features/auth/presentation/widgets/login_form.dart';
import 'package:tapem/l10n/app_localizations.dart';

import '../../helpers/fakes.dart';
import '../../helpers/recording_navigator_observer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginForm', () {
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

    Future<AuthProvider> buildProvider({
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

    Widget buildApp(AuthProvider provider, RecordingNavigatorObserver observer) {
      return ChangeNotifierProvider<AuthProvider>.value(
        value: provider,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: LoginForm()),
          routes: <String, WidgetBuilder>{
            AppRouter.home: (_) => const Scaffold(body: Text('home')),
          },
          navigatorObservers: <NavigatorObserver>[observer],
        ),
      );
    }

    testWidgets('submits credentials and navigates to home on success',
        (WidgetTester tester) async {
      final authManager = FakeFirebaseAuthManager(currentUser: null,
          onGetClaims: (_) async => const <String, dynamic>{'role': 'member'});
      late AuthProvider provider;
      final repository = FakeAuthRepository(
        onLogin: (String email, String password) async {
          expect(email, 'user@example.com');
          expect(password, 'password123');
          authManager.currentUserSetter =
              FakeFirebaseUser(uid: user.id, email: user.email);
          return user;
        },
        onGetCurrentUser: () async => user,
      );
      provider = await buildProvider(
        authManager: authManager,
        repository: repository,
      );

      final observer = RecordingNavigatorObserver();
      await tester.pumpWidget(buildApp(provider, observer));
      await tester.pump();

      final BuildContext context = tester.element(find.byType(LoginForm));
      final loc = AppLocalizations.of(context)!;

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'user@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'password123',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, loc.loginButton));
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

    testWidgets('shows error message when login fails',
        (WidgetTester tester) async {
      final authManager = FakeFirebaseAuthManager(currentUser: null);
      final repository = FakeAuthRepository(
        onLogin: (_, __) =>
            Future<UserData>.error(Exception('Invalid credentials')),
        onGetCurrentUser: () async => user,
      );
      final provider = await buildProvider(
        authManager: authManager,
        repository: repository,
      );

      await tester.pumpWidget(
        buildApp(provider, RecordingNavigatorObserver()),
      );
      await tester.pump();

      final BuildContext context = tester.element(find.byType(LoginForm));
      final loc = AppLocalizations.of(context)!;

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'user@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'wrong',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, loc.loginButton));
      await tester.pump();

      expect(find.text('Exception: Invalid credentials'), findsOneWidget);
    });

    testWidgets('displays loading indicator while login is in progress',
        (WidgetTester tester) async {
      final completer = Completer<void>();
      final authManager = FakeFirebaseAuthManager(currentUser: null,
          onGetClaims: (_) async => const <String, dynamic>{});
      final repository = FakeAuthRepository(
        onLogin: (String email, String password) async {
          await completer.future;
          authManager.currentUserSetter =
              FakeFirebaseUser(uid: user.id, email: user.email);
          return user;
        },
        onGetCurrentUser: () async => user,
      );
      final provider = await buildProvider(
        authManager: authManager,
        repository: repository,
      );

      await tester.pumpWidget(
        buildApp(provider, RecordingNavigatorObserver()),
      );
      await tester.pump();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'user@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'password123',
      );

      final BuildContext context = tester.element(find.byType(LoginForm));
      final loc = AppLocalizations.of(context)!;

      await tester.tap(find.widgetWithText(ElevatedButton, loc.loginButton));
      await tester.pump();

      final ElevatedButton button =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();
    });
  });
}
