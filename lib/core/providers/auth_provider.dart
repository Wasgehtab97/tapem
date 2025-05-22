// lib/core/providers/auth_provider.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:tapem/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tapem/features/auth/domain/models/user_data.dart';
import 'package:tapem/features/auth/domain/usecases/get_current_user.dart';
import 'package:tapem/features/auth/domain/usecases/login.dart';
import 'package:tapem/features/auth/domain/usecases/logout.dart';
import 'package:tapem/features/auth/domain/usecases/register.dart';

class AuthProvider extends ChangeNotifier {
  final LoginUseCase _loginUC;
  final RegisterUseCase _registerUC;
  final LogoutUseCase _logoutUC;
  final GetCurrentUserUseCase _currentUC;

  UserData? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider({AuthRepositoryImpl? repo})
      : _loginUC = LoginUseCase(repo ?? AuthRepositoryImpl()),
        _registerUC = RegisterUseCase(repo ?? AuthRepositoryImpl()),
        _logoutUC = LogoutUseCase(repo ?? AuthRepositoryImpl()),
        _currentUC = GetCurrentUserUseCase(repo ?? AuthRepositoryImpl()) {
    _loadCurrentUser();
  }

  bool get isLoading   => _isLoading;
  bool get isLoggedIn  => _user != null;
  String? get userEmail=> _user?.email;
  String? get gymCode  => _user?.gymId;
  String? get userId   => _user?.id;
  String? get error    => _error;
  String? get role     => _user?.role;
  bool get isAdmin     => role == 'admin';

  Future<void> _loadCurrentUser() async {
    _setLoading(true);
    try {
      _user = await _currentUC.execute();
    } catch (_) {
      _user = null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      _user = await _loginUC.execute(email, password);

      // Nach Login: ID-Token erneuern, damit Custom Claims verfügbar sind
      final fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.getIdToken(true);
      }

    } on fb_auth.FirebaseAuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register(
      String email, String password, String gymCode) async {
    _setLoading(true);
    _error = null;
    try {
      _user = await _registerUC.execute(email, password, gymCode);
      // Token-Refresh auch hier
      final fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.getIdToken(true);
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _logoutUC.execute();
      _user = null;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
