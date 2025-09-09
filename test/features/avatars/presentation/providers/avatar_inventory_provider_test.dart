import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';
import 'package:tapem/features/avatars/presentation/providers/avatar_inventory_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AvatarInventoryProvider', () {
    test('addKeys and removeKey use sanitized doc ids', () async {
      final fs = FakeFirebaseFirestore();
      final provider = AvatarInventoryProvider(firestore: fs);

      await provider.addKeys('u1', ['global/kurzhantel'],
          source: 'admin/manual', createdBy: 'admin', gymId: 'g1');

      final doc = await fs
          .collection('users')
          .doc('u1')
          .collection('avatarInventory')
          .doc('global__kurzhantel')
          .get();
      expect(doc.exists, true);
      expect(doc.data()?['key'], 'global/kurzhantel');

      await provider.removeKey('u1', 'global/kurzhantel');
      final after = await fs
          .collection('users')
          .doc('u1')
          .collection('avatarInventory')
          .doc('global__kurzhantel')
          .get();
      expect(after.exists, false);
    });

    test('filterNotOwnedItems merges catalog and excludes owned', () {
      final provider = AvatarInventoryProvider();
      final catalogItems = [
        const AvatarItem('global/default', 'p1'),
        const AvatarItem('global/extra', 'p2'),
        const AvatarItem('g1/kurzhantel', 'p3'),
        const AvatarItem('g1/kurzhantel', 'p3'), // duplicate
      ];
      final owned = ['global/default', 'g1/other'];
      final result =
          provider.filterNotOwnedItems(catalogItems, owned, currentGymId: 'g1');
      expect(result.map((e) => e.key).toList(), ['global/extra', 'g1/kurzhantel']);
    });

    test('availableKeys returns union minus inventory', () async {
      AvatarCatalog.instance.resetForTests();
      const manifest = {
        'assets/avatars/global/default.png': [],
        'assets/avatars/global/default2.png': [],
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
      addTearDown(() {
        ServicesBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', null);
        AvatarCatalog.instance.resetForTests();
      });
      final provider = AvatarInventoryProvider();
      final owned = {'global/default', 'gym_01/kurzhantel'};
      final avail = provider.availableKeys(owned, 'gym_01');
      expect(avail.global.map((e) => e.key), ['global/default2']);
      expect(avail.gym, isEmpty);
    });
  });
}
