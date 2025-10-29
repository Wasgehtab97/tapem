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
  Future<void> ensureMembership(
    String gymId,
    String uid, {
    DateTime? createdAt,
  });
}

class FirestoreMembershipService implements MembershipService {
  static const int _maxMemberNumber = 9999;
  static const int _memberNumberLength = 4;

  final FirebaseFirestore _firestore;
  final LogFn _log;
  final Set<String> _ensured = {};

  FirestoreMembershipService({FirebaseFirestore? firestore, LogFn? log})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _log = log ?? _defaultLog;

  @override
  Future<void> ensureMembership(
    String gymId,
    String uid, {
    DateTime? createdAt,
  }) async {
    final key = '$gymId|$uid';
    if (_ensured.contains(key)) return;
    _log('ENSURE_MEMBERSHIP start gymId=$gymId uid=$uid');
    try {
      final gymRef = _firestore.collection('gyms').doc(gymId);
      final memberRef = gymRef.collection('users').doc(uid);
      final configRef = gymRef.collection('config').doc('onboarding');

      await _firestore.runTransaction((transaction) async {
        final memberSnap = await transaction.get(memberRef);
        final existingData = memberSnap.data();
        final existingNumber =
            (existingData?['memberNumber'] as String?)?.trim() ?? '';

        final createdAtValue = existingData != null &&
                existingData.containsKey('createdAt') &&
                existingData['createdAt'] != null
            ? existingData['createdAt']
            : (createdAt ?? DateTime.now());

        final baseMembershipData = <String, dynamic>{
          'role': 'member',
          'createdAt': createdAtValue,
        };

        if (existingNumber.isNotEmpty) {
          transaction.set(
            memberRef,
            baseMembershipData,
            SetOptions(merge: true),
          );
          return;
        }

        final configSnap = await transaction.get(configRef);
        final configData = configSnap.data();
        var nextNumber = 1;
        final configNext = configData?['nextMemberNumber'];
        if (configNext is int && configNext > 0) {
          nextNumber = configNext;
        }

        if (nextNumber > _maxMemberNumber) {
          transaction.set(
            configRef,
            {
              'nextMemberNumber': nextNumber,
              'limitReachedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
          throw StateError('member_number_limit_reached');
        }

        final formattedNumber =
            nextNumber.toString().padLeft(_memberNumberLength, '0');

        transaction.set(
          memberRef,
          {
            ...baseMembershipData,
            'memberNumber': formattedNumber,
            'onboardingAssignedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        transaction.set(
          configRef,
          {
            'nextMemberNumber': nextNumber + 1,
            'lastAssignedNumber': formattedNumber,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      _ensured.add(key);
      _log('ENSURE_MEMBERSHIP success gymId=$gymId uid=$uid');
    } on FirebaseException catch (e, st) {
      _log('ENSURE_MEMBERSHIP fail gymId=$gymId uid=$uid error=${e.code}', st);
      rethrow;
    } on StateError catch (e, st) {
      _log('ENSURE_MEMBERSHIP fail gymId=$gymId uid=$uid error=$e', st);
      rethrow;
    } catch (e, st) {
      _log('ENSURE_MEMBERSHIP fail gymId=$gymId uid=$uid error=$e', st);
      rethrow;
    }
  }
}
