import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/avatar_catalog_item.dart';

class AvatarRepository {
  AvatarRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Future<List<AvatarCatalogItem>> loadCatalog(String gymId) async {
    final globalSnap = await _firestore
        .collection('catalogAvatarsGlobal')
        .where('isActive', isEqualTo: true)
        .get();
    final gymSnap = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('avatarCatalog')
        .where('isActive', isEqualTo: true)
        .get();

    final Map<String, AvatarCatalogItem> merged = {
      for (final doc in globalSnap.docs)
        doc.id: AvatarCatalogItem.fromMap(doc.id, doc.data())
    };
    for (final doc in gymSnap.docs) {
      merged[doc.id] = AvatarCatalogItem.fromMap(doc.id, doc.data());
    }
    final items = merged.values.toList();
    items.sort((a, b) => a.id.compareTo(b.id));
    return items;
  }
}
