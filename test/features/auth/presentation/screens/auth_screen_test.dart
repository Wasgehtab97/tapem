import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/auth/domain/models/user_data.dart';
import 'package:tapem/features/auth/presentation/screens/auth_screen.dart';
import 'package:tapem/l10n/app_localizations.dart';

import '../../helpers/fakes.dart';
import '../../helpers/widget_tester_extensions.dart';

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
    required FakeAuthRepository repository,
    FakeFirebaseAuthManager? authManager,
  }) async {
    final prefsGetter = createInMemorySharedPreferences();
    final provider = AuthProvider(
      repo: repository,
      authManager: authManager ??
          FakeFirebaseAuthManager(
            currentUser: FakeFirebaseUser(uid: user.id, email: user.email),
            onGetClaims: (_) async => const <String, dynamic>{'role': 'member'},
          ),
      sessionDraftRepository: FakeSessionDraftRepository(),
      sharedPreferencesProvider: prefsGetter,
    );
    await Future<void>.delayed(Duration.zero);
    return provider;
  }

  Widget buildApp(AuthProvider provider) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: provider,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AuthScreen(),
      ),
    );
  }

  group('AuthScreen', () {
    testWidgets('switches between login and registration tabs',
        (WidgetTester tester) async {
      final provider = await createProvider(
        repository: FakeAuthRepository(
          onGetCurrentUser: () async => null,
          onRegister: (_, __, ___) async => user,
          onLogin: (_, __) async => user,
        ),
        authManager: FakeFirebaseAuthManager(currentUser: null),
      );

      await tester.pumpWidget(buildApp(provider));
      await tester.pump();
      await tester.pumpUntilAbsent(find.byType(CircularProgressIndicator));

      final BuildContext context = tester.element(find.byType(AuthScreen));
      final loc = AppLocalizations.of(context)!;

      expect(find.text(loc.gymCodeFieldLabel), findsNothing);

      await tester.tap(find.text(loc.registerButton));
      await tester.pump();
      await tester.pumpUntilVisible(find.text(loc.gymCodeFieldLabel));

      expect(find.text(loc.gymCodeFieldLabel), findsOneWidget);

      await tester.tap(find.text(loc.loginButton));
      await tester.pump();
      await tester.pumpUntilAbsent(find.text(loc.gymCodeFieldLabel));

      expect(find.text(loc.gymCodeFieldLabel), findsNothing);
    });

    testWidgets('shows loading overlay while provider is busy',
        (WidgetTester tester) async {
      final completer = Completer<void>();
      late FakeFirebaseAuthManager authManager;
      authManager = FakeFirebaseAuthManager(currentUser: null,
          onGetClaims: (_) async => const <String, dynamic>{});
      final repository = FakeAuthRepository(
        onGetCurrentUser: () async => user,
        onLogin: (String email, String password) async {
          await completer.future;
          authManager.currentUserSetter =
              FakeFirebaseUser(uid: user.id, email: user.email);
          return user;
        },
      );
      final provider = await createProvider(
        repository: repository,
        authManager: authManager,
      );

      await tester.pumpWidget(buildApp(provider));
      await tester.pump();
      await tester.pumpUntilAbsent(find.byType(CircularProgressIndicator));

      await tester.runAsync(() async {
        provider.login('user@example.com', 'password123');
      });
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete();
      await tester.pump();
      await tester.pumpUntilAbsent(find.byType(CircularProgressIndicator));
    });
  });
}
