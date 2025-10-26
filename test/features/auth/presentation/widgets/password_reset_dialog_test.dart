import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/auth/domain/models/user_data.dart';
import 'package:tapem/features/auth/presentation/widgets/password_reset_dialog.dart';
import 'package:tapem/l10n/app_localizations.dart';

import '../../helpers/fakes.dart';

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
  }) async {
    final prefsGetter = createInMemorySharedPreferences();
    final provider = AuthProvider(
      repo: repository,
      authManager: FakeFirebaseAuthManager(
        currentUser: FakeFirebaseUser(uid: user.id, email: user.email),
        onGetClaims: (_) async => const <String, dynamic>{'role': 'member'},
      ),
      sessionDraftRepository: FakeSessionDraftRepository(),
      sharedPreferencesProvider: prefsGetter,
    );
    await Future<void>.delayed(Duration.zero);
    return provider;
  }

  Widget buildHarness(AuthProvider provider) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: provider,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => ElevatedButton(
              onPressed: () => showPasswordResetDialog(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  group('Password reset dialog', () {
    testWidgets('validates email input', (WidgetTester tester) async {
      final provider = await createProvider(
        repository: FakeAuthRepository(
          onGetCurrentUser: () async => user,
          onSendPasswordResetEmail: (_) async {},
        ),
      );

      await tester.pumpWidget(buildHarness(provider));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(AlertDialog));
      final loc = AppLocalizations.of(context)!;

      await tester.tap(find.widgetWithText(ElevatedButton, 'OK'));
      await tester.pump();

      expect(find.text(loc.emailInvalid), findsOneWidget);
    });

    testWidgets('closes dialog and shows confirmation on success',
        (WidgetTester tester) async {
      bool called = false;
      final provider = await createProvider(
        repository: FakeAuthRepository(
          onGetCurrentUser: () async => user,
          onSendPasswordResetEmail: (String email) async {
            called = true;
            expect(email, 'user@example.com');
          },
        ),
      );

      await tester.pumpWidget(buildHarness(provider));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(AlertDialog));
      final loc = AppLocalizations.of(context)!;

      await tester.enterText(
        find.widgetWithText(TextField, loc.emailFieldLabel),
        'user@example.com',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'OK'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text(loc.passwordResetSent), findsOneWidget);
    });

    testWidgets('shows backend error message', (WidgetTester tester) async {
      final provider = await createProvider(
        repository: FakeAuthRepository(
          onGetCurrentUser: () async => user,
          onSendPasswordResetEmail: (_) => Future<void>.error(
            fb_auth.FirebaseAuthException(message: 'bad', code: 'oops'),
          ),
        ),
      );

      await tester.pumpWidget(buildHarness(provider));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(AlertDialog));
      final loc = AppLocalizations.of(context)!;

      await tester.enterText(
        find.widgetWithText(TextField, loc.emailFieldLabel),
        'user@example.com',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'OK'));
      await tester.pump();

      expect(find.text('bad'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
