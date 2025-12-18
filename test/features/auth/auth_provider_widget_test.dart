import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/auth/presentation/widgets/login_form.dart';
import 'package:tapem/features/auth/presentation/widgets/registration_form.dart';
import 'package:tapem/features/auth/presentation/widgets/username_dialog.dart';
import 'package:tapem/features/gym/domain/usecases/validate_gym_code.dart';
import 'package:tapem/features/splash/presentation/screens/splash_screen.dart';
import 'package:tapem/l10n/app_localizations.dart';

class _MockAuthProvider extends Mock with ChangeNotifier implements AuthProvider {}
class _MockValidateGymCode extends Mock implements ValidateGymCode {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginForm widget tests', () {
    late _MockAuthProvider authProvider;

    setUp(() {
      authProvider = _MockAuthProvider();
    });

    Widget buildLoginApp({
      required _MockAuthProvider provider,
      required void Function(String? routeName) onRoutePushed,
    }) {
      return ChangeNotifierProvider<AuthProvider>.value(
        value: provider,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: const LoginForm(),
          ),
          onGenerateRoute: (settings) {
            onRoutePushed(settings.name);
            return MaterialPageRoute<void>(builder: (_) => const SizedBox());
          },
        ),
      );
    }

    testWidgets('submits credentials and navigates on success', (tester) async {
      var isLoading = false;
      String? error;
      String? pushedRoute;

      when(() => authProvider.isLoading).thenAnswer((_) => isLoading);
      when(() => authProvider.error).thenAnswer((_) => error);
      when(() => authProvider.gymCodes).thenReturn(const <String>['G1']);
      when(() => authProvider.gymCode).thenReturn('G1');
      when(() => authProvider.login(any(), any())).thenAnswer((invocation) async {
        isLoading = true;
        authProvider.notifyListeners();
        await Future<void>.value();
        isLoading = false;
        error = null;
        authProvider.notifyListeners();
        return const AuthResult.success();
      });

      await tester.pumpWidget(
        buildLoginApp(
          provider: authProvider,
          onRoutePushed: (route) => pushedRoute = route,
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'user@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();
      await tester.pumpAndSettle();

      verify(() => authProvider.login('user@example.com', 'password123')).called(1);
      expect(pushedRoute, AppRouter.home);
    });

    testWidgets('shows error message when provider exposes error', (tester) async {
      var isLoading = false;
      String? error;

      when(() => authProvider.isLoading).thenAnswer((_) => isLoading);
      when(() => authProvider.error).thenAnswer((_) => error);
      when(() => authProvider.gymCodes).thenReturn(const <String>['G1']);
      when(() => authProvider.gymCode).thenReturn('G1');
      when(() => authProvider.login(any(), any())).thenAnswer((_) async {
        isLoading = true;
        authProvider.notifyListeners();
        await Future<void>.value();
        isLoading = false;
        error = 'Invalid credentials';
        authProvider.notifyListeners();
        return const AuthResult.failure(error: 'Invalid credentials');
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: const LoginForm(),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'user@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('routes to select gym when gym selection is required', (tester) async {
      var isLoading = false;
      String? error;
      String? pushedRoute;

      when(() => authProvider.isLoading).thenAnswer((_) => isLoading);
      when(() => authProvider.error).thenAnswer((_) => error);
      when(() => authProvider.gymCodes).thenReturn(const <String>['G1', 'G2']);
      when(() => authProvider.gymCode).thenReturn(null);
      when(() => authProvider.login(any(), any())).thenAnswer((_) async {
        isLoading = true;
        authProvider.notifyListeners();
        await Future<void>.value();
        isLoading = false;
        authProvider.notifyListeners();
        return const AuthResult.success(requiresGymSelection: true);
      });

      await tester.pumpWidget(
        buildLoginApp(
          provider: authProvider,
          onRoutePushed: (route) => pushedRoute = route,
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'user@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(pushedRoute, AppRouter.selectGym);
    });

    testWidgets('shows loading indicator when provider is loading', (tester) async {
      when(() => authProvider.isLoading).thenReturn(true);
      when(() => authProvider.error).thenReturn(null);

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: LoginForm(),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsOneWidget);
      final ElevatedButton button = tester.widget(buttonFinder);
      expect(button.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('RegistrationForm widget tests', () {
    late _MockAuthProvider authProvider;
    late _MockValidateGymCode validator;

    setUp(() {
      authProvider = _MockAuthProvider();
      validator = _MockValidateGymCode();
      when(() => validator.execute(any())).thenAnswer(
        (_) async => GymCodeValidationResult(
          gymId: 'gym',
          gymName: 'Gym',
          code: 'GYM123',
          expiresAt: DateTime(2099, 1, 1),
        ),
      );
    });

    Widget buildRegistrationApp({
      required _MockAuthProvider provider,
      required ValidateGymCode gymValidator,
      required void Function(String? routeName) onRoutePushed,
    }) {
      return ChangeNotifierProvider<AuthProvider>.value(
        value: provider,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RegistrationForm(gymValidator: gymValidator),
          ),
          onGenerateRoute: (settings) {
            onRoutePushed(settings.name);
            return MaterialPageRoute<void>(builder: (_) => const SizedBox());
          },
        ),
      );
    }

    testWidgets('routes to select gym when multiple gyms exist', (tester) async {
      var isLoading = false;
      String? error;
      String? pushedRoute;

      when(() => authProvider.isLoading).thenAnswer((_) => isLoading);
      when(() => authProvider.error).thenAnswer((_) => error);
      when(() => authProvider.gymCodes).thenReturn(const <String>['G1', 'G2']);
      when(() => authProvider.gymCode).thenReturn(null);
      when(() => authProvider.register(any(), any(), any())).thenAnswer((_) async {
        isLoading = true;
        authProvider.notifyListeners();
        await Future<void>.value();
        isLoading = false;
        authProvider.notifyListeners();
        return const AuthResult.success(requiresGymSelection: true);
      });

      await tester.pumpWidget(
        buildRegistrationApp(
          provider: authProvider,
          gymValidator: validator,
          onRoutePushed: (route) => pushedRoute = route,
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'new@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.enterText(find.byType(TextFormField).at(2), 'GYM');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(pushedRoute, AppRouter.selectGym);
    });

    testWidgets('routes to home when registration has single gym', (tester) async {
      var isLoading = false;
      String? error;
      String? pushedRoute;

      when(() => authProvider.isLoading).thenAnswer((_) => isLoading);
      when(() => authProvider.error).thenAnswer((_) => error);
      when(() => authProvider.gymCodes).thenReturn(const <String>['G1']);
      when(() => authProvider.gymCode).thenReturn('G1');
      when(() => authProvider.register(any(), any(), any())).thenAnswer((_) async {
        isLoading = true;
        authProvider.notifyListeners();
        await Future<void>.value();
        isLoading = false;
        authProvider.notifyListeners();
        return const AuthResult.success();
      });

      await tester.pumpWidget(
        buildRegistrationApp(
          provider: authProvider,
          gymValidator: validator,
          onRoutePushed: (route) => pushedRoute = route,
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'new@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.enterText(find.byType(TextFormField).at(2), 'GYM');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(pushedRoute, AppRouter.home);
    });
  });

  group('SplashScreen widget tests', () {
    late _MockAuthProvider authProvider;

    setUp(() {
      authProvider = _MockAuthProvider();
    });

    Widget buildSplashApp({
      required _MockAuthProvider provider,
      required void Function(String? routeName) onRoutePushed,
    }) {
      return ChangeNotifierProvider<AuthProvider>.value(
        value: provider,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SplashScreen(),
          onGenerateRoute: (settings) {
            onRoutePushed(settings.name);
            return MaterialPageRoute<void>(builder: (_) => const SizedBox());
          },
        ),
      );
    }

    testWidgets('navigates to auth screen when user is not logged in', (tester) async {
      var isLoading = false;
      when(() => authProvider.isLoading).thenAnswer((_) => isLoading);
      when(() => authProvider.isLoggedIn).thenReturn(false);
      when(() => authProvider.error).thenReturn(null);
      when(() => authProvider.gymCodes).thenReturn(const <String>[]);

      String? pushedRoute;
      await tester.pumpWidget(
        buildSplashApp(
          provider: authProvider,
          onRoutePushed: (route) => pushedRoute = route,
        ),
      );

      await tester.pump(const Duration(milliseconds: 801));
      await tester.pumpAndSettle();

      expect(pushedRoute, AppRouter.auth);
    });

    testWidgets('navigates to select gym when multiple gyms available', (tester) async {
      when(() => authProvider.isLoading).thenReturn(false);
      when(() => authProvider.isLoggedIn).thenReturn(true);
      when(() => authProvider.error).thenReturn(null);
      when(() => authProvider.gymCodes).thenReturn(const <String>['G1', 'G2']);

      String? pushedRoute;
      await tester.pumpWidget(
        buildSplashApp(
          provider: authProvider,
          onRoutePushed: (route) => pushedRoute = route,
        ),
      );

      await tester.pump(const Duration(milliseconds: 801));
      await tester.pumpAndSettle();

      expect(pushedRoute, AppRouter.selectGym);
    });

    testWidgets('navigates to home when single gym available', (tester) async {
      when(() => authProvider.isLoading).thenReturn(false);
      when(() => authProvider.isLoggedIn).thenReturn(true);
      when(() => authProvider.error).thenReturn(null);
      when(() => authProvider.gymCodes).thenReturn(const <String>['G1']);

      String? pushedRoute;
      await tester.pumpWidget(
        buildSplashApp(
          provider: authProvider,
          onRoutePushed: (route) => pushedRoute = route,
        ),
      );

      await tester.pump(const Duration(milliseconds: 801));
      await tester.pumpAndSettle();

      expect(pushedRoute, AppRouter.home);
    });

    testWidgets('shows error state with retry when claim error occurs', (tester) async {
      when(() => authProvider.isLoading).thenReturn(false);
      when(() => authProvider.isLoggedIn).thenReturn(false);
      when(() => authProvider.error).thenReturn('claim-error');
      when(() => authProvider.reloadCurrentUser()).thenAnswer((_) async {});

      String? pushedRoute;
      await tester.pumpWidget(
        buildSplashApp(
          provider: authProvider,
          onRoutePushed: (route) => pushedRoute = route,
        ),
      );

      await tester.pump(const Duration(milliseconds: 801));
      await tester.pumpAndSettle();

      expect(find.text('Fehler beim Laden deines Accounts'), findsOneWidget);
      expect(find.textContaining('claim-error'), findsOneWidget);
      expect(find.text('Erneut versuchen'), findsOneWidget);
      expect(pushedRoute, isNull);
    });

    testWidgets('retry button triggers reload and navigation once resolved',
        (tester) async {
      var isLoading = false;
      String? currentError = 'claim-error';

      when(() => authProvider.isLoading).thenAnswer((_) => isLoading);
      when(() => authProvider.isLoggedIn).thenReturn(false);
      when(() => authProvider.error).thenAnswer((_) => currentError);
      when(() => authProvider.reloadCurrentUser()).thenAnswer((_) async {
        isLoading = true;
        authProvider.notifyListeners();
        await Future<void>.value();
        isLoading = false;
        currentError = null;
        authProvider.notifyListeners();
      });

      String? pushedRoute;
      await tester.pumpWidget(
        buildSplashApp(
          provider: authProvider,
          onRoutePushed: (route) => pushedRoute = route,
        ),
      );

      await tester.pump(const Duration(milliseconds: 801));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Erneut versuchen'));
      await tester.pump();
      await tester.pumpAndSettle();

      verify(() => authProvider.reloadCurrentUser()).called(1);
      expect(pushedRoute, AppRouter.auth);
    });
  });

  group('Username dialog widget tests', () {
    late _MockAuthProvider authProvider;

    setUp(() {
      authProvider = _MockAuthProvider();
    });

    Future<void> pumpDialogApp(WidgetTester tester) {
      return tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => showUsernameDialog(context),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('closes dialog when username is saved successfully', (tester) async {
      when(() => authProvider.setUsername(any())).thenAnswer((_) async => true);
      when(() => authProvider.error).thenReturn(null);

      await pumpDialogApp(tester);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'new-user');
      await tester.tap(find.widgetWithText(ElevatedButton, 'OK'));
      await tester.pumpAndSettle();

      verify(() => authProvider.setUsername('new-user')).called(1);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('shows error text when username save fails', (tester) async {
      String? error;
      when(() => authProvider.error).thenAnswer((_) => error);
      when(() => authProvider.setUsername(any())).thenAnswer((_) async {
        error = 'username_taken';
        authProvider.notifyListeners();
        return false;
      });

      await pumpDialogApp(tester);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'existing-user');
      await tester.tap(find.widgetWithText(ElevatedButton, 'OK'));
      await tester.pump();

      expect(find.text('username_taken'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
