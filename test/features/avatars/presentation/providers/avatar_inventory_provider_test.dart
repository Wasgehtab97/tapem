import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });
}
