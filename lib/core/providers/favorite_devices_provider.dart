import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/firebase_provider.dart';
import 'package:tapem/core/providers/shared_preferences_provider.dart';

class FavoriteDevicesProvider extends ChangeNotifier {
  FavoriteDevicesProvider({
    FirebaseFirestore? firestore,
    SharedPreferences? preferences,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _preferences = preferences;

  final FirebaseFirestore _firestore;
  final SharedPreferences? _preferences;

  String? _uid;
  String? _error;

  final Map<String, Set<String>> _favoriteIdsByGym = {};
  final Set<String> _loadingGyms = <String>{};
  final Set<String> _loadedGyms = <String>{};

  String? get error => _error;

  bool hasLoadedGym(String gymId) => _loadedGyms.contains(gymId);
  bool isLoadingGym(String gymId) => _loadingGyms.contains(gymId);

  Set<String> favoriteIdsForGym(String gymId) {
    final ids = _favoriteIdsByGym[gymId];
    if (ids == null) {
      return const <String>{};
    }
    return Set.unmodifiable(ids);
  }

  bool isFavorite({required String gymId, required String deviceId}) {
    final ids = _favoriteIdsByGym[gymId];
    return ids != null && ids.contains(deviceId);
  }

  void setUser(String? uid) {
    if (_uid == uid) {
      return;
    }
    _uid = uid;
    _error = null;
    _favoriteIdsByGym.clear();
    _loadingGyms.clear();
    _loadedGyms.clear();
    notifyListeners();
  }

  Future<void> loadForGym(String gymId, {bool force = false}) async {
    if (gymId.isEmpty) {
      return;
    }
    if (!force &&
        (_loadingGyms.contains(gymId) || _loadedGyms.contains(gymId))) {
      return;
    }

    final uid = _uid;
    final cacheKey = _cacheKey(uid: uid, gymId: gymId);
    final cached = _preferences?.getStringList(cacheKey);
    if (cached != null) {
      _favoriteIdsByGym[gymId] = cached.toSet();
      notifyListeners();
    }

    if (uid == null || uid.isEmpty) {
      _loadedGyms.add(gymId);
      notifyListeners();
      return;
    }

    _loadingGyms.add(gymId);
    _error = null;
    notifyListeners();
    try {
      final snap = await _doc(uid, gymId).get();
      final data = snap.data();
      final rawIds = data?['deviceIds'] as List<dynamic>? ?? const <dynamic>[];
      final ids = rawIds
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .toSet();
      _favoriteIdsByGym[gymId] = ids;
      _loadedGyms.add(gymId);
      await _preferences?.setStringList(cacheKey, ids.toList()..sort());
    } catch (e) {
      _error = e.toString();
      _loadedGyms.add(gymId);
    } finally {
      _loadingGyms.remove(gymId);
      notifyListeners();
    }
  }

  Future<bool> toggleFavorite({
    required String gymId,
    required String deviceId,
  }) async {
    final normalizedGymId = gymId.trim();
    final normalizedDeviceId = deviceId.trim();
    if (normalizedGymId.isEmpty || normalizedDeviceId.isEmpty) {
      return false;
    }

    final before = Set<String>.from(
      _favoriteIdsByGym[normalizedGymId] ?? const <String>{},
    );
    final next = Set<String>.from(before);
    final isNowFavorite = !next.remove(normalizedDeviceId);
    if (isNowFavorite) {
      next.add(normalizedDeviceId);
    }

    _favoriteIdsByGym[normalizedGymId] = next;
    _loadedGyms.add(normalizedGymId);
    _error = null;
    notifyListeners();

    final uid = _uid;
    final cacheKey = _cacheKey(uid: uid, gymId: normalizedGymId);
    final sortedNext = next.toList()..sort();
    try {
      await _preferences?.setStringList(cacheKey, sortedNext);

      if (uid != null && uid.isNotEmpty) {
        await _doc(uid, normalizedGymId).set({
          'gymId': normalizedGymId,
          'deviceIds': sortedNext,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      return isNowFavorite;
    } catch (e) {
      _favoriteIdsByGym[normalizedGymId] = before;
      _error = e.toString();
      await _preferences?.setStringList(cacheKey, before.toList()..sort());
      notifyListeners();
      return before.contains(normalizedDeviceId);
    }
  }

  String _cacheKey({required String? uid, required String gymId}) {
    final userSegment = (uid != null && uid.isNotEmpty) ? uid : 'guest';
    return 'favoriteDevices/$userSegment/$gymId';
  }

  DocumentReference<Map<String, dynamic>> _doc(String uid, String gymId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('device_favorites_${Uri.encodeComponent(gymId)}');
  }
}

final favoriteDevicesProvider = ChangeNotifierProvider<FavoriteDevicesProvider>(
  (ref) {
    final provider = FavoriteDevicesProvider(
      firestore: ref.watch(firebaseFirestoreProvider),
      preferences: ref.watch(sharedPreferencesProvider),
    );
    ref.onDispose(provider.dispose);

    void update(AuthViewState state) {
      provider.setUser(state.userId);
    }

    update(ref.read(authViewStateProvider));
    ref.listen<AuthViewState>(authViewStateProvider, (_, next) => update(next));
    return provider;
  },
);
