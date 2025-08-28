import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Syncs a subset of the user profile into `publicProfiles/{uid}`.
///
/// Only mirrors when the user opted in to a public profile
/// (`showInLeaderboard == true`). Otherwise the mirror document is
/// removed.
class PublicProfileSyncService {
  PublicProfileSyncService(this._firestore);

  final FirebaseFirestore _firestore;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  /// Ensures that a mirror document exists in `publicProfiles/{uid}`.
  ///
  /// If the user profile is marked as private the mirror will be
  /// removed instead. The [primaryGymCode] is optional and can be used
  /// to store the currently selected gym of the user.
  Future<void> ensurePublicProfile(String uid, {String? primaryGymCode}) async {
    try {
      final userSnap = await _firestore.collection('users').doc(uid).get();
      final user = userSnap.data();
      if (user == null) return;

      final isPublic = user['showInLeaderboard'] != false;
      if (!isPublic) {
        await removePublicProfileIfPrivate(uid);
        return;
      }

      final ref = _firestore.collection('publicProfiles').doc(uid);
      final profileSnap = await ref.get();
      final data = <String, dynamic>{
        'username': user['userName'] ?? '',
        'usernameLower': (user['userName'] as String? ?? '').toLowerCase(),
        if (primaryGymCode != null) 'primaryGymCode': primaryGymCode,
        if (user['avatarUrl'] != null) 'avatarUrl': user['avatarUrl'],
      };
      if (!profileSnap.exists) {
        data['createdAt'] = user['createdAt'] ?? FieldValue.serverTimestamp();
      }
      await ref.set(data, SetOptions(merge: true));
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('PublicProfileSyncService.ensure error: $e');
        debugPrintStack(stackTrace: st);
      }
      rethrow;
    }
  }

  /// Deletes the public profile mirror for [uid].
  Future<void> removePublicProfileIfPrivate(String uid) async {
    try {
      await _firestore.collection('publicProfiles').doc(uid).delete();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('PublicProfileSyncService.remove error: $e');
        debugPrintStack(stackTrace: st);
      }
      rethrow;
    }
  }

  /// Listens to `users/{uid}` and mirrors changes to `publicProfiles`.
  ///
  /// The optional [primaryGymCodeProvider] is invoked whenever a sync
  /// happens to obtain the latest gym code.
  void syncOnProfileChanges(String uid,
      {String? Function()? primaryGymCodeProvider}) {
    _sub?.cancel();
    _sub = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snap) async {
      final data = snap.data();
      if (data == null) return;
      final gym = primaryGymCodeProvider?.call();
      final isPublic = data['showInLeaderboard'] != false;
      if (isPublic) {
        await ensurePublicProfile(uid, primaryGymCode: gym);
      } else {
        await removePublicProfileIfPrivate(uid);
      }
    });
  }

  void dispose() {
    _sub?.cancel();
  }
}

