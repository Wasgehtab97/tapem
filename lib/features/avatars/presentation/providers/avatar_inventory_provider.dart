import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Provider for managing avatar inventory per user.
class AvatarInventoryProvider extends ChangeNotifier {
  AvatarInventoryProvider({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth? _auth;

  Set<String>? _cache;

  /// Stream of avatar keys in the inventory of [uid].
  Stream<List<String>> inventoryKeys(String uid) {
    if (uid.isEmpty) return const Stream<List<String>>.empty();
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('avatarInventory')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }

  /// Adds multiple avatar [keys] to the inventory of [uid].
  Future<void> addKeys(
    String uid,
    List<String> keys, {
    required String source,
    required String createdBy,
    String? gymId,
  }) async {
    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();
    for (final key in keys) {
      final ref = _firestore
          .collection('users')
          .doc(uid)
          .collection('avatarInventory')
          .doc(key);
      batch.set(ref, {
        'key': key,
        'source': source,
        'createdAt': now,
        'createdBy': createdBy,
        if (gymId != null) 'gymId': gymId,
      });
    }
    await batch.commit();
  }

  /// Removes [key] from the inventory of [uid].
  Future<void> removeKey(String uid, String key) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('avatarInventory')
        .doc(key)
        .delete();
  }

  // ---------------------------------------------------------------------------
  // Legacy API used by existing code
  // ---------------------------------------------------------------------------

  Future<Set<String>> getOwnedAvatarIds() async {
    if (_cache != null) return _cache!;
    final uid = _auth?.currentUser?.uid;
    if (uid == null) return <String>{};
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('avatarInventory')
        .get();
    _cache = snap.docs.map((d) => d.id).toSet();
    return _cache!;
  }

  bool isOwned(String avatarId) => _cache?.contains(avatarId) ?? false;

  Future<void> refresh() async {
    _cache = null;
    await getOwnedAvatarIds();
    notifyListeners();
  }

  void clear() {
    _cache = null;
    notifyListeners();
  }
}

