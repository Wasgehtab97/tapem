import 'package:flutter_test/flutter_test.dart';

import 'package:tapem/bootstrap/providers.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/splash/application/splash_flow.dart';

AuthViewState _state({
  bool isLoading = false,
  bool isLoggedIn = false,
  bool isAdmin = false,
  bool isCoach = false,
  GymContextStatus status = GymContextStatus.unknown,
  String? gymCode,
  String? error,
}) {
  return AuthViewState(
    isLoading: isLoading,
    isLoggedIn: isLoggedIn,
    isGuest: false,
    isAdmin: isAdmin,
    isCoach: isCoach,
    gymContextStatus: status,
    gymCode: gymCode,
    userId: 'uid-1',
    error: error,
  );
}

void main() {
  test('returns null while loading or when error blocking login exists', () {
    expect(resolveSplashDestination(_state(isLoading: true)), isNull);
    expect(
      resolveSplashDestination(_state(error: 'boom')),
      isNull,
    );
  });

  test('navigates to auth when user is not logged in', () {
    expect(resolveSplashDestination(_state()), SplashDestination.auth);
  });

  test('navigates to select gym when context missing', () {
    expect(
      resolveSplashDestination(
        _state(isLoggedIn: true, status: GymContextStatus.missingSelection),
      ),
      SplashDestination.selectGym,
    );
  });

  test('navigates home when gym context ready', () {
    expect(
      resolveSplashDestination(
        _state(isLoggedIn: true, status: GymContextStatus.ready, gymCode: 'g1'),
      ),
      SplashDestination.home,
    );
  });
}
