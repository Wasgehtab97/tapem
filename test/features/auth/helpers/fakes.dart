import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/drafts/session_draft.dart';
import 'package:tapem/core/drafts/session_draft_repository.dart';
import 'package:tapem/features/auth/domain/models/user_data.dart';
import 'package:tapem/features/auth/domain/repositories/auth_repository.dart';
import 'package:tapem/features/auth/domain/services/firebase_auth_manager.dart';

import 'fake_base.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    Future<UserData> Function(String email, String password)? onLogin,
    Future<UserData> Function(String email, String password, String gymId)?
        onRegister,
    Future<void> Function()? onLogout,
    Future<UserData?> Function()? onGetCurrentUser,
    Future<void> Function(String userId, String username)? onSetUsername,
    Future<void> Function(String userId, bool value)? onSetShowInLeaderboard,
    Future<void> Function(String userId, bool value)? onSetPublicProfile,
    Future<void> Function(String userId, String avatarKey)? onSetAvatarKey,
    Future<bool> Function(String username)? onIsUsernameAvailable,
    Future<void> Function(String email)? onSendPasswordResetEmail,
  })  : _onLogin = onLogin,
        _onRegister = onRegister,
        _onLogout = onLogout,
        _onGetCurrentUser = onGetCurrentUser,
        _onSetUsername = onSetUsername,
        _onSetShowInLeaderboard = onSetShowInLeaderboard,
        _onSetPublicProfile = onSetPublicProfile,
        _onSetAvatarKey = onSetAvatarKey,
        _onIsUsernameAvailable = onIsUsernameAvailable,
        _onSendPasswordResetEmail = onSendPasswordResetEmail;

  final Future<UserData> Function(String email, String password)? _onLogin;
  final Future<UserData> Function(String email, String password, String gymId)?
      _onRegister;
  final Future<void> Function()? _onLogout;
  final Future<UserData?> Function()? _onGetCurrentUser;
  final Future<void> Function(String userId, String username)? _onSetUsername;
  final Future<void> Function(String userId, bool value)?
      _onSetShowInLeaderboard;
  final Future<void> Function(String userId, bool value)? _onSetPublicProfile;
  final Future<void> Function(String userId, String avatarKey)? _onSetAvatarKey;
  final Future<bool> Function(String username)? _onIsUsernameAvailable;
  final Future<void> Function(String email)? _onSendPasswordResetEmail;

  int loginCalls = 0;
  int registerCalls = 0;
  int logoutCalls = 0;
  int getCurrentUserCalls = 0;
  int setUsernameCalls = 0;
  int setShowInLeaderboardCalls = 0;
  int setPublicProfileCalls = 0;
  int setAvatarKeyCalls = 0;
  int isUsernameAvailableCalls = 0;
  int sendPasswordResetEmailCalls = 0;

  @override
  Future<UserData> login(String email, String password) {
    loginCalls++;
    final handler = _onLogin;
    if (handler != null) {
      return handler(email, password);
    }
    throw UnimplementedError('login handler not provided');
  }

  @override
  Future<UserData> register(String email, String password, String gymId) {
    registerCalls++;
    final handler = _onRegister;
    if (handler != null) {
      return handler(email, password, gymId);
    }
    throw UnimplementedError('register handler not provided');
  }

  @override
  Future<void> logout() {
    logoutCalls++;
    final handler = _onLogout;
    if (handler != null) {
      return handler();
    }
    throw UnimplementedError('logout handler not provided');
  }

  @override
  Future<UserData?> getCurrentUser() {
    getCurrentUserCalls++;
    final handler = _onGetCurrentUser;
    if (handler != null) {
      return handler();
    }
    throw UnimplementedError('getCurrentUser handler not provided');
  }

  @override
  Future<void> setUsername(String userId, String username) {
    setUsernameCalls++;
    final handler = _onSetUsername;
    if (handler != null) {
      return handler(userId, username);
    }
    throw UnimplementedError('setUsername handler not provided');
  }

  @override
  Future<void> setShowInLeaderboard(String userId, bool value) {
    setShowInLeaderboardCalls++;
    final handler = _onSetShowInLeaderboard;
    if (handler != null) {
      return handler(userId, value);
    }
    throw UnimplementedError('setShowInLeaderboard handler not provided');
  }

  @override
  Future<void> setPublicProfile(String userId, bool value) {
    setPublicProfileCalls++;
    final handler = _onSetPublicProfile;
    if (handler != null) {
      return handler(userId, value);
    }
    throw UnimplementedError('setPublicProfile handler not provided');
  }

  @override
  Future<void> setAvatarKey(String userId, String avatarKey) {
    setAvatarKeyCalls++;
    final handler = _onSetAvatarKey;
    if (handler != null) {
      return handler(userId, avatarKey);
    }
    throw UnimplementedError('setAvatarKey handler not provided');
  }

  @override
  Future<bool> isUsernameAvailable(String username) {
    isUsernameAvailableCalls++;
    final handler = _onIsUsernameAvailable;
    if (handler != null) {
      return handler(username);
    }
    throw UnimplementedError('isUsernameAvailable handler not provided');
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    sendPasswordResetEmailCalls++;
    final handler = _onSendPasswordResetEmail;
    if (handler != null) {
      return handler(email);
    }
    throw UnimplementedError('sendPasswordResetEmail handler not provided');
  }
}

