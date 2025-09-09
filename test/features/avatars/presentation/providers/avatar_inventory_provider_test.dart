import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';
import 'package:tapem/features/avatars/presentation/providers/avatar_inventory_provider.dart';

void main() {
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
  });
}
