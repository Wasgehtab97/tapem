import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/drafts/session_draft_repository.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/auth/domain/models/user_data.dart';
import 'package:tapem/features/auth/domain/repositories/auth_repository.dart';
import 'package:tapem/features/auth/domain/services/firebase_auth_manager.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockFirebaseAuthManager extends Mock implements FirebaseAuthManager {}

class MockSessionDraftRepository extends Mock
    implements SessionDraftRepository {}

class MockFirebaseUser extends Mock implements fb_auth.User {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthProvider unit tests', () {
    late MockAuthRepository authRepository;
    late MockFirebaseAuthManager authManager;
    late MockSessionDraftRepository draftRepository;
    late MockFirebaseUser firebaseUser;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object?>{});
      authRepository = MockAuthRepository();
      authManager = MockFirebaseAuthManager();
      draftRepository = MockSessionDraftRepository();
      firebaseUser = MockFirebaseUser();

      when(() => draftRepository.deleteAll()).thenAnswer((_) async {});
    });

    UserData buildUser({
      String role = 'member',
      List<String> gymCodes = const ['G1', 'G2'],
      bool showInLeaderboard = true,
      bool publicProfile = true,
    }) {
      return UserData(
        id: 'uid-123',
        email: 'user@example.com',
        userName: 'tester',
        gymCodes: gymCodes,
        showInLeaderboard: showInLeaderboard,
        publicProfile: publicProfile,
        role: role,
        createdAt: DateTime(2024, 1, 1),
      );
    }

    Future<AuthProvider> createProvider({
      fb_auth.User? currentUser,
      Map<String, dynamic>? claims,
      UserData? currentUserData,
    }) async {
      when(() => authManager.currentUser).thenReturn(currentUser);
      if (currentUser != null) {
        when(() => authManager.getIdTokenClaims(currentUser))
            .thenAnswer((_) async => claims ?? <String, dynamic>{});
      }
      when(() => authRepository.getCurrentUser())
          .thenAnswer((_) async => currentUserData);

      final provider = AuthProvider(
        repo: authRepository,
        authManager: authManager,
        sessionDraftRepository: draftRepository,
      );
      await pumpEventQueue();
      return provider;
    }

    test('login success updates state and persists gym code', () async {
      final userData = buildUser();
      fb_auth.User? currentUser;
      when(() => authManager.currentUser).thenAnswer((_) => currentUser);
      when(() => authRepository.getCurrentUser())
          .thenAnswer((_) async => null);
      when(() => authRepository.login(any(), any()))
          .thenAnswer((_) async => userData);
      when(() => authManager.getIdTokenClaims(firebaseUser))
          .thenAnswer((_) async => <String, dynamic>{'role': 'coach'});
      when(() => authManager.reloadUser(firebaseUser))
          .thenAnswer((_) async {});
      when(() => authManager.forceRefreshIdToken(firebaseUser))
          .thenAnswer((_) async {});

      final provider = AuthProvider(
        repo: authRepository,
        authManager: authManager,
        sessionDraftRepository: draftRepository,
      );
      await pumpEventQueue();

      currentUser = firebaseUser;
      when(() => authRepository.getCurrentUser())
          .thenAnswer((_) async => userData);

      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.login('user@example.com', 'secret');
      await pumpEventQueue();

      expect(provider.userId, userData.id);
      expect(provider.userEmail, userData.email);
      expect(provider.role, 'coach');
      expect(provider.gymCode, 'G1');
      expect(provider.isLoggedIn, isTrue);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selectedGymCode'), 'G1');
      expect(notifications, greaterThan(0));

      verify(() => authManager.reloadUser(firebaseUser)).called(1);
      verify(() => authManager.forceRefreshIdToken(firebaseUser)).called(1);
    });

    test('login failure surfaces error and clears user state', () async {
      when(() => authManager.currentUser).thenReturn(null);
      when(() => authRepository.getCurrentUser())
          .thenAnswer((_) async => null);
      when(() => authRepository.login(any(), any()))
          .thenThrow(Exception('login failed'));

      final provider = AuthProvider(
        repo: authRepository,
        authManager: authManager,
        sessionDraftRepository: draftRepository,
      );
      await pumpEventQueue();

      await provider.login('user@example.com', 'wrong');

      expect(provider.error, contains('login failed'));
      expect(provider.isLoggedIn, isFalse);
      expect(provider.userId, isNull);
      expect(provider.isLoading, isFalse);
      verifyNever(() => authManager.reloadUser(firebaseUser));
    });

    test('logout clears session and persisted data', () async {
      SharedPreferences.setMockInitialValues(<String, Object?>{
        'selectedGymCode': 'G2',
      });
      when(() => authManager.currentUser).thenReturn(firebaseUser);
      when(() => authManager.getIdTokenClaims(firebaseUser))
          .thenAnswer((_) async => <String, dynamic>{});
      final userData = buildUser();
      when(() => authRepository.getCurrentUser())
          .thenAnswer((_) async => userData);
      when(() => authRepository.logout()).thenAnswer((_) async {});

      final provider = AuthProvider(
        repo: authRepository,
        authManager: authManager,
        sessionDraftRepository: draftRepository,
      );
      await pumpEventQueue();

      expect(provider.isLoggedIn, isTrue);
      expect(provider.gymCode, 'G2');

      await provider.logout();

      expect(provider.isLoggedIn, isFalse);
      expect(provider.gymCode, isNull);
      expect(provider.isLoading, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selectedGymCode'), isNull);
      verify(() => authRepository.logout()).called(1);
      verify(() => draftRepository.deleteAll()).called(1);
    });

    test('loads role from custom claims when current user exists', () async {
      when(() => authManager.currentUser).thenReturn(firebaseUser);
      when(() => authManager.getIdTokenClaims(firebaseUser))
          .thenAnswer((_) async => <String, dynamic>{'role': 'admin'});
      final userData = buildUser(role: 'member');
      when(() => authRepository.getCurrentUser())
          .thenAnswer((_) async => userData);

      final provider = await createProvider(
        currentUser: firebaseUser,
        claims: <String, dynamic>{'role': 'admin'},
        currentUserData: userData,
      );

      expect(provider.role, 'admin');
    });

    test('uses stored gym code when it is valid', () async {
      SharedPreferences.setMockInitialValues(<String, Object?>{
        'selectedGymCode': 'G2',
      });
      when(() => authManager.currentUser).thenReturn(firebaseUser);
      when(() => authManager.getIdTokenClaims(firebaseUser))
          .thenAnswer((_) async => <String, dynamic>{});
      final userData = buildUser(gymCodes: const ['G1', 'G2']);
      when(() => authRepository.getCurrentUser())
          .thenAnswer((_) async => userData);

      final provider = AuthProvider(
        repo: authRepository,
        authManager: authManager,
        sessionDraftRepository: draftRepository,
      );
      await pumpEventQueue();

      expect(provider.gymCode, 'G2');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selectedGymCode'), 'G2');
    });

    test('writes first gym code when none stored or invalid', () async {
      SharedPreferences.setMockInitialValues(<String, Object?>{
        'selectedGymCode': 'unknown',
      });
      when(() => authManager.currentUser).thenReturn(firebaseUser);
      when(() => authManager.getIdTokenClaims(firebaseUser))
          .thenAnswer((_) async => <String, dynamic>{});
      final userData = buildUser(gymCodes: const ['G1', 'G3']);
      when(() => authRepository.getCurrentUser())
          .thenAnswer((_) async => userData);

      final provider = AuthProvider(
        repo: authRepository,
        authManager: authManager,
        sessionDraftRepository: draftRepository,
      );
      await pumpEventQueue();

      expect(provider.gymCode, 'G1');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selectedGymCode'), 'G1');
    });
  });
}