Future<SharedPreferences> Function() createInMemorySharedPreferences(
    [Map<String, Object> initialValues = const {}]) {
  SharedPreferences.setMockInitialValues(initialValues);
  final prefsFuture = SharedPreferences.getInstance();
  return () => prefsFuture;
}

class FakeFirebaseAuthManager implements FirebaseAuthManager {
  FakeFirebaseAuthManager({
    fb_auth.User? currentUser,
    Future<void> Function(fb_auth.User user)? onReload,
    Future<void> Function(fb_auth.User user)? onForceRefresh,
    Future<Map<String, dynamic>> Function(fb_auth.User user)? onGetClaims,
  })  : _currentUser = currentUser,
        _onReload = onReload,
        _onForceRefresh = onForceRefresh,
        _onGetClaims = onGetClaims;

  fb_auth.User? _currentUser;
  final Future<void> Function(fb_auth.User user)? _onReload;
  final Future<void> Function(fb_auth.User user)? _onForceRefresh;
  final Future<Map<String, dynamic>> Function(fb_auth.User user)? _onGetClaims;

  int reloadCalls = 0;
  int forceRefreshCalls = 0;
  int claimsCalls = 0;

  set currentUserSetter(fb_auth.User? user) => _currentUser = user;

  @override
  fb_auth.User? get currentUser => _currentUser;

  @override
  Future<void> reloadUser(fb_auth.User user) {
    reloadCalls++;
    final handler = _onReload;
    if (handler != null) {
      return handler(user);
    }
    return Future.value();
  }

  @override
  Future<void> forceRefreshIdToken(fb_auth.User user) {
    forceRefreshCalls++;
    final handler = _onForceRefresh;
    if (handler != null) {
      return handler(user);
    }
    return Future.value();
  }

  @override
  Future<Map<String, dynamic>> getIdTokenClaims(fb_auth.User user) {
    claimsCalls++;
    final handler = _onGetClaims;
    if (handler != null) {
      return handler(user);
    }
    return Future.value(const {});
  }
}

class FakeFirebaseAuth extends Fake implements fb_auth.FirebaseAuth {
  FakeFirebaseAuth({fb_auth.User? currentUser}) : _currentUser = currentUser;

