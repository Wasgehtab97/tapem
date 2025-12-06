import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models/sticker.dart';

/// Repository for retrieving stickers.
class StickerRepository {
  StickerRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  /// Returns a list of available stickers from Firestore.
  ///
  /// Stickers are ordered by sortOrder field.
  Future<List<Sticker>> getAvailableStickers() async {
    final snapshot = await _firestore
        .collection('stickers')
        .orderBy('sortOrder')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Sticker(
        id: doc.id,
        name: data['name'] as String,
        imageUrl: data['imageUrl'] as String,
        isPremium: data['isPremium'] as bool? ?? false,
      );
    }).toList();
  }

  /// Returns a sticker by its ID.
  Future<Sticker?> getStickerById(String id) async {
    final doc = await _firestore.collection('stickers').doc(id).get();
    
    if (!doc.exists) {
      return null;
    }

    final data = doc.data()!;
    return Sticker(
      id: doc.id,
      name: data['name'] as String,
      imageUrl: data['imageUrl'] as String,
      isPremium: data['isPremium'] as bool? ?? false,
    );
  }
}
