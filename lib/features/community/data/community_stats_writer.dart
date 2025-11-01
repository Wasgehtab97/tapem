import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/time/logic_day.dart';

class CommunityStatsAlreadyAppliedException implements Exception {
  const CommunityStatsAlreadyAppliedException();
}

class CommunityStatsWriter {
  CommunityStatsWriter({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> recordSession({
    required String gymId,
    required String sessionId,
    required String userId,
    required String? username,
    required DateTime localTimestamp,
    required List<Map<String, dynamic>> sets,
  }) async {
    if (gymId.isEmpty || sessionId.isEmpty || userId.isEmpty) {
      return;
    }

    final totals = _aggregate(sets);
    final localDay = DateTime(localTimestamp.year, localTimestamp.month,
        localTimestamp.day);
    final dayKey = logicDayKey(localDay);
    final utcMidnight = localDay.toUtc();
    final trimmedUsername = username?.trim();

    final gymRef = _firestore.collection('gyms').doc(gymId);
    final appliedRef = gymRef.collection('stats_applied').doc(sessionId);
    final statsRef = gymRef.collection('stats_daily').doc(dayKey);
    final feedRef = gymRef.collection('feed_events').doc();

    await _firestore.runTransaction((transaction) async {
      final appliedSnap = await transaction.get(appliedRef);
      if (appliedSnap.exists) {
        throw const CommunityStatsAlreadyAppliedException();
      }

      transaction.set(appliedRef, {
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.set(
        statsRef,
        {
          'date': Timestamp.fromDate(utcMidnight),
          'dayKey': dayKey,
        },
        SetOptions(merge: true),
      );

      transaction.update(statsRef, {
        'repsTotal': FieldValue.increment(totals.reps),
        'volumeTotal': FieldValue.increment(totals.volume),
        'trainingSessions': FieldValue.increment(1),
      });

      final feedData = {
        'type': 'session_summary',
        'createdAt': FieldValue.serverTimestamp(),
        'userId': userId,
        'dayKey': dayKey,
        'reps': totals.reps,
        'volume': totals.volume,
      };
      if (trimmedUsername != null && trimmedUsername.isNotEmpty) {
        feedData['username'] = trimmedUsername;
      }
      transaction.set(feedRef, feedData);
    });
  }

  _CommunityTotals _aggregate(List<Map<String, dynamic>> sets) {
    var reps = 0;
    var volume = 0.0;
    for (final set in sets) {
      final setReps = _parseReps(set['reps']);
      reps += setReps;
      if (!_isBodyweight(set['isBodyweight'])) {
        final weight = _parseWeight(set['weight']);
        if (weight > 0 && setReps > 0) {
          volume += weight * setReps;
        }
      }
    }
    final normalizedVolume = double.parse(volume.toStringAsFixed(2));
    return _CommunityTotals(reps: reps, volume: normalizedVolume);
  }

  int _parseReps(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) {
      return int.tryParse(raw.trim()) ?? 0;
    }
    return 0;
  }

  double _parseWeight(dynamic raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String) {
      final normalized = raw.replaceAll(',', '.');
      return double.tryParse(normalized) ?? 0;
    }
    return 0;
  }

  bool _isBodyweight(dynamic raw) {
    if (raw is bool) return raw;
    if (raw is String) {
      final lower = raw.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    return false;
  }
}

class _CommunityTotals {
  const _CommunityTotals({required this.reps, required this.volume});

  final int reps;
  final double volume;
}