  fb_auth.User? _currentUser;
  final Map<String, _StoredUser> _users = <String, _StoredUser>{};
  bool signOutCalled = false;
  bool passwordResetCalled = false;
  String? lastPasswordResetEmail;
  Object? signInError;
  Object? registerError;
  Object? confirmResetError;
  bool confirmPasswordResetCalled = false;
  String? lastConfirmCode;
  String? lastConfirmPassword;

  void addUser({
    required String email,
    required String password,
    required FakeFirebaseUser user,
  }) {
    _users[email] = _StoredUser(password: password, user: user);
    _currentUser = user;
  }

  @override
  fb_auth.User? get currentUser => _currentUser;

  @override
  Future<fb_auth.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final error = signInError;
    if (error != null) {
      throw error;
    }
    final entry = _users[email];
    if (entry == null || entry.password != password) {
      throw fb_auth.FirebaseAuthException(
        code: 'invalid-credentials',
        message: 'Invalid credentials',
      );
    }
    _currentUser = entry.user;
    return FakeUserCredential(entry.user);
  }

  @override
  Future<fb_auth.UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final error = registerError;
    if (error != null) {
      throw error;
    }
    final user = FakeFirebaseUser(uid: email, email: email);
    _users[email] = _StoredUser(password: password, user: user);
    _currentUser = user;
    return FakeUserCredential(user);
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    _currentUser = null;
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    fb_auth.ActionCodeSettings? actionCodeSettings,
  }) async {
    passwordResetCalled = true;
    lastPasswordResetEmail = email;
  }

  @override
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    final error = confirmResetError;
    if (error != null) {
      throw error;
    }
    confirmPasswordResetCalled = true;
    lastConfirmCode = code;
    lastConfirmPassword = newPassword;
  }

}

class FakeFirebaseUser extends Fake implements fb_auth.User {
  FakeFirebaseUser({
    required this.uid,
    this.email,
    Map<String, dynamic>? claims,
  }) : _claims = claims ?? const <String, dynamic>{};

  @override
  final String uid;
  @override
  final String? email;

  int reloadCount = 0;
  int tokenRequests = 0;
  Map<String, dynamic> _claims;

  set claims(Map<String, dynamic> value) => _claims = value;

  @override
  Future<void> reload() async {
    reloadCount += 1;
  }

  @override
  Future<String> getIdToken([bool forceRefresh = false]) async {
    tokenRequests += forceRefresh ? 2 : 1;
    return 'token-$uid';
  }

  @override
  Future<fb_auth.IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async {
    tokenRequests += forceRefresh ? 2 : 1;
    return FakeIdTokenResult(_claims);
  }

}

class FakeIdTokenResult extends Fake implements fb_auth.IdTokenResult {
  FakeIdTokenResult(this.claimsMap);

  final Map<String, dynamic> claimsMap;

  @override
  Map<String, dynamic>? get claims => claimsMap;

}

class FakeUserCredential extends Fake implements fb_auth.UserCredential {
  FakeUserCredential(this._user);

  final fb_auth.User _user;

  @override
  fb_auth.User? get user => _user;

}

class FakeSessionDraftRepository implements SessionDraftRepository {
  final Map<String, SessionDraft> drafts = <String, SessionDraft>{};
  final List<String> deleted = <String>[];

  @override
  Future<SessionDraft?> get(String key) async => drafts[key];

  @override
  Future<Map<String, SessionDraft>> getAll() async => Map<String, SessionDraft>.from(drafts);

  @override
  Future<void> put(String key, SessionDraft draft) async {
    drafts[key] = draft;
  }

  @override
  Future<void> delete(String key) async {
    drafts.remove(key);
    deleted.add(key);
  }

  @override
  Future<void> deleteExpired(int nowMs) async {
    deleted.add('expired-$nowMs');
  }

  @override
  Future<void> deleteAll() async {
    drafts.clear();
    deleted.add('all');
  }
}

class _StoredUser {
  _StoredUser({required this.password, required this.user});

  final String password;
  final FakeFirebaseUser user;
}
