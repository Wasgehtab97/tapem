import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tapem/features/auth/domain/models/user_data.dart';
import 'package:tapem/features/auth/domain/usecases/get_current_user.dart';
import 'package:tapem/features/auth/domain/usecases/login.dart';
import 'package:tapem/features/auth/domain/usecases/logout.dart';
import 'package:tapem/features/auth/domain/usecases/register.dart';

class AuthProvider extends ChangeNotifier {
  static const _prefsKey = 'activeGymCode';

  final LoginUseCase _loginUC;
  final RegisterUseCase _registerUC;
  final LogoutUseCase _logoutUC;
  final GetCurrentUserUseCase _currentUC;

  UserData? _user;
  String? _activeGymCode;
  bool _isLoading = false;
  String? _error;

  AuthProvider({AuthRepositoryImpl? repo})
    : _loginUC = LoginUseCase(repo),
      _registerUC = RegisterUseCase(repo),
      _logoutUC = LogoutUseCase(repo),
      _currentUC = GetCurrentUserUseCase(repo) {
    _loadCurrentUser();
  }

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get userEmail => _user?.email;

  List<String>? get gymCodes => _user?.gymCodes;

  /// Gibt den aktuell gespeicherten Gym-Code zurück oder den ersten
  String? get gymCode {
    if (_activeGymCode != null &&
        _user?.gymCodes.contains(_activeGymCode) == true) {
      return _activeGymCode;
    }
    if (_user?.gymCodes.isNotEmpty == true) {
      return _user!.gymCodes.first;
    }
    return null;
  }

  /// Eindeutige Nutzer-ID
  String? get userId => _user?.id;
  String? get role => _user?.role;
  bool get isAdmin => role == 'admin';
  bool? get showInLeaderboard => _user?.showInLeaderboard;
  String? get error => _error;

  /// Nutzer wählt ein Gym → persistieren
  Future<void> setGymCode(String code) async {
    _activeGymCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);
    notifyListeners();
  }

  Future<void> _loadCurrentUser() async {
    _setLoading(true);
    _error = null;
    try {
      final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        await fbUser.reload();
        final claims = (await fbUser.getIdTokenResult(true)).claims ?? {};
        final dto = await _currentUC.execute();
        if (dto != null) {
          _user = UserData(
            id: dto.id, // <-- dto.id statt dto.userId
            email: dto.email,
            gymCodes: dto.gymCodes,
            showInLeaderboard: dto.showInLeaderboard,
            role: claims['role'] as String? ?? dto.role,
            createdAt: dto.createdAt,
          );
        }
        // gespeicherten Gym-Code laden
        final prefs = await SharedPreferences.getInstance();
        final saved = prefs.getString(_prefsKey);
        if (saved != null && _user?.gymCodes.contains(saved) == true) {
          _activeGymCode = saved;
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

  Future<void> register(String email, String password, String gymCode) async {
    _setLoading(true);
    _error = null;
    try {
      await _registerUC.execute(email, password, gymCode);
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
      _activeGymCode = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } finally {
      _user = null;
      _setLoading(false);
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
