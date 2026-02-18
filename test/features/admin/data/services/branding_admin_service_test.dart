import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/observability/owner_action_observability_service.dart';
import 'package:tapem/core/services/admin_audit_logger.dart';
import 'package:tapem/features/admin/data/services/branding_admin_service.dart';

void main() {
  group('BrandingAdminService', () {
    late FakeFirebaseFirestore firestore;
    late OwnerActionObservabilityService observability;
    late BrandingAdminService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      observability = OwnerActionObservabilityService.instance;
      observability.resetForTests();
      service = BrandingAdminService(
        firestore: firestore,
        auditLogger: AdminAuditLogger(firestore: firestore),
        observability: observability,
      );
    });

    test(
      'saves branding to gym config and gym root and writes audit',
      () async {
        await service.saveBranding(
          const BrandingSaveInput(
            gymId: 'gym-a',
            actorUid: 'owner-1',
            primaryHex: '112233',
            accentHex: 'aabbcc',
            logoUrl: 'https://example.com/logo.png',
          ),
        );

        final branding = await firestore
            .collection('gyms')
            .doc('gym-a')
            .collection('config')
            .doc('branding')
            .get();
        expect(branding.exists, isTrue);
        expect(branding.data()!['primaryColor'], '112233');
        expect(branding.data()!['secondaryColor'], 'aabbcc');
        expect(branding.data()!['logoUrl'], 'https://example.com/logo.png');

        final gym = await firestore.collection('gyms').doc('gym-a').get();
        expect(gym.exists, isTrue);
        expect(gym.data()!['primaryColor'], '112233');
        expect(gym.data()!['accentColor'], 'aabbcc');
        expect(gym.data()!['logoUrl'], 'https://example.com/logo.png');

        final auditDocs = await firestore
            .collection('gyms')
            .doc('gym-a')
            .collection('adminAudit')
            .get();
        expect(auditDocs.docs.length, 1);
        expect(auditDocs.docs.first.data()['action'], 'branding_update');

        final metric = observability.metrics.metricFor('owner.branding.save');
        expect(metric.attempts, 1);
        expect(metric.successes, 1);
        expect(metric.failures, 0);
      },
    );

    test('rejects invalid hex values', () async {
      await expectLater(
        () => service.saveBranding(
          const BrandingSaveInput(
            gymId: 'gym-a',
            actorUid: 'owner-1',
            primaryHex: 'xyz',
            accentHex: '123456',
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );

      final gym = await firestore.collection('gyms').doc('gym-a').get();
      expect(gym.exists, isFalse);
      final metric = observability.metrics.metricFor('owner.branding.save');
      expect(metric.attempts, 0);
    });
  });
}
