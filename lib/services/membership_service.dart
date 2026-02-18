import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'member_number_utils.dart';

typedef LogFn = void Function(String message, [StackTrace? stack]);

void _defaultLog(String message, [StackTrace? stack]) {
  if (stack != null) {
    debugPrintStack(label: message, stackTrace: stack);
  } else {
    debugPrint(message);
  }
}

abstract class MembershipService {
  Future<void> ensureMembership(String gymId, String uid);
}

class FirestoreMembershipService implements MembershipService {
  final FirebaseFirestore _firestore;
  final LogFn _log;
  final Set<String> _ensured = {};

  FirestoreMembershipService({FirebaseFirestore? firestore, LogFn? log})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _log = log ?? _defaultLog;

  @override
  Future<void> ensureMembership(String gymId, String uid) async {
    final key = '$gymId|$uid';
    if (_ensured.contains(key)) return;
    _log('ENSURE_MEMBERSHIP start gymId=$gymId uid=$uid');
    try {
      await _firestore.runTransaction((tx) async {
        final gymRef = _firestore.collection('gyms').doc(gymId);
        final membershipRef = gymRef.collection('users').doc(uid);

        final membershipSnap = await tx.get(membershipRef);
        final updates = <String, dynamic>{};

        final hasRole =
            membershipSnap.exists &&
            membershipSnap.data() != null &&
            (membershipSnap.data() as Map<String, dynamic>).containsKey('role');
        if (!hasRole) {
          updates['role'] = 'member';
        }
        var needsMemberNumber = true;
        if (membershipSnap.exists) {
          final data = membershipSnap.data();
          final current = data?['memberNumber'];
          needsMemberNumber = current is! String || current.trim().isEmpty;
        } else {
          updates['createdAt'] = DateTime.now();
        }

        if (needsMemberNumber) {
          final gymSnap = await tx.get(gymRef);
          final nextNumber = nextMemberNumber(gymSnap.data(), gymId: gymId);
          updates['memberNumber'] = formatMemberNumber(nextNumber);
          updateMemberNumberCounter(tx, gymRef, nextNumber);
        }

        tx.set(membershipRef, updates, SetOptions(merge: true));
      });
      _ensured.add(key);
      _log('ENSURE_MEMBERSHIP success gymId=$gymId uid=$uid');
    } catch (e, st) {
      if (_isTransientNetworkFailure(e)) {
        // Offline mode: do not block read paths that can fall back to local
        // caches. Remote writes will retry once connectivity is restored.
        _log(
          'ENSURE_MEMBERSHIP skipped (transient/offline) gymId=$gymId uid=$uid error=$e',
        );
        return;
      }
      _log('ENSURE_MEMBERSHIP fail gymId=$gymId uid=$uid error=$e', st);
      rethrow;
    }
  }

  bool _isTransientNetworkFailure(Object error) {
    if (error is FirebaseException) {
      final code = _normalizeErrorCode(error.code);
      return code == 'unavailable' ||
          code == 'deadline-exceeded' ||
          code == 'aborted' ||
          code == 'network-request-failed' ||
          code == 'timeout';
    }
    final message = error.toString().toLowerCase();
    return message.contains('network error') ||
        message.contains('unavailable') ||
        message.contains('unreachable host') ||
        message.contains('timeout');
  }

  String _normalizeErrorCode(String raw) {
    final code = raw.trim().toLowerCase();
    if (code.contains('/')) {
      return code.split('/').last;
    }
    return code;
  }
}

final membershipServiceProvider = Provider<MembershipService>((ref) {
  return FirestoreMembershipService(firestore: FirebaseFirestore.instance);
});
