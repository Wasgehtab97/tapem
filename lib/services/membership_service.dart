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
      await _firestore
          .collection('gyms')
          .doc(gymId)
          .collection('users')
          .doc(uid)
          .set({'role': 'member'}, SetOptions(merge: true));
      _ensured.add(key);
      _log('ENSURE_MEMBERSHIP success gymId=$gymId uid=$uid');
    } catch (e, st) {
      _log('ENSURE_MEMBERSHIP fail gymId=$gymId uid=$uid error=$e', st);
      rethrow;
    }
  }
}
