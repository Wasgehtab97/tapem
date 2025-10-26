import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:tapem/l10n/app_localizations.dart';

import '../../helpers/fakes.dart';
import '../../helpers/recording_navigator_observer.dart';
import '../../helpers/widget_tester_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildApp({
    required Widget child,
    RecordingNavigatorObserver? observer,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
      routes: <String, WidgetBuilder>{
        AppRouter.auth: (_) => const Scaffold(body: Text('auth')),
      },
      navigatorObservers:
          observer != null ? <NavigatorObserver>[observer] : const [],
    );
  }

  group('ResetPasswordScreen', () {
    testWidgets('confirms reset and navigates back to auth',
        (WidgetTester tester) async {
      final fakeAuth = FakeFirebaseAuth();
      final observer = RecordingNavigatorObserver();

      await tester.pumpWidget(
        buildApp(
          child: ResetPasswordScreen(
            oobCode: 'abc',
            firebaseAuth: fakeAuth,
          ),
          observer: observer,
        ),
      );

      final BuildContext context = tester.element(find.byType(ResetPasswordScreen));
      final loc = AppLocalizations.of(context)!;

      await tester.enterText(
        find.widgetWithText(TextFormField, loc.newPasswordFieldLabel),
        'password123',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, loc.confirmPasswordButton));
      await tester.pump();
      await tester.pumpUntilAbsent(find.byType(CircularProgressIndicator));
      await tester.pump();
      await tester.pumpUntilVisible(find.text(loc.passwordResetSuccess));

      expect(fakeAuth.confirmPasswordResetCalled, isTrue);
      expect(fakeAuth.lastConfirmCode, 'abc');
      expect(fakeAuth.lastConfirmPassword, 'password123');
      expect(find.text(loc.passwordResetSuccess), findsOneWidget);
      expect(
        observer.pushedRoutes
            .map((Route<dynamic> route) => route.settings.name)
            .whereType<String>()
            .contains(AppRouter.auth),
        isTrue,
      );
    });

    testWidgets('shows backend errors', (WidgetTester tester) async {
      final fakeAuth = FakeFirebaseAuth()
        ..confirmResetError = fb_auth.FirebaseAuthException(
          code: 'expired-action-code',
          message: 'Invalid or expired code',
        );

      await tester.pumpWidget(
        buildApp(
          child: ResetPasswordScreen(
            oobCode: 'abc',
            firebaseAuth: fakeAuth,
          ),
        ),
      );

      final BuildContext context = tester.element(find.byType(ResetPasswordScreen));
      final loc = AppLocalizations.of(context)!;

      await tester.enterText(
        find.widgetWithText(TextFormField, loc.newPasswordFieldLabel),
        '123',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, loc.confirmPasswordButton));
      await tester.pump();

      // Validation catches short password first.
      expect(find.text(loc.passwordTooShort), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, loc.newPasswordFieldLabel),
        'password123',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, loc.confirmPasswordButton));
      await tester.pump();

      expect(find.text('Invalid or expired code'), findsOneWidget);
      expect(fakeAuth.confirmPasswordResetCalled, isFalse);
    });
  });
}
