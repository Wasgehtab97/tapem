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
    : _loginUC = LoginUseCase(repo),
      _registerUC = RegisterUseCase(repo),
      _logoutUC = LogoutUseCase(repo),
      _currentUC = GetCurrentUserUseCase(repo) {
    _loadCurrentUser();
  }

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get userEmail => _user?.email;

  /// Liste der Gym-Codes, die diesem Nutzer zugeordnet sind
  List<String>? get gymCodes => _user?.gymCodes;

  /// Erster Gym-Code (für Single-Gym-Flow)
  String? get gymCode =>
      (_user?.gymCodes.isNotEmpty == true) ? _user!.gymCodes.first : null;

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
        final dto = await _currentUC.execute();
        if (dto != null) {
          _user = UserData(
            id: dto.userId,
            email: dto.email,
            gymCodes: dto.gymCodes,
            showInLeaderboard: dto.showInLeaderboard,
            role: claims['role'] as String? ?? dto.role,
            createdAt: dto.createdAt,
          );
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
      _setLoading(false);
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
