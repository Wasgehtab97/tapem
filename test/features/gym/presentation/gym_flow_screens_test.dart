import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/shared_preferences_provider.dart';
import 'package:tapem/core/providers/gym_scoped_resettable.dart';
import 'package:tapem/core/widgets/offline_banner.dart';
import 'package:tapem/features/auth/domain/models/user_data.dart';
import 'package:tapem/features/auth/domain/repositories/auth_repository.dart';
import 'package:tapem/features/auth/domain/services/firebase_auth_manager.dart';
import 'package:tapem/features/auth/presentation/screens/gym_login_screen.dart';
import 'package:tapem/features/auth/presentation/screens/gym_register_screen.dart';
import 'package:tapem/features/auth/presentation/screens/gym_register_method_screen.dart';
import 'package:tapem/features/gym/application/gym_directory_provider.dart';
import 'package:tapem/features/gym/domain/models/gym_config.dart';
import 'package:tapem/features/gym/domain/usecases/validate_gym_code.dart';
import 'package:tapem/features/gym/presentation/screens/gym_entry_screen.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/drafts/session_draft.dart';
import 'package:tapem/core/drafts/session_draft_repository.dart';
import 'package:tapem/services/membership_service.dart';

class _FakeAuthRepository implements AuthRepository {
  final UserData _user = UserData(
    id: 'user-1',
    email: 'user@test.dev',
    gymCodes: const ['gym-1'],
    showInLeaderboard: true,
    publicProfile: true,
    role: 'member',
    createdAt: DateTime(2024, 1, 1),
  );

  @override
  Future<UserData> login(String email, String password) async => _user;

  @override
  Future<UserData> register(
    String email,
    String password,
    String gymId,
  ) async => _user.copyWith(gymCodes: [gymId]);

  @override
  Future<void> logout() async {}

  @override
  Future<UserData?> getCurrentUser() async => null;

  @override
  Future<void> setUsername(String userId, String username) async {}

  @override
  Future<void> setShowInLeaderboard(String userId, bool value) async {}

  @override
  Future<void> setPublicProfile(String userId, bool value) async {}

  @override
  Future<void> setProfileVisibility(String userId, bool value) async {}

  @override
  Future<void> setAvatarKey(String userId, String avatarKey) async {}

  @override
  Future<void> setPublicKey(String userId, String publicKey) async {}

  @override
  Future<void> setCoachEnabled(String userId, bool value) async {}

  @override
  Future<bool> isUsernameAvailable(String username) async => true;

  @override
  Future<void> sendPasswordResetEmail(String email) async {}
}

class _FakeAuthManager implements FirebaseAuthManager {
  @override
  fb_auth.User? get currentUser => null;

  @override
  Future<void> reloadUser(fb_auth.User user) async {}

  @override
  Future<Map<String, dynamic>> forceRefreshIdToken(fb_auth.User user) async =>
      const {};

  @override
  Future<Map<String, dynamic>> getIdTokenClaims(fb_auth.User user) async =>
      const {};
}

class _FakeSessionDraftRepository implements SessionDraftRepository {
  @override
  Future<void> delete(String key) async {}

  @override
  Future<void> deleteAll() async {}

  @override
  Future<void> deleteExpired(int nowMs) async {}

  @override
  Future<SessionDraft?> get(String key) async => null;

  @override
  Future<Map<String, SessionDraft>> getAll() async => {};

  @override
  Future<void> put(String key, SessionDraft draft) async {}
}

class _FakeMembershipService implements MembershipService {
  @override
  Future<void> ensureMembership(String gymId, String uid) async {}
}

Future<AuthProvider> _buildAuthProvider() async {
  return AuthProvider(
    repo: _FakeAuthRepository(),
    authManager: _FakeAuthManager(),
    sessionDraftRepository: _FakeSessionDraftRepository(),
    membershipService: _FakeMembershipService(),
    setActiveGym: (_) async {},
    gymScopedStateController: GymScopedStateController(),
    firestore: FakeFirebaseFirestore(),
  );
}

Widget _buildTestApp(Widget child, {required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    ),
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    OfflineBanner.disableForTests = true;
  });

  testWidgets('GymEntryScreen shows gyms', (tester) async {
    final gyms = [GymConfig(id: 'gym-1', code: 'AAAAAA', name: 'Test Gym')];

    await tester.pumpWidget(
      _buildTestApp(
        const GymEntryScreen(),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          listGymsProvider.overrideWith((ref) async => gyms),
        ],
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('Test Gym'), findsOneWidget);
  });

  testWidgets('GymLoginScreen renders gym title and form', (tester) async {
    final authProvider = await _buildAuthProvider();

    await tester.pumpWidget(
      _buildTestApp(
        const GymLoginScreen(gymId: 'gym-1'),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith((ref) => authProvider),
          gymByIdProvider.overrideWith(
            (ref, id) async =>
                GymConfig(id: id, code: 'AAAAAA', name: 'Test Gym'),
          ),
        ],
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.textContaining('Test Gym'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
  });

  testWidgets('GymRegisterMethodScreen shows registration options', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(
        const GymRegisterMethodScreen(gymId: 'gym-1'),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          gymByIdProvider.overrideWith(
            (ref, id) async =>
                GymConfig(id: id, code: 'AAAAAA', name: 'Test Gym'),
          ),
        ],
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.textContaining('Test Gym'), findsOneWidget);
    expect(find.text('Register with gym code'), findsOneWidget);
  });

  testWidgets('GymRegisterScreen renders registration form', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final authProvider = await _buildAuthProvider();
    final gymValidator = _MockValidateGymCode();
    when(() => gymValidator.execute(any())).thenAnswer(
      (_) async => GymCodeValidationResult(
        gymId: 'gym-1',
        gymName: 'Test Gym',
        code: 'AAAAAA',
        expiresAt: DateTime(2025, 1, 1),
      ),
    );

    await tester.pumpWidget(
      _buildTestApp(
        GymRegisterScreen(
          args: GymRegisterArgs(
            gymId: 'gym-1',
            method: GymRegisterMethod.gymCode,
            gymValidator: gymValidator,
          ),
        ),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith((ref) => authProvider),
          gymByIdProvider.overrideWith(
            (ref, id) async =>
                GymConfig(id: id, code: 'AAAAAA', name: 'Test Gym'),
          ),
        ],
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.textContaining('Test Gym'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
  });
}

class _MockValidateGymCode extends Mock implements ValidateGymCode {}
