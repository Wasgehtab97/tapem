import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/providers/branding_provider.dart';
import 'package:tapem/core/providers/gym_scoped_resettable.dart';
import 'package:tapem/features/gym/data/sources/firestore_gym_source.dart';
import 'package:tapem/features/gym/domain/models/branding.dart';
import 'package:tapem/services/membership_service.dart';

void main() {
  group('BrandingProvider', () {
    test('resets branding when gym context changes', () async {
      final controller = GymScopedStateController();
      final membership = _RecordingMembershipService();
      final provider = BrandingProvider(
        source: _FakeBrandingSource({
          'gymA': Branding(primaryColor: '#111111'),
          'gymB': Branding(primaryColor: '#222222'),
        }),
        membership: membership,
      );
      provider.registerGymScopedResettable(controller);

      await provider.loadBranding('gymA', 'uid');
      expect(provider.branding?.primaryColor, '#111111');

      controller.resetGymScopedState();
      expect(provider.branding, isNull);

      await provider.loadBranding('gymB', 'uid');
      expect(provider.branding?.primaryColor, '#222222');
      expect(membership.ensureCalls, 2);
    });

    test('unregisters from controller on dispose', () {
      final controller = _RecordingGymScopedStateController();
      final provider = BrandingProvider(
        source: _FakeBrandingSource({}),
        membership: _RecordingMembershipService(),
      );
      provider.registerGymScopedResettable(controller);
      expect(controller.registerCalls, 1);

      provider.dispose();
      expect(controller.unregisterCalls, 1);
    });
  });
}

class _FakeBrandingSource extends FirestoreGymSource {
  _FakeBrandingSource(this._responses)
      : super(firestore: FakeFirebaseFirestore());

  final Map<String, Branding?> _responses;

  @override
  Future<Branding?> getBranding(String gymId) async => _responses[gymId];
}

class _RecordingMembershipService implements MembershipService {
  int ensureCalls = 0;

  @override
  Future<void> ensureMembership(String gymId, String uid) async {
    ensureCalls++;
  }
}

class _RecordingGymScopedStateController extends GymScopedStateController {
  int registerCalls = 0;
  int unregisterCalls = 0;

  @override
  void register(GymScopedResettable resettable) {
    registerCalls++;
    super.register(resettable);
  }

  @override
  void unregister(GymScopedResettable resettable) {
    unregisterCalls++;
    super.unregister(resettable);
  }
}
