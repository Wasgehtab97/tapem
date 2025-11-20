import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/branding_provider.dart';
import 'package:tapem/core/providers/firebase_provider.dart';
import 'package:tapem/core/providers/shared_preferences_provider.dart';
import 'package:tapem/core/providers/theme_preference_provider.dart';
import 'package:tapem/core/theme/theme_loader.dart';
import 'package:tapem/features/gym/data/sources/firestore_gym_source.dart';
import 'package:tapem/features/gym/domain/models/branding.dart';
import 'package:tapem/services/membership_service.dart';

AuthViewState _authState({String? gymId, String? userId}) {
  return AuthViewState(
    isLoading: false,
    isLoggedIn: gymId != null && userId != null,
    isAdmin: false,
    gymContextStatus:
        gymId != null ? GymContextStatus.ready : GymContextStatus.unknown,
    gymCode: gymId,
    userId: userId,
    error: null,
  );
}

class _FakeMembershipService implements MembershipService {
  @override
  Future<void> ensureMembership(String gymId, String uid) async {}
}

class _TestBrandingProvider extends BrandingProvider {
  _TestBrandingProvider()
      : super(
          source: FirestoreGymSource(firestore: FakeFirebaseFirestore()),
          membership: _FakeMembershipService(),
        );

  Branding? _brandingOverride;
  String? _gymIdOverride;

  @override
  Branding? get branding => _brandingOverride;

  @override
  String? get gymId => _gymIdOverride;

  void setState({String? gymId, Branding? branding}) {
    _gymIdOverride = gymId;
    _brandingOverride = branding;
    notifyListeners();
  }

  @override
  void resetGymScopedState() {
    _brandingOverride = null;
    _gymIdOverride = null;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('themeLoaderProvider detaches branding listeners on dispose', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final branding = _TestBrandingProvider();
    final container = ProviderContainer(
      overrides: [
        firebaseFirestoreProvider.overrideWith((ref) => FakeFirebaseFirestore()),
        sharedPreferencesProvider.overrideWith((ref) => prefs),
        membershipServiceProvider.overrideWith((ref) => _FakeMembershipService()),
        brandingProvider.overrideWith((ref) => branding),
        authViewStateProvider.overrideWith((ref) => _authState(
              gymId: 'gymA',
              userId: 'userA',
            )),
      ],
    );
    addTearDown(() {
      branding.dispose();
      container.dispose();
    });

    final prefsProvider = container.read(themePreferenceProvider);
    prefsProvider.setUser('userA');
    final loader = container.read(themeLoaderProvider);
    expect(loader.theme, isNotNull);

    branding.setState(
      gymId: 'gymA',
      branding: Branding(
        primaryColor: '#111111',
        secondaryColor: '#eeeeee',
      ),
    );

    container.invalidate(themeLoaderProvider);

    expect(
      () =>
          branding.setState(
            gymId: 'gymB',
            branding: Branding(
              primaryColor: '#222222',
              secondaryColor: '#dddddd',
            ),
          ),
      returnsNormally,
    );
  });
}
