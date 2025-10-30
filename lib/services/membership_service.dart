import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
  static const int _maxMemberNumber = 9999;

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
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore
            .collection('gyms')
            .doc(gymId)
            .collection('users')
            .doc(uid);
        final onboardingRef = _firestore
            .collection('gyms')
            .doc(gymId)
            .collection('config')
            .doc('onboarding');

        final userSnap = await transaction.get(userRef);
        final data = userSnap.data();
        final hasMemberNumber = data?['memberNumber'] != null;
        if (hasMemberNumber) {
          return;
        }

        var nextMemberNumber = 1;
        final onboardingSnap = await transaction.get(onboardingRef);
        if (onboardingSnap.exists) {
          final stored = onboardingSnap.data()?['nextMemberNumber'];
          if (stored is int && stored > 0) {
            nextMemberNumber = stored;
          } else if (stored is num && stored > 0) {
            nextMemberNumber = stored.toInt();
          } else if (stored is String) {
            final parsed = int.tryParse(stored);
            if (parsed != null && parsed > 0) {
              nextMemberNumber = parsed;
            }
          }
        }

        if (nextMemberNumber > _maxMemberNumber) {
          throw StateError('Member number pool exhausted');
        }

        transaction.set(
          onboardingRef,
          {'nextMemberNumber': nextMemberNumber + 1},
          SetOptions(merge: true),
        );

        final role = (data != null && data['role'] is String &&
                (data['role'] as String).isNotEmpty)
            ? data['role'] as String
            : 'member';
        final updates = <String, dynamic>{
          'role': role,
          'memberNumber': _formatMemberNumber(nextMemberNumber),
        };

        if (data == null || data['createdAt'] == null) {
          updates['createdAt'] = FieldValue.serverTimestamp();
        }

        transaction.set(userRef, updates, SetOptions(merge: true));
      });
      _ensured.add(key);
      _log('ENSURE_MEMBERSHIP success gymId=$gymId uid=$uid');
    } catch (e, st) {
      _log('ENSURE_MEMBERSHIP fail gymId=$gymId uid=$uid error=$e', st);
      rethrow;
    }
  }

  String _formatMemberNumber(int value) {
    return value.toString().padLeft(4, '0');
  }
}
