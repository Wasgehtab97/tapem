import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/drafts/session_draft_repository.dart';
import 'package:tapem/core/drafts/session_draft_repository_impl.dart';
import 'package:tapem/features/auth/domain/models/user_data.dart';
import 'package:tapem/features/auth/domain/repositories/auth_repository.dart';
import 'package:tapem/features/auth/domain/services/firebase_auth_manager.dart';
import 'package:tapem/features/auth/domain/usecases/check_username_available.dart';
import 'package:tapem/features/auth/domain/usecases/get_current_user.dart';
import 'package:tapem/features/auth/domain/usecases/login.dart';
import 'package:tapem/features/auth/domain/usecases/logout.dart';
import 'package:tapem/features/auth/domain/usecases/register.dart';
import 'package:tapem/features/auth/domain/usecases/reset_password.dart';
import 'package:tapem/features/auth/domain/usecases/set_avatar_key.dart';
import 'package:tapem/features/auth/domain/usecases/set_public_profile.dart';
import 'package:tapem/features/auth/domain/usecases/set_show_in_leaderboard.dart';
import 'package:tapem/features/auth/domain/usecases/set_username.dart';

class AuthProvider extends ChangeNotifier {
  final LoginUseCase _loginUC;
  final RegisterUseCase _registerUC;
  final LogoutUseCase _logoutUC;
  final GetCurrentUserUseCase _currentUC;
  final SetUsernameUseCase _setUsernameUC;
  final SetShowInLeaderboardUseCase _setShowInLbUC;
  final SetPublicProfileUseCase _setPublicProfileUC;
  final SetAvatarKeyUseCase _setAvatarKeyUC;
  final CheckUsernameAvailable _checkUsernameUC;
  final ResetPasswordUseCase _resetPasswordUC;
  final FirebaseAuthManager _authManager;
  final SessionDraftRepository _sessionDraftRepository;
  final Future<SharedPreferences> Function() _sharedPreferencesGetter;

  UserData? _user;
  bool _isLoading = false;
  String? _error;
  String? _selectedGymCode;

  AuthProvider._({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required GetCurrentUserUseCase currentUserUseCase,
    required SetUsernameUseCase setUsernameUseCase,
    required SetShowInLeaderboardUseCase setShowInLeaderboardUseCase,
    required SetPublicProfileUseCase setPublicProfileUseCase,
    required SetAvatarKeyUseCase setAvatarKeyUseCase,
    required CheckUsernameAvailable checkUsernameUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
    required FirebaseAuthManager authManager,
    required SessionDraftRepository sessionDraftRepository,
    required Future<SharedPreferences> Function() sharedPreferencesGetter,
  })  : _loginUC = loginUseCase,
        _registerUC = registerUseCase,
        _logoutUC = logoutUseCase,
        _currentUC = currentUserUseCase,
        _setUsernameUC = setUsernameUseCase,
        _setShowInLbUC = setShowInLeaderboardUseCase,
        _setPublicProfileUC = setPublicProfileUseCase,
        _setAvatarKeyUC = setAvatarKeyUseCase,
        _checkUsernameUC = checkUsernameUseCase,
        _resetPasswordUC = resetPasswordUseCase,
        _authManager = authManager,
        _sessionDraftRepository = sessionDraftRepository,
        _sharedPreferencesGetter = sharedPreferencesGetter {
    _loadCurrentUser();
  }

  factory AuthProvider({
    AuthRepository? repo,
    FirebaseAuthManager? authManager,
    SessionDraftRepository? sessionDraftRepository,
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
    SharedPreferences? sharedPreferences,
  }) {
    final resolvedAuthManager = authManager ?? DefaultFirebaseAuthManager();
    final resolvedSessionDraftRepo =
        sessionDraftRepository ?? SessionDraftRepositoryImpl();
    final prefsGetter = sharedPreferences != null
        ? (() => Future<SharedPreferences>.value(sharedPreferences))
        : (sharedPreferencesProvider ?? SharedPreferences.getInstance);
    return AuthProvider._(
      loginUseCase:
          LoginUseCase(repo: repo, authManager: resolvedAuthManager),
      registerUseCase:
          RegisterUseCase(repo: repo, authManager: resolvedAuthManager),
      logoutUseCase: LogoutUseCase(repo),
      currentUserUseCase: GetCurrentUserUseCase(repo),
      setUsernameUseCase: SetUsernameUseCase(repo),
      setShowInLeaderboardUseCase:
          SetShowInLeaderboardUseCase(repo),
      setPublicProfileUseCase: SetPublicProfileUseCase(repo),
      setAvatarKeyUseCase: SetAvatarKeyUseCase(repo),
      checkUsernameUseCase: CheckUsernameAvailable(repo),
      resetPasswordUseCase: ResetPasswordUseCase(repo),
      authManager: resolvedAuthManager,
      sessionDraftRepository: resolvedSessionDraftRepo,
      sharedPreferencesGetter: prefsGetter,
    );
  }

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get userEmail => _user?.email;
  String? get userName => _user?.userName;
  String get avatarKey => _user?.avatarKey ?? 'default';

