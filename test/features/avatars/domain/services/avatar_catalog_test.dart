import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/utils/avatar_assets.dart';
import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    AvatarCatalog.instance.resetForTests();
    const manifest = {
      'assets/avatars/global/default.png': [],
      'assets/avatars/gym_01/kurzhantel.png': [],
    };
    ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (message) async {
        final key = utf8.decode(message!.buffer.asUint8List());
        if (key == 'AssetManifest.json') {
          final data = utf8.encode(json.encode(manifest));
          return ByteData.view(Uint8List.fromList(data).buffer);
        }
        return null;
      },
    );
    await AvatarCatalog.instance.warmUp();
  });

  tearDown(() {
    ServicesBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    AvatarCatalog.instance.resetForTests();
  });

  test('catalog mapping and resolver', () {
    final catalog = AvatarCatalog.instance;
    final gymList = catalog.listGym('gym_01');
    expect(gymList.map((e) => e.key), contains('gym_01/kurzhantel'));
    expect(catalog.pathForKey('gym_01/kurzhantel'),
        'assets/avatars/gym_01/kurzhantel.png');
    expect(
        catalog.pathForKey(AvatarAssets.normalizeAvatarKey('kurzhantel',
            currentGymId: 'gym_01')),
        'assets/avatars/gym_01/kurzhantel.png');
    expect(
        catalog.pathForKey(AvatarAssets.normalizeAvatarKey('unknown')),
        'assets/avatars/global/default.png');
  });
}
