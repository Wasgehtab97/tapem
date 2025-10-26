import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/auth/domain/models/user_data.dart';
import 'package:tapem/features/auth/presentation/widgets/username_dialog.dart';
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
              onPressed: () => showUsernameDialog(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  group('Username dialog', () {
    testWidgets('closes when username is saved', (WidgetTester tester) async {
      final repository = FakeAuthRepository(
        onGetCurrentUser: () async => user,
        onIsUsernameAvailable: (_) async => true,
        onSetUsername: (_, __) async {},
      );
      final provider = await createProvider(repository: repository);

      await tester.pumpWidget(buildHarness(provider));

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pumpUntilVisible(find.byType(AlertDialog));

      await tester.enterText(find.byType(TextField), 'new-user');
      await tester.tap(find.widgetWithText(ElevatedButton, 'OK'));
      await tester.pump();
      await tester.pumpUntilAbsent(find.byType(AlertDialog));

      expect(provider.userName, 'new-user');
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('shows error when username cannot be set',
        (WidgetTester tester) async {
      final repository = FakeAuthRepository(
        onGetCurrentUser: () async => user,
        onIsUsernameAvailable: (_) async => false,
        onSetUsername: (_, __) async {},
      );
      final provider = await createProvider(repository: repository);

      await tester.pumpWidget(buildHarness(provider));

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pumpUntilVisible(find.byType(AlertDialog));

      await tester.enterText(find.byType(TextField), 'taken');
      await tester.tap(find.widgetWithText(ElevatedButton, 'OK'));
      await tester.pump();

      expect(find.text('username_taken'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
