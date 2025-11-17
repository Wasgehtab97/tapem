import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/data/user_profile_service.dart';
import 'package:tapem/core/drafts/session_draft_repository.dart';
import 'package:tapem/core/drafts/session_draft_repository_impl.dart';
import 'package:tapem/core/providers/gym_scoped_resettable.dart';
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
import 'package:tapem/services/membership_service.dart';

typedef ActiveGymSetter = Future<void> Function(String gymId);
typedef AuthErrorLogger = void Function(
  Object error,
  StackTrace stackTrace, {
  String? context,
});

enum GymContextStatus {
  unknown,
  loading,
  missingSelection,
  ready,
}

abstract class GymContextState {
  GymContextStatus get gymContextStatus;

  String? get gymCode;
}

class AuthResult {
  final bool success;
  final bool requiresGymSelection;
  final bool missingMembership;
  final String? error;

  const AuthResult({
    required this.success,
    this.requiresGymSelection = false,
    this.missingMembership = false,
    this.error,
  });

  const AuthResult.success({
    bool requiresGymSelection = false,
    bool missingMembership = false,
  }) : this(
          success: true,
          requiresGymSelection: requiresGymSelection,
          missingMembership: missingMembership,
        );

  const AuthResult.failure({String? error})
      : this(success: false, error: error);
}

class GymSwitchResult {
  final bool success;
  final bool requiresReauthentication;
  final bool requiresMembershipAction;
  final String? errorCode;

  const GymSwitchResult._({
    required this.success,
    this.requiresReauthentication = false,
    this.requiresMembershipAction = false,
    this.errorCode,
  });

  const GymSwitchResult.success() : this._(success: true);

  const GymSwitchResult.failure({
    String? errorCode,
    bool requiresReauthentication = false,
    bool requiresMembershipAction = false,
  }) : this._(
          success: false,
          errorCode: errorCode,
          requiresReauthentication: requiresReauthentication,
          requiresMembershipAction: requiresMembershipAction,
        );
}

class AuthProvider extends ChangeNotifier implements GymContextState {
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
  final MembershipService _membershipService;
  final ActiveGymSetter _setActiveGym;
  final GymScopedStateController? _gymScopedStateController;
  final FirebaseFirestore _firestore;
  final AuthErrorLogger? _errorLogger;

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
    required MembershipService membershipService,
    required ActiveGymSetter setActiveGym,
    GymScopedStateController? gymScopedStateController,
    FirebaseFirestore? firestore,
    AuthErrorLogger? errorLogger,
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
        _membershipService = membershipService,
        _setActiveGym = setActiveGym,
        _gymScopedStateController = gymScopedStateController,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _errorLogger = errorLogger {
    _loadCurrentUser();
  }

