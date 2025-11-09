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
    required String? avatarUrl,
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

    final sanitizedAvatar = avatarUrl?.trim();

    final gymRef = _firestore.collection('gyms').doc(gymId);
    final appliedRef = gymRef.collection('stats_applied').doc(sessionId);
    final statsRef = gymRef.collection('stats_daily').doc(dayKey);
    final feedRef =
        gymRef.collection('feed_events').doc('${dayKey}_$userId');

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

      final feedData = <String, dynamic>{
        'type': 'day_summary',
        'createdAt': FieldValue.serverTimestamp(),
        'userId': userId,
        'dayKey': dayKey,
        'reps': FieldValue.increment(totals.reps),
        'volume': FieldValue.increment(totals.volume),
        'sessionCount': FieldValue.increment(1),
        'exerciseCount': FieldValue.increment(totals.exerciseCount),
        'setCount': FieldValue.increment(totals.setCount),
      };
      if (trimmedUsername != null && trimmedUsername.isNotEmpty) {
        feedData['username'] = trimmedUsername;
      }
      if (sanitizedAvatar != null && sanitizedAvatar.isNotEmpty) {
        feedData['avatarUrl'] = sanitizedAvatar;
      }
      transaction.set(feedRef, feedData, SetOptions(merge: true));
    });
  }

  _CommunityTotals _aggregate(List<Map<String, dynamic>> sets) {
    var reps = 0;
    var volume = 0.0;
    var setCount = 0;
    final exerciseIds = <String>{};
    for (final set in sets) {
      final setReps = _parseReps(set['reps']);
      reps += setReps;
      if (setReps > 0) {
        setCount++;
      }
      if (!_isBodyweight(set['isBodyweight'])) {
        final weight = _parseWeight(set['weight']);
        if (weight > 0 && setReps > 0) {
          volume += weight * setReps;
        }
      }
      final exerciseId = _parseExerciseId(set['exerciseId']);
      if (exerciseId != null) {
        exerciseIds.add(exerciseId);
      }
    }
    final normalizedVolume = double.parse(volume.toStringAsFixed(2));
    final exerciseCount = exerciseIds.isEmpty
        ? (setCount > 0 ? 1 : 0)
        : exerciseIds.length;
    return _CommunityTotals(
      reps: reps,
      volume: normalizedVolume,
      setCount: setCount,
      exerciseCount: exerciseCount,
    );
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

  String? _parseExerciseId(dynamic raw) {
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }
}

class _CommunityTotals {
  const _CommunityTotals({
    required this.reps,
    required this.volume,
    required this.setCount,
    required this.exerciseCount,
  });

  final int reps;
  final double volume;
  final int setCount;
  final int exerciseCount;
}