  /// Liste der Gym-Codes, die diesem Nutzer zugeordnet sind
  List<String>? get gymCodes => _user?.gymCodes;

  /// Ausgewählter Gym-Code (wird in SharedPreferences gespeichert)
  String? get gymCode => _selectedGymCode;

  /// Eindeutige Nutzer-ID
  String? get userId => _user?.id;
  String? get role => _user?.role;
  bool get isAdmin => role == 'admin';
  DateTime? get createdAt => _user?.createdAt;

  /// Opt-out für Leaderboard
  bool? get showInLeaderboard => _user?.showInLeaderboard;
  bool? get publicProfile => _user?.publicProfile;

  String? get error => _error;

  Future<SharedPreferences?> _safeGetPreferences() async {
    try {
      return await _sharedPreferencesGetter()
          .timeout(const Duration(seconds: 2));
    } on TimeoutException catch (e, st) {
      debugPrint('AuthProvider: SharedPreferences timeout: $e');
      debugPrintStack(stackTrace: st);
    } catch (e, st) {
      debugPrint('AuthProvider: Failed to load SharedPreferences: $e');
      debugPrintStack(stackTrace: st);
    }
    return null;
  }

  Future<void> _loadCurrentUser() async {
    _setLoading(true);
    _error = null;
    try {
      final fbUser = _authManager.currentUser;
      if (fbUser != null) {
        Map<String, dynamic> claims = {};
        try {
          claims = await _authManager.getIdTokenClaims(fbUser);
        } on fb_auth.FirebaseAuthException catch (e) {
          _error = e.message;
          _user = null;
          return;
        } catch (e) {
          _error = e.toString();
          return;
        }
        final fetchedUser = await _currentUC.execute();
        if (fetchedUser != null) {
          var currentUser = fetchedUser;
          if (currentUser.publicProfile != currentUser.showInLeaderboard) {
            try {
              await _setPublicProfileUC.execute(
                  currentUser.id, currentUser.showInLeaderboard);
              currentUser = currentUser.copyWith(
                publicProfile: currentUser.showInLeaderboard,
              );
            } catch (e, st) {
              _error = e.toString();
              debugPrintStack(
                  label: 'AuthProvider._loadCurrentUser', stackTrace: st);
            }
          }
          _user = currentUser.copyWith(
            role: claims['role'] as String? ?? currentUser.role,
          );
          final prefs = await _safeGetPreferences();
          if (prefs != null) {
            final stored = prefs.getString('selectedGymCode');
            if (stored != null && currentUser.gymCodes.contains(stored)) {
              _selectedGymCode = stored;
            } else if (currentUser.gymCodes.isNotEmpty) {
              _selectedGymCode = currentUser.gymCodes.first;
              await prefs.setString('selectedGymCode', _selectedGymCode!);
            }
          }
        }
      } else {
        _user = null;
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      _error = e.message;
      _user = null;
    } catch (e) {
      _error = e.toString();
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
      final registeredUser =
          await _registerUC.execute(email, password, initialGymCode);
      await _loadCurrentUser();
      if (_user == null) {
        _user = registeredUser;
        if (registeredUser.gymCodes.isNotEmpty) {
          final prefs = await _safeGetPreferences();
          if (prefs != null) {
            _selectedGymCode = registeredUser.gymCodes.first;
            await prefs.setString('selectedGymCode', _selectedGymCode!);
          }
        }
        notifyListeners();
      }
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
      final prefs = await _safeGetPreferences();
      if (prefs != null) {
        await prefs.remove('selectedGymCode');
      }
      await _sessionDraftRepository.deleteAll();
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
        _error = 'username_taken';
        return false;
      }
      await _setUsernameUC.execute(_user!.id, username);
      _user = _user!.copyWith(userName: username);
      return true;
    } on FirebaseException catch (e) {
      _error = e.code;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> checkUsernameAvailable(String username) {
    return _checkUsernameUC.execute(username);
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

  Future<void> setPublicProfile(bool value) async {
    if (_user == null) return;
    _setLoading(true);
    _error = null;
    try {
      await _setPublicProfileUC.execute(_user!.id, value);
      _user = _user!.copyWith(publicProfile: value);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setAvatarKey(String key) async {
    if (_user == null) return;
    _setLoading(true);
    _error = null;
    final previous = _user!.avatarKey;
    _user = _user!.copyWith(avatarKey: key);
    notifyListeners();
    try {
      await _setAvatarKeyUC.execute(_user!.id, key);
    } catch (e) {
      _error = e.toString();
      _user = _user!.copyWith(avatarKey: previous);
      notifyListeners();
      rethrow;
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
    final prefs = await _safeGetPreferences();
    if (prefs != null) {
      await prefs.setString('selectedGymCode', code);
    }
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