  factory AuthProvider({
    AuthRepository? repo,
    FirebaseAuthManager? authManager,
    SessionDraftRepository? sessionDraftRepository,
    MembershipService? membershipService,
    ActiveGymSetter? setActiveGym,
    GymScopedStateController? gymScopedStateController,
    FirebaseFirestore? firestore,
    AuthErrorLogger? errorLogger,
  }) {
    final resolvedAuthManager = authManager ?? DefaultFirebaseAuthManager();
    final resolvedSessionDraftRepo =
        sessionDraftRepository ?? SessionDraftRepositoryImpl();
    final resolvedMembership = membershipService ?? FirestoreMembershipService();
    final resolvedSetActiveGym = setActiveGym ?? UserProfileService.setActiveGym;
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
      membershipService: resolvedMembership,
      setActiveGym: resolvedSetActiveGym,
      gymScopedStateController: gymScopedStateController,
      firestore: firestore,
      errorLogger: errorLogger,
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
  @override
  String? get gymCode => _selectedGymCode;

  @override
  GymContextStatus get gymContextStatus {
    if (!isLoggedIn) {
      return _isLoading ? GymContextStatus.loading : GymContextStatus.unknown;
    }
    return (_selectedGymCode?.isNotEmpty ?? false)
        ? GymContextStatus.ready
        : GymContextStatus.missingSelection;
  }

  /// Eindeutige Nutzer-ID
  String? get userId => _user?.id;
  String? get role => _user?.role;
  bool get isAdmin => role == 'admin';
  DateTime? get createdAt => _user?.createdAt;

  /// Opt-out für Leaderboard
  bool? get showInLeaderboard => _user?.showInLeaderboard;
  bool? get publicProfile => _user?.publicProfile;

  String? get error => _error;

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
              _logError(e, st, context: '_loadCurrentUser');
            }
          }
          _user = currentUser.copyWith(
            role: claims['role'] as String? ?? currentUser.role,
          );
          await _syncActiveGymSelection(
            currentUser: _user!,
            fbUser: fbUser,
            claims: claims,
          );
        }
      } else {
        _user = null;
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      _error = e.message;
      _user = null;
    } catch (e, st) {
      _error = e.toString();
      _logError(e, st, context: '_loadCurrentUser');
    } finally {
      _setLoading(false);
    }
  }

  AuthResult _resolveAuthResult() {
    final user = _user;
    if (user == null) {
      return AuthResult.failure(error: _error);
    }

    final requiresGymSelection =
        gymContextStatus == GymContextStatus.missingSelection;
    final missingMembership = user.gymCodes.isEmpty;

    return AuthResult.success(
      requiresGymSelection: requiresGymSelection,
      missingMembership: missingMembership,
    );
  }

  Future<AuthResult> login(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      await _loginUC.execute(email, password);
      await _loadCurrentUser();
      return _resolveAuthResult();
    } catch (e) {
      _error = (e is fb_auth.FirebaseAuthException) ? e.message : e.toString();
      _user = null;
      _setLoading(false);
      return AuthResult.failure(error: _error);
    }
  }

  Future<AuthResult> register(
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
          final prefs = await SharedPreferences.getInstance();
          _selectedGymCode = registeredUser.gymCodes.first;
          await prefs.setString('selectedGymCode', _selectedGymCode!);
        }
        notifyListeners();
      }
      return _resolveAuthResult();
    } catch (e) {
      _error = (e is fb_auth.FirebaseAuthException) ? e.message : e.toString();
      _user = null;
      _setLoading(false);
      return AuthResult.failure(error: _error);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _logoutUC.execute();
    } finally {
      _gymScopedStateController?.resetGymScopedState();
      _user = null;
      _selectedGymCode = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selectedGymCode');
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
  Future<GymSwitchResult> switchGym(String gymId) async {
    if (_user == null) {
      _error = 'missing_user';
      notifyListeners();
      return const GymSwitchResult.failure(
        errorCode: 'missing_user',
        requiresReauthentication: true,
      );
    }
    if (!_user!.gymCodes.contains(gymId)) {
      _error = 'invalid_gym_code';
      notifyListeners();
      return const GymSwitchResult.failure(errorCode: 'invalid_gym_code');
    }
    final fbUser = _authManager.currentUser;
    if (fbUser == null) {
      _error = 'missing_firebase_user';
      notifyListeners();
      return const GymSwitchResult.failure(
        errorCode: 'missing_firebase_user',
        requiresReauthentication: true,
      );
    }

    if (_selectedGymCode == gymId) {
      return const GymSwitchResult.success();
    }

    _setLoading(true);
    _error = null;
    final previousGymCode = _selectedGymCode;
    var activeGymUpdated = false;
    SharedPreferences? prefs;
    try {
      await _membershipService.ensureMembership(gymId, fbUser.uid);
      await _setActiveGym(gymId);
      activeGymUpdated = true;
      await _authManager.forceRefreshIdToken(fbUser);
      prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedGymCode', gymId);
      _selectedGymCode = gymId;
      _gymScopedStateController?.resetGymScopedState();
      return const GymSwitchResult.success();
    } catch (e, st) {
      final membershipFailure = !activeGymUpdated;
      _error = e is fb_auth.FirebaseAuthException
          ? e.message ?? e.code
          : (membershipFailure ? 'membership_sync_failed' : e.toString());
      if (activeGymUpdated) {
        try {
          if (previousGymCode != null) {
            await _setActiveGym(previousGymCode);
            await _authManager.forceRefreshIdToken(fbUser);
            prefs ??= await SharedPreferences.getInstance();
            await prefs.setString('selectedGymCode', previousGymCode);
          } else {
            prefs ??= await SharedPreferences.getInstance();
            await prefs.remove('selectedGymCode');
          }
          _selectedGymCode = previousGymCode;
        } catch (restoreError, restoreStack) {
          _logError(
            restoreError,
            restoreStack,
            context: 'switchGym.restore',
          );
        }
      }
      _logError(e, st, context: 'switchGym');
      return GymSwitchResult.failure(
        errorCode: _error,
        requiresMembershipAction: membershipFailure,
      );
    } finally {
      _setLoading(false);
    }
  }

  @Deprecated('Use switchGym instead')
  Future<GymSwitchResult> selectGym(String code) {
    return switchGym(code);
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  Future<void> _syncActiveGymSelection({
    required UserData currentUser,
    required fb_auth.User fbUser,
    required Map<String, dynamic> claims,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('selectedGymCode');
      final doc = await _firestore.collection('users').doc(currentUser.id).get();
      final data = doc.data();
      final firestoreActiveGym = data?['activeGymId'];
      String? normalizedFirestoreGym =
          (firestoreActiveGym is String &&
                  currentUser.gymCodes.contains(firestoreActiveGym))
              ? firestoreActiveGym
              : null;
      final normalizedStoredGym =
          (stored != null && currentUser.gymCodes.contains(stored))
              ? stored
              : null;
      final claimGym = claims['gymId'];
      final normalizedClaimGym =
          (claimGym is String && currentUser.gymCodes.contains(claimGym))
              ? claimGym
              : null;

      String? resolvedGym = normalizedFirestoreGym ??
          normalizedStoredGym ??
          normalizedClaimGym ??
          (currentUser.gymCodes.isNotEmpty ? currentUser.gymCodes.first : null);

      if (resolvedGym == null) {
        _selectedGymCode = null;
        await prefs.remove('selectedGymCode');
        return;
      }

      try {
        await _membershipService.ensureMembership(resolvedGym, fbUser.uid);
      } catch (error, stackTrace) {
        _error = 'membership_sync_failed';
        _selectedGymCode = null;
        await prefs.remove('selectedGymCode');
        _logError(
          error,
          stackTrace,
          context: 'activeGymSync.ensureMembership',
        );
        return;
      }

      final inconsistencies = <String, String?>{};
      if (normalizedFirestoreGym != null &&
          normalizedFirestoreGym != resolvedGym) {
        inconsistencies['firestore'] = normalizedFirestoreGym;
      }
      if (normalizedStoredGym != null &&
          normalizedStoredGym != resolvedGym) {
        inconsistencies['sharedPreferences'] = normalizedStoredGym;
      }
      if (normalizedClaimGym != null && normalizedClaimGym != resolvedGym) {
        inconsistencies['claims'] = normalizedClaimGym;
      }

      if (inconsistencies.isNotEmpty) {
        final payload = <String, dynamic>{
          'resolved': resolvedGym,
          'firestore': normalizedFirestoreGym,
          'sharedPreferences': normalizedStoredGym,
          'claims': normalizedClaimGym,
          'inconsistencies': inconsistencies,
        };
        debugPrint('AuthProvider.activeGymSync: ${jsonEncode(payload)}');
      }

      if (normalizedStoredGym != resolvedGym) {
        await prefs.setString('selectedGymCode', resolvedGym);
      }

      var shouldRefreshClaims = false;
      if (normalizedFirestoreGym != resolvedGym) {
        await _setActiveGym(resolvedGym);
        shouldRefreshClaims = true;
      } else if (normalizedClaimGym != resolvedGym) {
        shouldRefreshClaims = true;
      }

      if (shouldRefreshClaims) {
        await _authManager.forceRefreshIdToken(fbUser);
      }

      _selectedGymCode = resolvedGym;
    } catch (e, st) {
      _logError(e, st, context: 'activeGymSync');
    }
  }

  void _logError(Object error, StackTrace stackTrace, {String? context}) {
    final logger = _errorLogger;
    if (logger != null) {
      logger(error, stackTrace, context: context);
      return;
    }
    final label = context != null ? 'AuthProvider.$context' : 'AuthProvider';
    debugPrint('$label: $error');
    debugPrintStack(label: label, stackTrace: stackTrace);
  }
}
