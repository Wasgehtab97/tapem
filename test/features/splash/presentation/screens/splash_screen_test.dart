import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tapem/bootstrap/providers.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/splash/presentation/screens/splash_screen.dart';

class _FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _isAdmin = false;
  String? _error;
  String? _gymCode;
  String? _userId;
  GymContextStatus _status = GymContextStatus.unknown;

  void setState({
    bool? isLoading,
    bool? isLoggedIn,
    bool? isAdmin,
    String? error,
    String? gymCode,
    String? userId,
    GymContextStatus? status,
  }) {
    _isLoading = isLoading ?? _isLoading;
    _isLoggedIn = isLoggedIn ?? _isLoggedIn;
    _isAdmin = isAdmin ?? _isAdmin;
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
  testWidgets('renders retry UI when authentication fails', (tester) async {
    final fakeAuth = _FakeAuthProvider()
      ..setState(error: 'boom', isLoggedIn: false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => fakeAuth),
        ],
        child: const MaterialApp(home: SplashScreen()),
      ),
    );

    await tester.pump();

    expect(find.textContaining('Fehler beim Laden'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);
  });
}
