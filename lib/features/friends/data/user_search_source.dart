import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/models/public_profile.dart';

class UserSearchSource {
  UserSearchSource(this._firestore);

  final FirebaseFirestore _firestore;
  final Duration _cacheTtl = const Duration(minutes: 5);
  final Map<String, _CachedProfiles> _cache = <String, _CachedProfiles>{};

  Future<PublicProfile> getProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) {
      throw Exception('not-found');
    }
    return PublicProfile(
      uid: doc.id,
      username: data['username'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      primaryGymCode:
          (data['gymCodes'] is List && (data['gymCodes'] as List).isNotEmpty)
              ? (data['gymCodes'] as List).first as String
              : null,
      avatarKey: data['avatarKey'] as String? ?? 'default',
    );
  }

  Future<List<PublicProfile>> searchByUsernamePrefix(
    String q, {
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    final prefix = q.trim().toLowerCase();
    if (prefix.isEmpty) return const [];

    if (!forceRefresh) {
      final cached = _cache[prefix];
      if (cached != null && _isFresh(cached.timestamp)) {
        return cached.results;
      }
    }

    final end = '$prefix\uf8ff';
    if (kDebugMode) {
      debugPrint(
          '[FriendSearch] query collection=users orderBy=publicProfile,usernameLower where publicProfile=true startAt=[true,$prefix] endAt=[true,$end] limit=$limit');
    }
    final snap = await _firestore
        .collection('users')
        .orderBy('publicProfile')
        .where('publicProfile', isEqualTo: true)
        .orderBy('usernameLower')
        .startAt([true, prefix])
        .endAt([true, end])
        .limit(limit)
        .get();
    if (kDebugMode) {
      debugPrint('[FriendSearch] results=${snap.docs.length}');
    }
    final results = snap.docs.map((d) {
      final data = d.data();
      return PublicProfile(
        uid: d.id,
        username: data['username'] as String? ?? '',
        avatarUrl: data['avatarUrl'] as String?,
        primaryGymCode:
            (data['gymCodes'] is List && (data['gymCodes'] as List).isNotEmpty)
                ? (data['gymCodes'] as List).first as String
                : null,
        avatarKey: data['avatarKey'] as String? ?? 'default',
      );
    }).toList();

    _cache[prefix] = _CachedProfiles(
      results: results,
      timestamp: DateTime.now(),
    );
    return results;
  }

  bool _isFresh(DateTime timestamp) {
    return DateTime.now().difference(timestamp) < _cacheTtl;
  }
}

class _CachedProfiles {
  _CachedProfiles({required this.results, required this.timestamp});

  final List<PublicProfile> results;
  final DateTime timestamp;
}
