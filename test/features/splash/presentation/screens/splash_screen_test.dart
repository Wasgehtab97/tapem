import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tapem/bootstrap/providers.dart';
import 'package:tapem/core/constants.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/splash/presentation/screens/splash_screen.dart';

class _FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _isAdmin = false;
  bool _isGuest = false;
  bool _isGymOwner = false;
  bool _isCoach = false;
  String? _error;
  String? _gymCode;
  String? _userId;
  GymContextStatus _status = GymContextStatus.unknown;

  void setState({
    bool? isLoading,
    bool? isLoggedIn,
    bool? isAdmin,
    bool? isGuest,
    bool? isGymOwner,
    bool? isCoach,
    String? error,
    String? gymCode,
    String? userId,
    GymContextStatus? status,
  }) {
    _isLoading = isLoading ?? _isLoading;
    _isLoggedIn = isLoggedIn ?? _isLoggedIn;
    _isAdmin = isAdmin ?? _isAdmin;
    _isGuest = isGuest ?? _isGuest;
    _isGymOwner = isGymOwner ?? _isGymOwner;
    _isCoach = isCoach ?? _isCoach;
    _error = error;
    _gymCode = gymCode;
    _userId = userId;
    _status = status ?? _status;
    notifyListeners();
  }

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isLoggedIn => _isLoggedIn;

  @override
  bool get isAdmin => _isAdmin;

  @override
  bool get isGuest => _isGuest;

  @override
  bool get isGymOwner => _isGymOwner;

  @override
  bool get isCoach => _isCoach;

  @override
  String? get error => _error;

  @override
  GymContextStatus get gymContextStatus => _status;

  @override
  String? get gymCode => _gymCode;

  @override
  String? get userId => _userId;

  @override
  Future<void> reloadCurrentUser() async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'routes to auth flow instead of showing retry block on auth error',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fakeAuth = _FakeAuthProvider()
        ..setState(error: 'boom', isLoggedIn: false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith((ref) => fakeAuth),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: const SplashScreen(),
            onGenerateRoute: (settings) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => Text('route:${settings.name}'),
              );
            },
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump();

      expect(find.textContaining('Fehler beim Laden'), findsNothing);
      expect(find.text('Erneut versuchen'), findsNothing);
      expect(find.text('route:/gym_entry'), findsOneWidget);
    },
  );

  testWidgets('routes to gym access when pre-auth gym id exists in prefs', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      StorageKeys.preAuthGymId: 'gym-abc',
    });
    final prefs = await SharedPreferences.getInstance();
    final fakeAuth = _FakeAuthProvider()
      ..setState(error: 'boom', isLoggedIn: false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => fakeAuth),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          home: const SplashScreen(),
          onGenerateRoute: (settings) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) =>
                  Text('route:${settings.name}:${settings.arguments}'),
            );
          },
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();

    expect(find.textContaining('Fehler beim Laden'), findsNothing);
    expect(find.text('Erneut versuchen'), findsNothing);
    expect(find.text('route:/gym_access:gym-abc'), findsOneWidget);
  });
}
