import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:tapem/core/config/remote_config.dart';
import 'package:tapem/features/avatars/presentation/providers/avatar_inventory_provider.dart';
import 'package:tapem/features/avatars/domain/avatars_v2_telemetry.dart';

class EquipAvatarException implements Exception {
  EquipAvatarException(this.code);
  final String code;
  @override
  String toString() => 'EquipAvatarException($code)';
}

class AvatarEquipService {
  AvatarEquipService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required AvatarInventoryProvider inventory,
    AvatarsV2Telemetry? telemetry,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _inventory = inventory,
        _telemetry = telemetry;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AvatarInventoryProvider _inventory;
  final AvatarsV2Telemetry? _telemetry;

  String? _equippedRef;
  String? get equippedAvatarRef => _equippedRef;

  Future<void> setEquippedAvatarRef(String equippedRef) async {
    if (!RC.avatarsV2Enabled) return;
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw EquipAvatarException('not_member');
    }

    String avatarId = '';
    String source = '';
    String result = 'unknown';
    try {
      final parts = equippedRef.split('/');
      if (parts.length == 2 && parts[0] == 'catalogAvatarsGlobal') {
        avatarId = parts[1];
        source = 'global';
      } else if (parts.length == 4 &&
          parts[0] == 'gyms' &&
          parts[2] == 'avatarCatalog') {
        avatarId = parts[3];
        source = 'gym:${parts[1]}';
      } else {
        throw EquipAvatarException('invalid_ref');
      }

      final catalogSnap = await _firestore.doc(equippedRef).get();
      if (!catalogSnap.exists) {
        throw EquipAvatarException('invalid_ref');
      }

      final owned = await _inventory.getOwnedAvatarIds();
      if (!owned.contains(avatarId)) {
        throw EquipAvatarException('not_owned');
      }

      if (source.startsWith('gym:')) {
        final gymId = source.split(':')[1];
        final ownedDoc = await _firestore
            .collection('users')
            .doc(uid)
            .collection('avatarsOwned')
            .doc(avatarId)
            .get();
        final ownedSource = ownedDoc.data()?['source'] as String? ?? 'global';
        if (ownedSource != 'gym:$gymId') {
          throw EquipAvatarException('cross_gym_forbidden');
        }
        final memberSnap = await _firestore
            .collection('gyms')
            .doc(gymId)
            .collection('users')
            .doc(uid)
            .get();
        if (!memberSnap.exists) {
          throw EquipAvatarException('not_member');
        }
      }

      final prev = _equippedRef;
      _equippedRef = equippedRef;
      try {
        await _firestore
            .collection('users')
            .doc(uid)
            .set({'equippedAvatarRef': equippedRef}, SetOptions(merge: true));
      } on FirebaseException catch (e) {
        _equippedRef = prev;
        if (e.code == 'permission-denied') {
          throw EquipAvatarException('write_denied');
        }
        throw EquipAvatarException('unknown');
      }

      result = 'success';
      _telemetry?.avatarEquipSuccess();
    } on EquipAvatarException catch (e) {
      result = e.code;
      rethrow;
    } finally {
      _telemetry?.avatarEquipAttempt(
          avatarId: avatarId, source: source, result: result);
    }
  }
}
