import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:tapem/core/config/remote_config.dart';
import 'package:tapem/features/avatars/domain/avatars_v2_telemetry.dart';

class AvatarInventoryProvider extends ChangeNotifier {
  AvatarInventoryProvider({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    AvatarsV2Telemetry? telemetry,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _telemetry = telemetry;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AvatarsV2Telemetry? _telemetry;

  Set<String>? _owned;

  Future<Set<String>> getOwnedAvatarIds() async {
    if (!RC.avatarsV2Enabled) return <String>{};
    if (_owned != null) return _owned!;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return <String>{};
    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('avatarsOwned')
          .get();
      _owned = snap.docs.map((d) => d.id).toSet();
      _telemetry?.avatarInventoryLoaded(_owned!.length);
      return _owned!;
    } catch (e) {
      return _owned ?? <String>{};
    }
  }

  bool isOwned(String avatarId) {
    if (!RC.avatarsV2Enabled) return false;
    return _owned?.contains(avatarId) ?? false;
  }

  Future<void> refresh() async {
    _owned = null;
    await getOwnedAvatarIds();
    notifyListeners();
  }

  void clear() {
    _owned = null;
    notifyListeners();
  }
}

