import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/gym_scoped_resettable.dart';
import 'package:tapem/features/auth/domain/models/user_data.dart';
import 'package:tapem/services/membership_service.dart';

import 'helpers/fakes.dart';
import 'helpers/fake_firestore.dart';

Future<void> _pumpEventQueue() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthProvider', () {
    late FakeSessionDraftRepository sessionRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sessionRepo = FakeSessionDraftRepository();
    });

    AuthProvider buildProvider({
      required FakeAuthRepository repo,
      FakeFirebaseAuthManager? authManager,
      MembershipService? membershipService,
      Future<void> Function(String gymId)? onSetActiveGym,
      GymScopedStateController? gymStateController,
      FakeFirebaseFirestore? firestore,
      AuthErrorLogger? errorLogger,
    }) {
      return AuthProvider(
        repo: repo,
        authManager: authManager ?? FakeFirebaseAuthManager(),
        sessionDraftRepository: sessionRepo,
        membershipService: membershipService ?? _FakeMembershipService(),
        setActiveGym: onSetActiveGym ?? (_) async {},
        gymScopedStateController:
            gymStateController ?? GymScopedStateController(),
        firestore: firestore,
        errorLogger: errorLogger,
      );
    }

    test('initial load fetches user, syncs profile flags and persists gym', () async {
      var storedUser = UserData(
        id: 'uid',
        email: 'user@example.com',
        gymCodes: const ['gym1', 'gym2'],
        showInLeaderboard: true,
        publicProfile: false,
        role: 'member',
        createdAt: DateTime(2023, 4, 1),
      );
      var publicProfileUpdated = false;
      final repo = FakeAuthRepository(
        onGetCurrentUser: () async => storedUser,
        onSetPublicProfile: (id, value) async {
          storedUser = storedUser.copyWith(publicProfile: value);
          publicProfileUpdated = true;
        },
        onSetShowInLeaderboard: (id, value) async {
          storedUser = storedUser.copyWith(showInLeaderboard: value);
        },
        onSetAvatarKey: (id, key) async {
          storedUser = storedUser.copyWith(avatarKey: key);
        },
        onSetUsername: (id, username) async {
          storedUser = storedUser.copyWith(userName: username);
        },
        onIsUsernameAvailable: (_) async => true,
        onSendPasswordResetEmail: (_) async {},
        onLogout: () async {},
      );
      final firebaseUser = FakeFirebaseUser(uid: storedUser.id, email: storedUser.email, claims: {'role': 'coach'});
      final manager = FakeFirebaseAuthManager(
        currentUser: firebaseUser,
        onGetClaims: (_) async => {'role': 'coach'},
      );

      final provider = buildProvider(
        repo: repo,
        authManager: manager,
      );
      await _pumpEventQueue();

      expect(provider.isLoggedIn, isTrue);
      expect(provider.role, 'coach');
      expect(provider.publicProfile, isTrue);
      expect(publicProfileUpdated, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selectedGymCode'), 'gym1');
    });

    test('initial load ensures membership for resolved gym selection', () async {
      SharedPreferences.setMockInitialValues({});
      final firestore = FakeFirebaseFirestore();
      await firestore.seedDocument('users/uid', {'activeGymId': 'gym1'});
      final membership = _FakeMembershipService();
      var storedUser = UserData(
        id: 'uid',
        email: 'user@example.com',
        gymCodes: const ['gym1', 'gym2'],
        showInLeaderboard: true,
        publicProfile: true,
        role: 'member',
        createdAt: DateTime(2023, 4, 1),
      );
      final repo = FakeAuthRepository(
        onGetCurrentUser: () async => storedUser,
        onSetPublicProfile: (_, __) async {},
        onSetShowInLeaderboard: (_, __) async {},
        onSetAvatarKey: (_, __) async {},
        onSetUsername: (_, __) async {},
        onIsUsernameAvailable: (_) async => true,
        onSendPasswordResetEmail: (_) async {},
        onLogout: () async {},
      );
      final manager = FakeFirebaseAuthManager(
        currentUser:
            FakeFirebaseUser(uid: storedUser.id, email: storedUser.email),
        onGetClaims: (_) async => {'role': 'member', 'gymId': 'gym1'},
      );

      final provider = buildProvider(
        repo: repo,
        authManager: manager,
        membershipService: membership,
        firestore: firestore,
      );
      await _pumpEventQueue();

      expect(provider.gymCode, 'gym1');
      expect(membership.ensureCalls, 1);
      expect(membership.lastGymId, 'gym1');
      expect(membership.lastUid, storedUser.id);
    });

    test('initial load does not auto select gym when multi gym selection missing',
        () async {
      SharedPreferences.setMockInitialValues({});
      var storedUser = UserData(
        id: 'uid',
        email: 'user@example.com',
        gymCodes: const ['gym1', 'gym2'],
        showInLeaderboard: true,
        publicProfile: true,
        role: 'member',
        createdAt: DateTime(2023, 4, 1),
      );
      final repo = FakeAuthRepository(
        onGetCurrentUser: () async => storedUser,
        onSetPublicProfile: (_, __) async {},
        onSetShowInLeaderboard: (_, __) async {},
        onSetAvatarKey: (_, __) async {},
        onSetUsername: (_, __) async {},
        onIsUsernameAvailable: (_) async => true,
        onSendPasswordResetEmail: (_) async {},
        onLogout: () async {},
      );
      final membership = _FakeMembershipService();
      final manager = FakeFirebaseAuthManager(
        currentUser: FakeFirebaseUser(uid: storedUser.id, email: storedUser.email),
        onGetClaims: (_) async => <String, dynamic>{},
      );

      final provider = buildProvider(
        repo: repo,
        authManager: manager,
        membershipService: membership,
      );
      await _pumpEventQueue();

      expect(provider.gymCode, isNull);
      expect(provider.gymContextStatus, GymContextStatus.missingSelection);
      expect(membership.ensureCalls, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selectedGymCode'), isNull);
    });

    test('login ensures membership when gym selection is synced', () async {
      SharedPreferences.setMockInitialValues({});
      var storedUser = UserData(
        id: 'uid',
        email: 'user@example.com',
        gymCodes: const ['gym1'],
        showInLeaderboard: true,
        publicProfile: true,
        role: 'member',
        createdAt: DateTime(2023, 4, 1),
      );
      final repo = FakeAuthRepository(
        onLogin: (email, _) async => storedUser.copyWith(email: email),
        onGetCurrentUser: () async => storedUser,
        onSetPublicProfile: (_, __) async {},
        onSetShowInLeaderboard: (_, __) async {},
        onSetAvatarKey: (_, __) async {},
        onSetUsername: (_, __) async {},
        onIsUsernameAvailable: (_) async => true,
        onSendPasswordResetEmail: (_) async {},
        onLogout: () async {},
      );
      final membership = _FakeMembershipService();
      final manager = FakeFirebaseAuthManager(
        onGetClaims: (_) async => {'role': 'member', 'gymId': 'gym1'},
      );
      final provider = buildProvider(
        repo: repo,
        authManager: manager,
        membershipService: membership,
      );
      await _pumpEventQueue();
      expect(membership.ensureCalls, 0);

      manager.currentUserSetter =
          FakeFirebaseUser(uid: storedUser.id, email: storedUser.email);

      final result = await provider.login('login@example.com', 'secret');
      await _pumpEventQueue();

      expect(result.success, isTrue);
      expect(membership.ensureCalls, 1);
      expect(membership.lastGymId, 'gym1');
      expect(membership.lastUid, storedUser.id);
    });

    test('login result flags missing gym selection for multi gym users', () async {
      SharedPreferences.setMockInitialValues({});
      var storedUser = UserData(
        id: 'uid',
        email: 'user@example.com',
        gymCodes: const ['gym1', 'gym2'],
        showInLeaderboard: true,
        publicProfile: true,
        role: 'member',
        createdAt: DateTime(2023, 4, 1),
      );
      final repo = FakeAuthRepository(
        onLogin: (email, _) async => storedUser.copyWith(email: email),
        onGetCurrentUser: () async => storedUser,
        onSetPublicProfile: (_, __) async {},
        onSetShowInLeaderboard: (_, __) async {},
        onSetAvatarKey: (_, __) async {},
        onSetUsername: (_, __) async {},
        onIsUsernameAvailable: (_) async => true,
        onSendPasswordResetEmail: (_) async {},
        onLogout: () async {},
      );
      final membership = _FakeMembershipService();
      final manager = FakeFirebaseAuthManager(
        onGetClaims: (_) async => <String, dynamic>{},
      );

      final provider = buildProvider(
        repo: repo,
        authManager: manager,
        membershipService: membership,
      );
      await _pumpEventQueue();
      expect(membership.ensureCalls, 0);

      manager.currentUserSetter =
          FakeFirebaseUser(uid: storedUser.id, email: storedUser.email);

      final result = await provider.login('login@example.com', 'secret');
      await _pumpEventQueue();

      expect(result.success, isTrue);
      expect(result.requiresGymSelection, isTrue);
      expect(result.gymContextStatus, GymContextStatus.missingSelection);
      expect(provider.gymCode, isNull);
      expect(membership.ensureCalls, 0);
    });

    test('initial load falls back when membership sync fails', () async {
      SharedPreferences.setMockInitialValues({'selectedGymCode': 'gym1'});
      final firestore = FakeFirebaseFirestore();
      await firestore.seedDocument('users/uid', {'activeGymId': 'gym1'});
      final loggedContexts = <String?>[];
      final membership = _FakeMembershipService(
        onEnsure: (_, __) => Future<void>.error(Exception('fail ensure')),
      );
      var storedUser = UserData(
        id: 'uid',
        email: 'user@example.com',
        gymCodes: const ['gym1', 'gym2'],
        showInLeaderboard: true,
        publicProfile: true,
        role: 'member',
        createdAt: DateTime(2023, 4, 1),
      );
      final repo = FakeAuthRepository(
        onGetCurrentUser: () async => storedUser,
        onSetPublicProfile: (_, __) async {},
        onSetShowInLeaderboard: (_, __) async {},
        onSetAvatarKey: (_, __) async {},
        onSetUsername: (_, __) async {},
        onIsUsernameAvailable: (_) async => true,
        onSendPasswordResetEmail: (_) async {},
        onLogout: () async {},
      );
      final manager = FakeFirebaseAuthManager(
        currentUser:
            FakeFirebaseUser(uid: storedUser.id, email: storedUser.email),
        onGetClaims: (_) async => {'role': 'member', 'gymId': 'gym1'},
      );
      final provider = buildProvider(
        repo: repo,
        authManager: manager,
        membershipService: membership,
        firestore: firestore,
        errorLogger: (error, stackTrace, {context}) {
          loggedContexts.add(context);
        },
      );
      await _pumpEventQueue();

      expect(provider.gymCode, isNull);
      expect(provider.gymContextStatus, GymContextStatus.missingSelection);
      expect(provider.error, 'membership_sync_failed');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selectedGymCode'), isNull);
      expect(loggedContexts, contains('activeGymSync.ensureMembership'));
    });

    test('initial load syncs active gym when firestore differs from prefs',
        () async {
      SharedPreferences.setMockInitialValues({'selectedGymCode': 'gym1'});
      final firestore = FakeFirebaseFirestore();
      await firestore.seedDocument('users/uid', {'activeGymId': 'gym2'});
      var storedUser = UserData(
        id: 'uid',
        email: 'user@example.com',
        gymCodes: const ['gym1', 'gym2'],
        showInLeaderboard: true,
        publicProfile: true,
        role: 'member',
        createdAt: DateTime(2023, 4, 1),
      );
      final repo = FakeAuthRepository(
        onGetCurrentUser: () async => storedUser,
        onSetPublicProfile: (_, __) async {},
        onSetShowInLeaderboard: (_, __) async {},
        onSetAvatarKey: (_, __) async {},
        onSetUsername: (_, __) async {},
        onIsUsernameAvailable: (_) async => true,
        onSendPasswordResetEmail: (_) async {},
        onLogout: () async {},
      );
      final activeGymCalls = <String>[];
      final manager = FakeFirebaseAuthManager(
        currentUser:
            FakeFirebaseUser(uid: storedUser.id, email: storedUser.email),
        onGetClaims: (_) async => {'role': 'member', 'gymId': 'gym1'},
      );
      final provider = buildProvider(
        repo: repo,
        authManager: manager,
        onSetActiveGym: (gymId) async => activeGymCalls.add(gymId),
        firestore: firestore,
      );
      await _pumpEventQueue();

      expect(provider.gymCode, 'gym2');
      expect(activeGymCalls, isEmpty);
      expect(manager.forceRefreshCalls, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selectedGymCode'), 'gym2');
    });

    test('initial load writes missing firestore active gym from stored pref',
        () async {
      SharedPreferences.setMockInitialValues({'selectedGymCode': 'gym1'});
      final firestore = FakeFirebaseFirestore();
      await firestore.seedDocument('users/uid', {});
      var storedUser = UserData(
        id: 'uid',
        email: 'user@example.com',
        gymCodes: const ['gym1', 'gym2'],
        showInLeaderboard: true,
        publicProfile: true,
        role: 'member',
        createdAt: DateTime(2023, 4, 1),
      );
      final repo = FakeAuthRepository(
        onGetCurrentUser: () async => storedUser,
        onSetPublicProfile: (_, __) async {},
        onSetShowInLeaderboard: (_, __) async {},
        onSetAvatarKey: (_, __) async {},
        onSetUsername: (_, __) async {},
        onIsUsernameAvailable: (_) async => true,
        onSendPasswordResetEmail: (_) async {},
        onLogout: () async {},
      );
      final activeGymCalls = <String>[];
      final manager = FakeFirebaseAuthManager(
        currentUser:
            FakeFirebaseUser(uid: storedUser.id, email: storedUser.email),
        onGetClaims: (_) async => {'role': 'member', 'gymId': 'gym2'},
      );
      final provider = buildProvider(
        repo: repo,
        authManager: manager,
        onSetActiveGym: (gymId) async => activeGymCalls.add(gymId),
        firestore: firestore,
      );
      await _pumpEventQueue();

      expect(provider.gymCode, 'gym1');
      expect(activeGymCalls, ['gym1']);
      expect(manager.forceRefreshCalls, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selectedGymCode'), 'gym1');
    });

    test('login updates user and clears error on success', () async {
      var storedUser = UserData(
        id: 'uid',
        email: 'user@example.com',
        gymCodes: const ['gym1'],
        showInLeaderboard: true,
        publicProfile: true,
        role: 'member',
        createdAt: DateTime(2023, 4, 1),
      );
      final repo = FakeAuthRepository(
        onLogin: (email, password) async {
          storedUser = storedUser.copyWith(email: email);
          return storedUser;
        },
        onGetCurrentUser: () async => storedUser,
        onSetPublicProfile: (id, value) async {
          storedUser = storedUser.copyWith(publicProfile: value);
        },
        onSetShowInLeaderboard: (id, value) async {
          storedUser = storedUser.copyWith(showInLeaderboard: value);
        },
        onSetAvatarKey: (id, key) async {
          storedUser = storedUser.copyWith(avatarKey: key);
        },
        onSetUsername: (id, username) async {
          storedUser = storedUser.copyWith(userName: username);
        },
        onIsUsernameAvailable: (_) async => true,
        onSendPasswordResetEmail: (_) async {},
        onLogout: () async {},
      );
      final manager = FakeFirebaseAuthManager(
        currentUser: FakeFirebaseUser(uid: storedUser.id, email: storedUser.email),
      );
      final provider = buildProvider(
        repo: repo,
        authManager: manager,
      );
      await _pumpEventQueue();

      final result = await provider.login('login@example.com', 'secret');
      await _pumpEventQueue();

      expect(result.success, isTrue);
      expect(provider.userEmail, 'login@example.com');
      expect(provider.error, isNull);
    });

    test('login stores error on failure', () async {
      final repo = FakeAuthRepository(
        onLogin: (_, __) => Future<UserData>.error(Exception('invalid')),
        onGetCurrentUser: () async => null,
        onSetPublicProfile: (_, __) async {},
        onSetShowInLeaderboard: (_, __) async {},
        onSetAvatarKey: (_, __) async {},
        onSetUsername: (_, __) async {},
        onIsUsernameAvailable: (_) async => true,
        onSendPasswordResetEmail: (_) async {},
        onLogout: () async {},
      );
      final provider = buildProvider(
        repo: repo,
        authManager: FakeFirebaseAuthManager(),
      );
      await _pumpEventQueue();

      final result = await provider.login('user@example.com', 'wrong');
      expect(result.success, isFalse);
      expect(provider.error, contains('invalid'));
      expect(provider.isLoading, isFalse);
    });

    test('register updates user on success and handles failure', () async {
      var storedUser = UserData(
        id: 'uid',
        email: 'user@example.com',
        gymCodes: const ['gym1'],
        showInLeaderboard: true,
        publicProfile: true,
        role: 'member',
        createdAt: DateTime(2023, 4, 1),
      );
      final successRepo = FakeAuthRepository(
        onRegister: (email, password, gym) async {
          storedUser = storedUser.copyWith(email: email);
          return storedUser;
        },
        onGetCurrentUser: () async => storedUser,
        onSetPublicProfile: (id, value) async {
          storedUser = storedUser.copyWith(publicProfile: value);
        },
        onSetShowInLeaderboard: (id, value) async {
          storedUser = storedUser.copyWith(showInLeaderboard: value);
        },
        onSetAvatarKey: (id, key) async {
          storedUser = storedUser.copyWith(avatarKey: key);
        },
        onSetUsername: (id, username) async {
          storedUser = storedUser.copyWith(userName: username);
        },
        onIsUsernameAvailable: (_) async => true,
        onSendPasswordResetEmail: (_) async {},
        onLogout: () async {},
      );
      final provider = buildProvider(
        repo: successRepo,
        authManager: FakeFirebaseAuthManager(),
      );
      await _pumpEventQueue();

      final registerResult =
          await provider.register('new@example.com', 'secret', 'gym');
      await _pumpEventQueue();
      expect(registerResult.success, isTrue);
      expect(provider.userEmail, 'new@example.com');

      final failingRepo = FakeAuthRepository(
        onRegister: (_, __, ___) => Future<UserData>.error(Exception('fail')),
        onGetCurrentUser: () async => null,
        onSetPublicProfile: (_, __) async {},
        onSetShowInLeaderboard: (_, __) async {},
        onSetAvatarKey: (_, __) async {},
        onSetUsername: (_, __) async {},
        onIsUsernameAvailable: (_) async => true,
        onSendPasswordResetEmail: (_) async {},
        onLogout: () async {},
      );
      final provider2 = buildProvider(
        repo: failingRepo,
        authManager: FakeFirebaseAuthManager(),
      );
      await _pumpEventQueue();

      final failingResult =
          await provider2.register('user@example.com', 'secret', 'gym');
      expect(failingResult.success, isFalse);
      expect(provider2.error, contains('fail'));
    });

    test('logout clears auth state but keeps session drafts for recovery', () async {
      var storedUser = UserData(
        id: 'uid',
        email: 'user@example.com',
        gymCodes: const ['gym1'],
        showInLeaderboard: true,
        publicProfile: true,
        role: 'member',
        createdAt: DateTime(2023, 4, 1),
      );
      final repo = FakeAuthRepository(
        onGetCurrentUser: () async => storedUser,
        onLogout: () async {},
        onSetPublicProfile: (_, __) async {},
        onSetShowInLeaderboard: (_, __) async {},
        onSetAvatarKey: (_, __) async {},
        onSetUsername: (_, __) async {},
        onIsUsernameAvailable: (_) async => true,
        onSendPasswordResetEmail: (_) async {},
      );
      final provider = buildProvider(
        repo: repo,
        authManager: FakeFirebaseAuthManager(
            currentUser: FakeFirebaseUser(uid: 'uid', email: 'user@example.com')),
      );
      await _pumpEventQueue();

      await provider.logout();
      await _pumpEventQueue();

      expect(provider.isLoggedIn, isFalse);
      expect(
        sessionRepo.deleted.any((entry) => entry.startsWith('expired-')),
        isTrue,
      );
      expect(sessionRepo.deleted, isNot(contains('all')));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selectedGymCode'), isNull);
    });

    test('setUsername succeeds, handles taken name and firebase errors', () async {
      var storedUser = UserData(
        id: 'uid',
        email: 'user@example.com',
        gymCodes: const ['gym1'],
        showInLeaderboard: true,
        publicProfile: true,
        role: 'member',
        createdAt: DateTime(2023, 4, 1),
      );
      final repo = FakeAuthRepository(
        onGetCurrentUser: () async => storedUser,
        onSetUsername: (id, username) async {
          storedUser = storedUser.copyWith(userName: username);
        },
        onIsUsernameAvailable: (_) async => true,
        onSetPublicProfile: (_, __) async {},
        onSetShowInLeaderboard: (_, __) async {},
        onSetAvatarKey: (_, __) async {},
        onSendPasswordResetEmail: (_) async {},
        onLogout: () async {},
      );
      final provider = buildProvider(
        repo: repo,
        authManager: FakeFirebaseAuthManager(
            currentUser: FakeFirebaseUser(uid: 'uid', email: 'user@example.com')),
      );
      await _pumpEventQueue();

      final success = await provider.setUsername('NewName');
      expect(success, isTrue);
      expect(provider.userName, 'NewName');

      final takenRepo = FakeAuthRepository(
        onGetCurrentUser: () async => storedUser,
        onSetPublicProfile: (_, __) async {},
        onSetShowInLeaderboard: (_, __) async {},
        onSetAvatarKey: (_, __) async {},
        onSetUsername: (_, __) => Future<void>.error(
          FirebaseException(plugin: 'firestore', code: 'username_taken'),
        ),
        onSendPasswordResetEmail: (_) async {},
        onLogout: () async {},
      );
      final providerTaken = buildProvider(
        repo: takenRepo,
        authManager: FakeFirebaseAuthManager(
            currentUser: FakeFirebaseUser(uid: 'uid', email: 'user@example.com')),
      );
      await _pumpEventQueue();

      final taken = await providerTaken.setUsername('Other');
      expect(taken, isFalse);
      expect(providerTaken.error, 'username_taken');

      final errorRepo = FakeAuthRepository(
        onGetCurrentUser: () async => storedUser,
        onIsUsernameAvailable: (_) async => true,
        onSetUsername: (_, __) => Future<void>.error(
          FirebaseException(plugin: 'firestore', code: 'failed'),
        ),
        onSetPublicProfile: (_, __) async {},
        onSetShowInLeaderboard: (_, __) async {},
        onSetAvatarKey: (_, __) async {},
        onSendPasswordResetEmail: (_) async {},
        onLogout: () async {},
      );
      final providerError = buildProvider(
        repo: errorRepo,
        authManager: FakeFirebaseAuthManager(
            currentUser: FakeFirebaseUser(uid: 'uid', email: 'user@example.com')),
      );
      await _pumpEventQueue();

      final result = await providerError.setUsername('Crash');
      expect(result, isFalse);
      expect(providerError.error, 'failed');
    });

    test('setShowInLeaderboard and setPublicProfile update values and handle errors', () async {
      var storedUser = UserData(
        id: 'uid',
        email: 'user@example.com',
        gymCodes: const ['gym1'],
        showInLeaderboard: true,
        publicProfile: true,
        role: 'member',
        createdAt: DateTime(2023, 4, 1),
      );
      final repo = FakeAuthRepository(
        onGetCurrentUser: () async => storedUser,
        onSetShowInLeaderboard: (_, value) async {
          storedUser = storedUser.copyWith(showInLeaderboard: value);
        },
        onSetPublicProfile: (_, value) async {
          storedUser = storedUser.copyWith(publicProfile: value);
        },
        onSetAvatarKey: (_, __) async {},
        onSetUsername: (_, __) async {},
        onIsUsernameAvailable: (_) async => true,
        onSendPasswordResetEmail: (_) async {},
        onLogout: () async {},
      );
      final provider = buildProvider(
        repo: repo,
        authManager: FakeFirebaseAuthManager(
            currentUser: FakeFirebaseUser(uid: 'uid', email: 'user@example.com')),
      );
      await _pumpEventQueue();

      await provider.setShowInLeaderboard(false);
      expect(provider.showInLeaderboard, isFalse);

      await provider.setPublicProfile(false);
      expect(provider.publicProfile, isFalse);

      final errorRepo = FakeAuthRepository(
        onGetCurrentUser: () async => storedUser,
        onSetShowInLeaderboard: (_, __) => Future<void>.error(Exception('fail')),
        onSetPublicProfile: (_, __) => Future<void>.error(Exception('fail')),
        onSetAvatarKey: (_, __) async {},
        onSetUsername: (_, __) async {},
        onIsUsernameAvailable: (_) async => true,
        onSendPasswordResetEmail: (_) async {},
        onLogout: () async {},
      );
      final providerError = buildProvider(
        repo: errorRepo,
        authManager: FakeFirebaseAuthManager(
            currentUser: FakeFirebaseUser(uid: 'uid', email: 'user@example.com')),
      );
      await _pumpEventQueue();

      await providerError.setShowInLeaderboard(false);
      expect(providerError.error, contains('fail'));

      await providerError.setPublicProfile(false);
      expect(providerError.error, contains('fail'));
    });

    test('setAvatarKey performs optimistic update and rolls back on error', () async {
      var storedUser = UserData(
        id: 'uid',
        email: 'user@example.com',
        gymCodes: const ['gym1'],
        showInLeaderboard: true,
        publicProfile: true,
        role: 'member',
        createdAt: DateTime(2023, 4, 1),
        avatarKey: 'old',
      );
      final repo = FakeAuthRepository(
        onGetCurrentUser: () async => storedUser,
        onSetAvatarKey: (_, key) async {
          storedUser = storedUser.copyWith(avatarKey: key);
        },
        onSetPublicProfile: (_, __) async {},
        onSetShowInLeaderboard: (_, __) async {},
        onSetUsername: (_, __) async {},
        onIsUsernameAvailable: (_) async => true,
        onSendPasswordResetEmail: (_) async {},
        onLogout: () async {},
      );
      final provider = buildProvider(
        repo: repo,
        authManager: FakeFirebaseAuthManager(
            currentUser: FakeFirebaseUser(uid: 'uid', email: 'user@example.com')),
      );
      await _pumpEventQueue();

      await provider.setAvatarKey('new');
      expect(provider.avatarKey, 'new');

      final failingRepo = FakeAuthRepository(
        onGetCurrentUser: () async =>
            UserData(
              id: 'uid',
              email: 'user@example.com',
              gymCodes: const ['gym1'],
              showInLeaderboard: true,
              publicProfile: true,
              role: 'member',
              createdAt: DateTime(2023, 4, 1),
              avatarKey: 'old',
            ),
        onSetAvatarKey: (_, __) => Future<void>.error(Exception('fail')),
        onSetPublicProfile: (_, __) async {},
        onSetShowInLeaderboard: (_, __) async {},
        onSetUsername: (_, __) async {},
        onIsUsernameAvailable: (_) async => true,
        onSendPasswordResetEmail: (_) async {},
        onLogout: () async {},
      );
      final providerFail = buildProvider(
        repo: failingRepo,
        authManager: FakeFirebaseAuthManager(
            currentUser: FakeFirebaseUser(uid: 'uid', email: 'user@example.com')),
      );
      await _pumpEventQueue();

      await expectLater(
        providerFail.setAvatarKey('new'),
        throwsA(isA<Exception>()),
      );
      await _pumpEventQueue();
      expect(providerFail.avatarKey, 'old');
      expect(providerFail.error, contains('fail'));
    });

    test('resetPassword forwards to repository and stores errors', () async {
      final repo = FakeAuthRepository(
        onGetCurrentUser: () async => null,
        onSendPasswordResetEmail: (_) async {},
        onSetPublicProfile: (_, __) async {},
        onSetShowInLeaderboard: (_, __) async {},
        onSetAvatarKey: (_, __) async {},
        onSetUsername: (_, __) async {},
        onIsUsernameAvailable: (_) async => true,
        onLogout: () async {},
      );
      final provider = buildProvider(
        repo: repo,
        authManager: FakeFirebaseAuthManager(),
      );
      await _pumpEventQueue();

      await provider.resetPassword('user@example.com');
      expect(provider.error, isNull);

      final failingRepo = FakeAuthRepository(
        onGetCurrentUser: () async => null,
        onSendPasswordResetEmail: (_) => Future<void>.error(
          fb_auth.FirebaseAuthException(code: 'error', message: 'bad'),
        ),
        onSetPublicProfile: (_, __) async {},
        onSetShowInLeaderboard: (_, __) async {},
        onSetAvatarKey: (_, __) async {},
        onSetUsername: (_, __) async {},
        onIsUsernameAvailable: (_) async => true,
        onLogout: () async {},
      );
      final providerFail = buildProvider(
        repo: failingRepo,
        authManager: FakeFirebaseAuthManager(),
      );
      await _pumpEventQueue();

      await providerFail.resetPassword('user@example.com');
      expect(providerFail.error, 'bad');
    });

    test('switchGym ensures membership, updates profile and persists gym code', () async {
      var storedUser = UserData(
        id: 'uid',
        email: 'user@example.com',
        gymCodes: const ['gym1', 'gym2'],
        showInLeaderboard: true,
        publicProfile: true,
        role: 'member',
        createdAt: DateTime(2023, 4, 1),
      );
      final repo = FakeAuthRepository(
        onGetCurrentUser: () async => storedUser,
        onSetPublicProfile: (_, __) async {},
        onSetShowInLeaderboard: (_, __) async {},
        onSetAvatarKey: (_, __) async {},
        onSetUsername: (_, __) async {},
        onIsUsernameAvailable: (_) async => true,
        onSendPasswordResetEmail: (_) async {},
        onLogout: () async {},
      );
      final membership = _FakeMembershipService();
      final activeGymCalls = <String>[];
      final manager = FakeFirebaseAuthManager(
        currentUser: FakeFirebaseUser(uid: storedUser.id, email: storedUser.email),
      );
      final resetController = _RecordingGymScopedStateController();
      final provider = buildProvider(
        repo: repo,
        authManager: manager,
        membershipService: membership,
        onSetActiveGym: (gymId) async => activeGymCalls.add(gymId),
        gymStateController: resetController,
      );
      await _pumpEventQueue();

      final result = await provider.switchGym('gym2');

      expect(result.success, isTrue);
      expect(provider.gymCode, 'gym2');
      expect(membership.ensureCalls, 1);
      expect(membership.lastGymId, 'gym2');
      expect(membership.lastUid, storedUser.id);
      expect(manager.forceRefreshCalls, 1);
      expect(activeGymCalls, ['gym2']);
      expect(resetController.resetCalls, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selectedGymCode'), 'gym2');
    });

    test('switchGym reports membership errors and keeps previous selection', () async {
      final storedUser = UserData(
        id: 'uid',
        email: 'user@example.com',
        gymCodes: const ['gym1', 'gym2'],
        showInLeaderboard: true,
        publicProfile: true,
        role: 'member',
        createdAt: DateTime(2023, 4, 1),
      );
      final repo = FakeAuthRepository(
        onGetCurrentUser: () async => storedUser,
        onSetPublicProfile: (_, __) async {},
        onSetShowInLeaderboard: (_, __) async {},
        onSetAvatarKey: (_, __) async {},
        onSetUsername: (_, __) async {},
        onIsUsernameAvailable: (_) async => true,
        onSendPasswordResetEmail: (_) async {},
        onLogout: () async {},
      );
      final membership = _FakeMembershipService(
        onEnsure: (_, __) => Future<void>.error(Exception('membership failed')),
      );
      final manager = FakeFirebaseAuthManager(
        currentUser: FakeFirebaseUser(uid: storedUser.id, email: storedUser.email),
      );
      var activeGymCalls = 0;
      final provider = buildProvider(
        repo: repo,
        authManager: manager,
        membershipService: membership,
        onSetActiveGym: (_) async => activeGymCalls++,
      );
      await _pumpEventQueue();

      final result = await provider.switchGym('gym2');

      expect(result.success, isFalse);
      expect(result.errorCode, 'membership_sync_failed');
      expect(result.requiresMembershipAction, isTrue);
      expect(provider.error, 'membership_sync_failed');
      expect(provider.gymCode, 'gym1');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selectedGymCode'), 'gym1');
      expect(activeGymCalls, 0);
    });

    test('switchGym keeps gym state intact when setActiveGym fails', () async {
      final storedUser = UserData(
        id: 'uid',
        email: 'user@example.com',
        gymCodes: const ['gym1', 'gym2'],
        showInLeaderboard: true,
        publicProfile: true,
        role: 'member',
        createdAt: DateTime(2023, 4, 1),
      );
      final repo = FakeAuthRepository(
        onGetCurrentUser: () async => storedUser,
        onSetPublicProfile: (_, __) async {},
        onSetShowInLeaderboard: (_, __) async {},
        onSetAvatarKey: (_, __) async {},
        onSetUsername: (_, __) async {},
        onIsUsernameAvailable: (_) async => true,
        onSendPasswordResetEmail: (_) async {},
        onLogout: () async {},
      );
      final manager = FakeFirebaseAuthManager(
        currentUser:
            FakeFirebaseUser(uid: storedUser.id, email: storedUser.email),
      );
      final activeGymCalls = <String>[];
      final resetController = _RecordingGymScopedStateController();
      final provider = buildProvider(
        repo: repo,
        authManager: manager,
        onSetActiveGym: (gymId) async {
          activeGymCalls.add(gymId);
          if (gymId == 'gym2') {
            throw Exception('setActiveGym failed');
          }
        },
        gymStateController: resetController,
      );
      await _pumpEventQueue();

      final result = await provider.switchGym('gym2');

      expect(result.success, isFalse);
      expect(result.errorCode, contains('setActiveGym failed'));
      expect(result.requiresMembershipAction, isFalse);
      expect(provider.gymCode, 'gym1');
      expect(provider.error, contains('setActiveGym failed'));
      expect(resetController.resetCalls, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selectedGymCode'), 'gym1');
      expect(activeGymCalls, ['gym2']);
    });

    test('switchGym returns reauth requirement when firebase user missing',
        () async {
      final storedUser = UserData(
        id: 'uid',
        email: 'user@example.com',
        gymCodes: const ['gym1', 'gym2'],
        showInLeaderboard: true,
        publicProfile: true,
        role: 'member',
        createdAt: DateTime(2023, 4, 1),
      );
      final repo = FakeAuthRepository(
        onGetCurrentUser: () async => storedUser,
        onSetPublicProfile: (_, __) async {},
        onSetShowInLeaderboard: (_, __) async {},
        onSetAvatarKey: (_, __) async {},
        onSetUsername: (_, __) async {},
        onIsUsernameAvailable: (_) async => true,
        onSendPasswordResetEmail: (_) async {},
        onLogout: () async {},
      );
      final provider = buildProvider(
        repo: repo,
        authManager: FakeFirebaseAuthManager(),
      );
      await _pumpEventQueue();

      final result = await provider.switchGym('gym2');

      expect(result.success, isFalse);
      expect(result.requiresReauthentication, isTrue);
      expect(result.errorCode, 'missing_firebase_user');
    });

    test('switchGym returns validation error when gym code unknown', () async {
      final storedUser = UserData(
        id: 'uid',
        email: 'user@example.com',
        gymCodes: const ['gym1'],
        showInLeaderboard: true,
        publicProfile: true,
        role: 'member',
        createdAt: DateTime(2023, 4, 1),
      );
      final repo = FakeAuthRepository(
        onGetCurrentUser: () async => storedUser,
        onSetPublicProfile: (_, __) async {},
        onSetShowInLeaderboard: (_, __) async {},
        onSetAvatarKey: (_, __) async {},
        onSetUsername: (_, __) async {},
        onIsUsernameAvailable: (_) async => true,
        onSendPasswordResetEmail: (_) async {},
        onLogout: () async {},
      );
      final manager = FakeFirebaseAuthManager(
        currentUser: FakeFirebaseUser(uid: storedUser.id, email: storedUser.email),
      );
      final provider = buildProvider(
        repo: repo,
        authManager: manager,
      );
      await _pumpEventQueue();

      final result = await provider.switchGym('unknown');

      expect(result.success, isFalse);
      expect(result.errorCode, 'invalid_gym_code');
      expect(result.requiresReauthentication, isFalse);
      expect(result.requiresMembershipAction, isFalse);
    });
  });
}

class _RecordingGymScopedStateController extends GymScopedStateController {
  int resetCalls = 0;

  @override
  void resetGymScopedState() {
    resetCalls++;
    super.resetGymScopedState();
  }
}

class _FakeMembershipService implements MembershipService {
  _FakeMembershipService({this.onEnsure});

  final Future<void> Function(String gymId, String uid)? onEnsure;
  int ensureCalls = 0;
  String? lastGymId;
  String? lastUid;

  @override
  Future<void> ensureMembership(String gymId, String uid) async {
    ensureCalls++;
    lastGymId = gymId;
    lastUid = uid;
    final handler = onEnsure;
    if (handler != null) {
      await handler(gymId, uid);
    }
  }
}
