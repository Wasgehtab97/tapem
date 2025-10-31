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
    String? desiredRole,
  });
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
  Future<void> ensureMembership(
    String gymId,
    String uid, {
    String? desiredRole,
  }) async {
    final normalizedDesiredRole = _readString(desiredRole) ?? '';
    final key = normalizedDesiredRole.isEmpty
        ? '$gymId|$uid'
        : '$gymId|$uid|$normalizedDesiredRole';
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

        final profileRef = _firestore.collection('users').doc(uid);
        final profileSnap = await transaction.get(profileRef);
        final profileData = profileSnap.data();

        final resolvedRole = _resolveRole(
          membershipData: data,
          profileData: profileData,
          desiredRole: normalizedDesiredRole,
        );

        final existingMemberNumber =
            _resolveExistingMemberNumber(data) ?? _resolveExistingMemberNumber(profileData);
        final existingMemberNumberInt =
            existingMemberNumber != null ? int.tryParse(existingMemberNumber) : null;

        var nextMemberNumber = existingMemberNumberInt;
        var formattedNumber = existingMemberNumber;
        var assignedNewNumber = false;

        if (nextMemberNumber == null || formattedNumber == null) {
          nextMemberNumber = await _acquireNextMemberNumber(
            transaction,
            onboardingRef,
            uid,
          );
          formattedNumber = _formatMemberNumber(nextMemberNumber);
          assignedNewNumber = true;
        }

        final resolvedNumber = nextMemberNumber!;
        final resolvedFormatted = formattedNumber!;

        final updates = <String, dynamic>{
          'role': resolvedRole,
          'memberNumber': resolvedFormatted,
          'memberNumberNormalized': resolvedFormatted,
          'memberNumberInt': resolvedNumber,
          'memberNumberNumeric': resolvedNumber,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (data == null || data['createdAt'] == null) {
          updates['createdAt'] = FieldValue.serverTimestamp();
        }

        if (assignedNewNumber) {
          updates['memberNumberAssignedAt'] = FieldValue.serverTimestamp();
        }

        transaction.set(userRef, updates, SetOptions(merge: true));

        final profileUpdates = _buildProfileUpdates(
          profileSnapExists: profileSnap.exists,
          profileData: profileData,
          role: resolvedRole,
          gymId: gymId,
        );

        if (profileUpdates != null) {
          transaction.set(profileRef, profileUpdates, SetOptions(merge: true));
        }
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

  Future<int> _acquireNextMemberNumber(
    Transaction transaction,
    DocumentReference<Map<String, dynamic>> onboardingRef,
    String uid,
  ) async {
    var nextMemberNumber = 1;
    final onboardingSnap = await transaction.get(onboardingRef);
    if (onboardingSnap.exists) {
      final stored = onboardingSnap.data()?['nextMemberNumber'];
      final parsed = _tryParseInt(stored);
      if (parsed != null && parsed > 0) {
        nextMemberNumber = parsed;
      }
    }

    if (nextMemberNumber > _maxMemberNumber) {
      throw StateError('Member number pool exhausted');
    }

    final formattedNumber = _formatMemberNumber(nextMemberNumber);

    transaction.set(
      onboardingRef,
      {
        'nextMemberNumber': nextMemberNumber + 1,
        'lastAssignedNumber': formattedNumber,
        'lastAssignedUserId': uid,
        'lastAssignedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return nextMemberNumber;
  }

  String _resolveRole({
    Map<String, dynamic>? membershipData,
    Map<String, dynamic>? profileData,
    String? desiredRole,
  }) {
    final candidates = <String?>[
      desiredRole,
      _readString(profileData?['role']),
      _readString(membershipData?['role']),
      'member',
    ];
    for (final candidate in candidates) {
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }
    return 'member';
  }

  String? _resolveExistingMemberNumber(Map<String, dynamic>? data) {
    if (data == null) return null;
    final candidates = [
      data['memberNumberNormalized'],
      data['memberNumber'],
      data['memberNumberString'],
    ];
    for (final candidate in candidates) {
      final normalized = _normalizeMemberNumber(candidate);
      if (normalized != null) {
        return normalized;
      }
    }

    final numeric = _tryParseInt(
      data['memberNumberInt'] ??
          data['memberNumberNumeric'] ??
          data['memberNumberNumber'] ??
          data['memberNumberDigits'],
    );
    if (numeric != null && numeric > 0) {
      return _formatMemberNumber(numeric);
    }
    return null;
  }

  int? _tryParseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isEmpty) return null;
      return int.tryParse(digits);
    }
    return null;
  }

  String? _normalizeMemberNumber(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isEmpty) return null;
      final parsed = int.tryParse(digits);
      if (parsed == null) return null;
      return _formatMemberNumber(parsed);
    }
    final parsed = _tryParseInt(value);
    if (parsed == null) return null;
    return _formatMemberNumber(parsed);
  }

  String? _readString(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return trimmed;
    }
    return null;
  }

  Map<String, dynamic>? _buildProfileUpdates({
    required bool profileSnapExists,
    required Map<String, dynamic>? profileData,
    required String role,
    required String gymId,
  }) {
    final updates = <String, dynamic>{};

    final existingRole = _readString(profileData?['role']);
    if (existingRole == null || existingRole != role) {
      updates['role'] = role;
    }

    final existingGymCodes = <String>{};
    final rawGymCodes = profileData?['gymCodes'];
    if (rawGymCodes is Iterable) {
      for (final entry in rawGymCodes) {
        final code = _readString(entry);
        if (code != null) {
          existingGymCodes.add(code);
        }
      }
    }
    if (!existingGymCodes.contains(gymId)) {
      updates['gymCodes'] = FieldValue.arrayUnion([gymId]);
    }

    if (updates.isEmpty && profileSnapExists) {
      return null;
    }

    updates['updatedAt'] = FieldValue.serverTimestamp();
    if (!profileSnapExists) {
      updates['createdAt'] = FieldValue.serverTimestamp();
      updates['showInLeaderboard'] = true;
      updates['publicProfile'] = false;
    }

    return updates;
  }
}
