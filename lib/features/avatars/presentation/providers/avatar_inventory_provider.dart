import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tapem/core/utils/avatar_assets.dart';
import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';

/// Single inventory record.
class AvatarInventoryEntry {
  AvatarInventoryEntry({
    required this.key,
    required this.source,
    this.createdAt,
  });

  final String key;
  final String source;
  final Timestamp? createdAt;
}

/// Provider for managing avatar inventory per user.
class AvatarInventoryProvider extends ChangeNotifier {
  AvatarInventoryProvider({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth? _auth;

  Set<String>? _cache;

  String _docId(String key) => key.replaceAll('/', '__');

  /// Computes available catalog keys for [gymId] excluding [ownedKeys].
  ({List<String> global, List<String> gym}) availableKeys(
    Iterable<String> ownedKeys,
    String gymId,
  ) {
    final owned = ownedKeys.toSet();
    return AvatarCatalog.instance.availableKeys(owned: owned, gymId: gymId);
  }

  /// Stream of normalised inventory entries for [uid].
  Stream<List<AvatarInventoryEntry>> inventory(String uid,
      {String? currentGymId}) {
    if (uid.isEmpty) return const Stream<List<AvatarInventoryEntry>>.empty();
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('avatarInventory')
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              final rawKey =
                  data['key'] as String? ?? d.id.replaceAll('__', '/');
              final normalised = AvatarAssets.normalizeAvatarKey(rawKey,
                  currentGymId: currentGymId);
              return AvatarInventoryEntry(
                key: normalised,
                source: data['source'] as String? ?? '',
                createdAt: data['createdAt'] as Timestamp?,
              );
            }).toList());
  }

  /// Stream only the keys, merged with default avatars and deduplicated.
  Stream<List<String>> inventoryKeys(String uid, {String? currentGymId}) {
    return inventory(uid, currentGymId: currentGymId).map((items) {
      final map = <String, AvatarInventoryEntry>{};
      for (final item in items) {
        final existing = map[item.key];
        if (existing == null ||
            (existing.createdAt?.compareTo(item.createdAt ?? Timestamp(0, 0)) ??
                    -1) <
                0) {
          map[item.key] = item;
        }
      }
      final result = <AvatarInventoryEntry>[];

      final def = map.remove(AvatarKeys.globalDefault);
      if (def != null) {
        result.add(def);
      } else {
        result.add(
            AvatarInventoryEntry(key: AvatarKeys.globalDefault, source: 'global'));
      }

      final def2 = map.remove(AvatarKeys.globalDefault2);
      if (def2 != null) {
        result.add(def2);
      } else {
        result.add(AvatarInventoryEntry(
            key: AvatarKeys.globalDefault2, source: 'global'));
      }
      final rest = map.values.toList()
        ..sort((a, b) {
          final aTime = a.createdAt ?? Timestamp(0, 0);
          final bTime = b.createdAt ?? Timestamp(0, 0);
          return bTime.compareTo(aTime);
        });
      result.addAll(rest);
      return result.map((e) => e.key).toList();
    });
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
      final normalised =
          AvatarAssets.normalizeAvatarKey(key, currentGymId: gymId);
      final ref = _firestore
          .collection('users')
          .doc(uid)
          .collection('avatarInventory')
          .doc(_docId(normalised));
      batch.set(
          ref,
          {
            'key': normalised,
            'source': source,
            'createdAt': now,
            'createdBy': createdBy,
            if (gymId != null) 'gymId': gymId,
          },
          SetOptions(merge: true));
    }
    await batch.commit();
  }

  /// Removes [key] from the inventory of [uid].
  Future<void> removeKey(String uid, String key) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('avatarInventory')
        .doc(_docId(key))
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

