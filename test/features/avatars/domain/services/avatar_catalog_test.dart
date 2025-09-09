import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    AvatarCatalog.instance.resetForTests();
    const manifest = {
      'assets/avatars/global/default.png': [],
      'assets/avatars/global/default2.png': [],
      'assets/avatars/gym_01/kurzhantel.png': [],
      'assets/avatars/Club Aktiv/ignored.png': [],
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
    expect(catalog.globalCount, 2);
    expect(catalog.gymCount('gym_01'), 1);
    expect(catalog.resolvePathOrFallback('gym_01/kurzhantel'),
        'assets/avatars/gym_01/kurzhantel.png');
    expect(
        catalog.resolvePathOrFallback('kurzhantel', gymId: 'gym_01'),
        'assets/avatars/gym_01/kurzhantel.png');
    expect(catalog.resolvePathOrFallback('unknown'),
        'assets/avatars/global/default.png');
  });
}
