import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:tapem/core/utils/avatar_assets.dart';
import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';

/// Single inventory record.
class AvatarInventoryEntry {
  AvatarInventoryEntry({
    required this.key,
    required this.source,
    this.createdAt,
    this.documentId,
  });

  final String key;
  final String source;
  final Timestamp? createdAt;
  final String? documentId;
}

class _InventoryCache {
  _InventoryCache({required this.items, required this.timestamp});

  final List<AvatarInventoryEntry> items;
  final DateTime timestamp;
}

/// Provider for managing avatar inventory per user.
class AvatarInventoryProvider extends ChangeNotifier {
  AvatarInventoryProvider({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth? _auth;

  final Duration _cacheTtl = const Duration(minutes: 10);
  final Map<String, _InventoryCache> _inventoryCache =
      <String, _InventoryCache>{};
  final Map<String, Set<String>> _ownedCache = <String, Set<String>>{};

  String _docId(String key) => key.replaceAll('/', '__');

  bool _isFresh(String uid) {
    final cache = _inventoryCache[uid];
    if (cache == null) return false;
    return DateTime.now().difference(cache.timestamp) < _cacheTtl;
  }

  /// Computes available catalog keys for [gymId] excluding [ownedKeys].
  ({List<String> global, List<String> gym}) availableKeys(
    Iterable<String> ownedKeys,
    String gymId,
  ) {
    final owned = ownedKeys.toSet();
    return AvatarCatalog.instance.availableKeys(owned: owned, gymId: gymId);
  }

  Future<List<AvatarInventoryEntry>> fetchInventory(
    String uid, {
    bool forceRefresh = false,
  }) async {
    if (uid.isEmpty) return const [];
    if (!forceRefresh && _isFresh(uid)) {
      return _inventoryCache[uid]!.items;
    }

    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('avatarInventory')
        .get();
    final items = snap.docs.map((d) {
      final data = d.data();
      final rawKey = data['key'] as String? ?? d.id.replaceAll('__', '/');
      final normalized = AvatarAssets.normalizeKey(rawKey);
      return AvatarInventoryEntry(
        key: normalized,
        source: data['source'] as String? ?? '',
        createdAt: data['createdAt'] as Timestamp?,
        documentId: d.id,
      );
    }).toList();

    _inventoryCache[uid] = _InventoryCache(
      items: items,
      timestamp: DateTime.now(),
    );
    _ownedCache[uid] = snap.docs.map((d) => d.id).toSet();
    notifyListeners();
    return items;
  }

  List<AvatarInventoryEntry> getCachedInventory(String uid) {
    final cache = _inventoryCache[uid];
    if (cache == null) return const [];
    return cache.items;
  }

  Future<List<String>> fetchInventoryKeys(
    String uid, {
    String? currentGymId,
    bool forceRefresh = false,
  }) async {
    final entries = await fetchInventory(uid, forceRefresh: forceRefresh);
    return _normaliseKeys(entries, currentGymId: currentGymId);
  }

  List<String> getCachedInventoryKeys(String uid, {String? currentGymId}) {
    final entries = getCachedInventory(uid);
    if (entries.isEmpty) return const [];
    return _normaliseKeys(entries, currentGymId: currentGymId);
  }

  List<String> _normaliseKeys(
    List<AvatarInventoryEntry> items, {
    String? currentGymId,
  }) {
    final map = <String, AvatarInventoryEntry>{};
    for (final item in items) {
      final normalised =
          AvatarAssets.normalizeKey(item.key, currentGymId: currentGymId);
      final existing = map[normalised];
      if (existing == null ||
          (existing.createdAt?.compareTo(item.createdAt ?? Timestamp(0, 0)) ??
                  -1) <
              0) {
        map[normalised] = AvatarInventoryEntry(
          key: normalised,
          source: item.source,
          createdAt: item.createdAt,
          documentId: item.documentId,
        );
      }
    }

    final result = <AvatarInventoryEntry>[];
    final def = map.remove(AvatarKeys.globalDefault);
    if (def != null) {
      result.add(def);
    } else {
      result.add(AvatarInventoryEntry(
          key: AvatarKeys.globalDefault, source: 'global_default'));
    }

    final def2 = map.remove(AvatarKeys.globalDefault2);
    if (def2 != null) {
      result.add(def2);
    } else {
      result.add(AvatarInventoryEntry(
          key: AvatarKeys.globalDefault2, source: 'global_default'));
    }

    final rest = map.values.toList()
      ..sort((a, b) {
        final aTime = a.createdAt ?? Timestamp(0, 0);
        final bTime = b.createdAt ?? Timestamp(0, 0);
        return bTime.compareTo(aTime);
      });
    result.addAll(rest);
    return result.map((e) => e.key).toList();
  }

  /// Adds multiple avatar [keys] to the inventory of [uid].
  Future<void> addKeys(
    String uid,
    List<String> keys, {
    required String source,
    String? gymId,
  }) async {
    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();
    final localNow = Timestamp.now();
    for (final key in keys) {
      final normalised =
          AvatarAssets.normalizeKey(key, currentGymId: gymId);
      final ref = _firestore
          .collection('users')
          .doc(uid)
          .collection('avatarInventory')
          .doc(_docId(normalised));
      debugPrint('[AvatarInventory] add path=' + ref.path +
          ' uid=' + uid +
          ' key=' + normalised +
          ' source=' + source +
          ' gymId=' + (gymId ?? '')); 
      final includeGymId = gymId != null && !normalised.startsWith('global/');
      batch.set(
        ref,
        {
          'key': normalised,
          'source': source,
          'createdAt': now,
          if (includeGymId) 'gymId': gymId,
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();

    final existing = _inventoryCache[uid]?.items ?? <AvatarInventoryEntry>[];
    final map = {for (final entry in existing) entry.key: entry};
    for (final key in keys) {
      final normalised =
          AvatarAssets.normalizeKey(key, currentGymId: gymId);
      map[normalised] = AvatarInventoryEntry(
        key: normalised,
        source: source,
        createdAt: localNow,
        documentId: _docId(normalised),
      );
    }
    final updated = map.values.toList()
      ..sort((a, b) {
        final aTime = a.createdAt ?? Timestamp(0, 0);
        final bTime = b.createdAt ?? Timestamp(0, 0);
        return bTime.compareTo(aTime);
      });
    _inventoryCache[uid] = _InventoryCache(
      items: updated,
      timestamp: DateTime.now(),
    );
    _ownedCache[uid] = map.values.map((e) => e.documentId ?? _docId(e.key)).toSet();
    notifyListeners();
  }

  /// Removes [key] from the inventory of [uid].
  Future<void> removeKey(String uid, String key) {
    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('avatarInventory')
        .doc(_docId(key));
    debugPrint('[AvatarInventory] remove path=' + ref.path +
        ' uid=' + uid + ' key=' + key);
    return ref.delete().whenComplete(() {
      final cache = _inventoryCache[uid];
      if (cache == null) {
        _ownedCache.remove(uid);
        return;
      }
      final updated = cache.items.where((e) => e.key != key).toList();
      _inventoryCache[uid] = _InventoryCache(
        items: updated,
        timestamp: DateTime.now(),
      );
      final owned = _ownedCache[uid] ?? <String>{};
      owned.remove(_docId(key));
      _ownedCache[uid] = owned;
      notifyListeners();
    });
  }

  // ---------------------------------------------------------------------------
  // Legacy API used by existing code
  // ---------------------------------------------------------------------------

  Future<Set<String>> getOwnedAvatarIds(
    String uid, {
    bool forceRefresh = false,
  }) async {
    if (uid.isEmpty) return <String>{};
    if (!forceRefresh) {
      final cached = _ownedCache[uid];
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    } else {
      _inventoryCache.remove(uid);
      _ownedCache.remove(uid);
    }
    await fetchInventory(uid, forceRefresh: true);
    return _ownedCache[uid] ?? <String>{};
  }

  Future<Set<String>> refreshOwnedAvatars(String uid) async {
    if (uid.isEmpty) return <String>{};
    _inventoryCache.remove(uid);
    _ownedCache.remove(uid);
    return getOwnedAvatarIds(uid, forceRefresh: true);
  }

  @Deprecated('Use getOwnedAvatarIds(uid)')
  Future<Set<String>> getOwnedAvatarIdsForCurrentUser() async {
    final uid = _auth?.currentUser?.uid;
    if (uid == null) return <String>{};
    return getOwnedAvatarIds(uid);
  }

  bool isOwned(String avatarId) {
    final uid = _auth?.currentUser?.uid;
    if (uid == null) return false;
    final cached = _ownedCache[uid];
    if (cached == null) return false;
    return cached.contains(avatarId);
  }

  Future<void> refresh({String? uid}) async {
    final targetUid = uid ?? _auth?.currentUser?.uid;
    if (targetUid == null || targetUid.isEmpty) return;
    await fetchInventory(targetUid, forceRefresh: true);
  }

  void clear() {
    _inventoryCache.clear();
    _ownedCache.clear();
    notifyListeners();
  }
}

