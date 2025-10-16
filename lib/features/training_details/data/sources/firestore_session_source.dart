import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../dtos/session_dto.dart';

/// Liest alle Log‐Einträge (collectionGroup "logs") für ein Datum aus.
class FirestoreSessionSource {
  final FirebaseFirestore _firestore;

  FirestoreSessionSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<SessionDto>> getSessionsForDate({
    required String userId,
    required DateTime date,
  }) async {
    final dayKey = _formatDayKey(date);
    final summaryRef = _firestore
        .collection('trainingSummary')
        .doc(userId)
        .collection('daily')
        .doc(dayKey);

    try {
      final summarySnap = await summaryRef.get();
      if (!summarySnap.exists) {
        return const <SessionDto>[];
      }
      final summary = summarySnap.data();
      final sessionCounts = summary?['sessionCounts'];
      if (sessionCounts is! Map<String, dynamic> || sessionCounts.isEmpty) {
        return const <SessionDto>[];
      }

      final targets = <_SessionTarget>[];
      sessionCounts.forEach((sessionId, raw) {
        if (sessionId.isEmpty) {
          return;
        }
        if (raw is Map<String, dynamic>) {
          final count = (raw['count'] as num?)?.toInt() ?? 0;
          if (count <= 0) {
            return;
          }
          final gymId = raw['gymId'] as String?;
          final deviceId = raw['deviceId'] as String?;
          if (gymId != null && gymId.isNotEmpty && deviceId != null && deviceId.isNotEmpty) {
            targets.add(_SessionTarget(sessionId: sessionId, gymId: gymId, deviceId: deviceId));
          }
        }
      });

      if (targets.isEmpty) {
        return const <SessionDto>[];
      }

      final results = <SessionDto>[];
      for (final target in targets) {
        final entries = await _fetchSessionLogs(
          gymId: target.gymId,
          deviceId: target.deviceId,
          sessionId: target.sessionId,
          userId: userId,
        );
        results.addAll(entries);
      }
      return results;
    } on FirebaseException catch (e) {
      debugPrint('FirestoreSessionSource: failure path=trainingSummary owner=' +
          userId +
          ' code=' +
          e.code);
      rethrow;
    }
  }

  Future<void> backfillSetNumbers(List<SessionDto> dtos) async {
    final batch = _firestore.batch();
    for (var i = 0; i < dtos.length; i++) {
      batch.update(dtos[i].reference, {
        'setNumber': i + 1,
        'backfilled': true,
      });
    }
    await batch.commit();
  }

  Future<List<SessionDto>> getSessionEntries({
    required String gymId,
    required String deviceId,
    required String sessionId,
    required String userId,
  }) async {
    return _fetchSessionLogs(
      gymId: gymId,
      deviceId: deviceId,
      sessionId: sessionId,
      userId: userId,
    );
  }

  Future<void> deleteSessionEntries(List<SessionDto> entries) async {
    if (entries.isEmpty) return;
    const chunkSize = 450;
    var index = 0;
    while (index < entries.length) {
      final batch = _firestore.batch();
      final slice = entries.skip(index).take(chunkSize);
      for (final entry in slice) {
        batch.delete(entry.reference);
      }
      await batch.commit();
      index += chunkSize;
    }
  }
}

const int _kLogPageSize = 50;

extension on FirestoreSessionSource {
  Future<List<SessionDto>> _fetchSessionLogs({
    required String gymId,
    required String deviceId,
    required String sessionId,
    required String userId,
  }) async {
    final collection = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('logs');

    final results = <SessionDto>[];
    DocumentSnapshot<Map<String, dynamic>>? lastDoc;
    while (true) {
      var query = collection
          .where('sessionId', isEqualTo: sessionId)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: false)
          .limit(_kLogPageSize);
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }
      final snap = await query.get();
      if (snap.docs.isEmpty) {
        break;
      }
      results.addAll(snap.docs.map(SessionDto.fromFirestore));
      if (snap.docs.length < _kLogPageSize) {
        break;
      }
      lastDoc = snap.docs.last;
    }
    return results;
  }
}

String _formatDayKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _SessionTarget {
  _SessionTarget({
    required this.sessionId,
    required this.gymId,
    required this.deviceId,
  });

  final String sessionId;
  final String gymId;
  final String deviceId;
}
