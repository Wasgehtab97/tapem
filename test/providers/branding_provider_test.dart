import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/providers/branding_provider.dart';
import 'package:tapem/features/gym/data/sources/firestore_gym_source.dart';
import 'package:tapem/features/gym/domain/models/branding.dart';
import 'package:tapem/features/gym/domain/models/gym_config.dart';
import '../firebase_test_utils.dart';

class FakeGymSource implements FirestoreGymSource {
  FakeGymSource({this.branding, this.throwError});
  final Branding? branding;
  final bool? throwError;

  @override
  Future<GymConfig?> getGymByCode(String code) async => null;

  @override
  Future<GymConfig?> getGymById(String id) async => null;

  @override
  Future<Branding?> getBranding(String gymId) async {
    if (throwError == true) throw Exception('fail');
    return branding;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setupFirebaseMocks();
  });

  group('BrandingProvider', () {
    test('loads branding successfully', () async {
      final source = FakeGymSource(branding: Branding(logoUrl: 'x'));
      final provider = BrandingProvider(
        source: source,
        log: (_, [__]) {},
      );
      await provider.loadBranding('g1');
      expect(provider.branding?.logoUrl, 'x');
      expect(provider.error, isNull);
    });

    test('handles missing document', () async {
      final source = FakeGymSource(branding: null);
      final provider = BrandingProvider(
        source: source,
        log: (_, [__]) {},
      );
      await provider.loadBranding('g1');
      expect(provider.branding, isNull);
    });

    test('handles exceptions', () async {
      final source = FakeGymSource(throwError: true);
      final provider = BrandingProvider(
        source: source,
        log: (_, [__]) {},
      );
      await provider.loadBranding('g1');
      expect(provider.branding, isNull);
      expect(provider.error, isNotNull);
    });
  });
}
