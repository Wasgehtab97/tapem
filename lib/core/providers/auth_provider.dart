import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tapem/features/auth/domain/models/user_data.dart';
import 'package:tapem/features/auth/domain/usecases/get_current_user.dart';
import 'package:tapem/features/auth/domain/usecases/login.dart';
import 'package:tapem/features/auth/domain/usecases/logout.dart';
import 'package:tapem/features/auth/domain/usecases/register.dart';
import 'package:tapem/features/auth/domain/usecases/set_username.dart';
import 'package:tapem/features/auth/domain/usecases/check_username_available.dart';
import 'package:tapem/features/auth/domain/usecases/reset_password.dart';
import 'package:tapem/features/auth/domain/usecases/set_show_in_leaderboard.dart';
import 'package:tapem/core/drafts/session_draft_repository_impl.dart';

class AuthProvider extends ChangeNotifier {
  final LoginUseCase _loginUC;
  final RegisterUseCase _registerUC;
  final LogoutUseCase _logoutUC;
  final GetCurrentUserUseCase _currentUC;
  final SetUsernameUseCase _setUsernameUC;
  final SetShowInLeaderboardUseCase _setShowInLbUC;
  final CheckUsernameAvailable _checkUsernameUC;
  final ResetPasswordUseCase _resetPasswordUC;

  UserData? _user;
  bool _isLoading = false;
  String? _error;
  String? _selectedGymCode;

  AuthProvider({AuthRepositoryImpl? repo})
    : _loginUC = LoginUseCase(repo),
      _registerUC = RegisterUseCase(repo),
      _logoutUC = LogoutUseCase(repo),
      _currentUC = GetCurrentUserUseCase(repo),
      _setUsernameUC = SetUsernameUseCase(repo),
      _setShowInLbUC = SetShowInLeaderboardUseCase(repo),
      _checkUsernameUC = CheckUsernameAvailable(repo),
      _resetPasswordUC = ResetPasswordUseCase(repo) {
    _loadCurrentUser();
  }

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get userEmail => _user?.email;
  String? get userName => _user?.userName;

  /// Liste der Gym-Codes, die diesem Nutzer zugeordnet sind
  List<String>? get gymCodes => _user?.gymCodes;

  /// Ausgewählter Gym-Code (wird in SharedPreferences gespeichert)
  String? get gymCode => _selectedGymCode;

  /// Eindeutige Nutzer-ID
  String? get userId => _user?.id;
  String? get role => _user?.role;
  bool get isAdmin => role == 'admin';

  /// Opt-out für Leaderboard
  bool? get showInLeaderboard => _user?.showInLeaderboard;

  String? get error => _error;

  Future<void> _loadCurrentUser() async {
    _setLoading(true);
    _error = null;
    try {
      final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        await fbUser.reload();
        final claims = (await fbUser.getIdTokenResult(true)).claims ?? {};
        final user = await _currentUC.execute();
        if (user != null) {
          _user = UserData(
            id: user.id,
            email: user.email,
            userName: user.userName,
            gymCodes: user.gymCodes,
            showInLeaderboard: user.showInLeaderboard,
            role: claims['role'] as String? ?? user.role,
            createdAt: user.createdAt,
          );
          final prefs = await SharedPreferences.getInstance();
          final stored = prefs.getString('selectedGymCode');
          if (stored != null && user.gymCodes.contains(stored)) {
            _selectedGymCode = stored;
          } else if (user.gymCodes.isNotEmpty) {
            _selectedGymCode = user.gymCodes.first;
            await prefs.setString('selectedGymCode', _selectedGymCode!);
          }
        }
      }
    } catch (e) {
      _error = e.toString();
      _user = null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      await _loginUC.execute(email, password);
      await _loadCurrentUser();
    } catch (e) {
      _error = (e is fb_auth.FirebaseAuthException) ? e.message : e.toString();
      _user = null;
      _setLoading(false);
    }
  }

  Future<void> register(
    String email,
    String password,
    String initialGymCode,
  ) async {
    _setLoading(true);
    _error = null;
    try {
      await _registerUC.execute(email, password, initialGymCode);
      await _loadCurrentUser();
    } catch (e) {
      _error = (e is fb_auth.FirebaseAuthException) ? e.message : e.toString();
      _user = null;
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _logoutUC.execute();
    } finally {
      _user = null;
      _selectedGymCode = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selectedGymCode');
      await SessionDraftRepositoryImpl().deleteAll();
      _setLoading(false);
    }
  }

  Future<bool> setUsername(String username) async {
    if (_user == null) return false;
    _setLoading(true);
    _error = null;
    try {
      final available = await _checkUsernameUC.execute(username);
      if (!available) {
        _error = 'Username already taken';
        return false;
      }
      await _setUsernameUC.execute(_user!.id, username);
      _user = _user!.copyWith(userName: username);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setShowInLeaderboard(bool value) async {
    if (_user == null) return;
    _setLoading(true);
    _error = null;
    try {
      await _setShowInLbUC.execute(_user!.id, value);
      _user = _user!.copyWith(showInLeaderboard: value);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword(String email) async {
    _setLoading(true);
    _error = null;
    try {
      await _resetPasswordUC.execute(email);
    } catch (e) {
      _error = (e is fb_auth.FirebaseAuthException) ? e.message : e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Wählt ein Gym aus und speichert die Auswahl persistent
  Future<void> selectGym(String code) async {
    if (_user == null || !_user!.gymCodes.contains(code)) return;
    _selectedGymCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedGymCode', code);
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
