import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tapem/core/time/logic_day.dart';
import 'package:tapem/features/device/domain/models/device_session_snapshot.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';
import 'package:tapem/features/training_details/data/repositories/session_repository_impl.dart';
import 'package:tapem/features/training_details/data/session_meta_source.dart';
import 'package:tapem/features/training_details/data/sources/firestore_session_source.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';
import 'package:tapem/features/session_story/domain/models/session_story.dart';

class SessionStoryService {
  final FirebaseFirestore _firestore;
  final SessionRepositoryImpl _sessionRepository;

  SessionStoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _sessionRepository = SessionRepositoryImpl(
          FirestoreSessionSource(firestore: firestore),
          SessionMetaSource(firestore: firestore),
        );

  Future<SessionStory?> buildStory({
    required String gymId,
    required String userId,
    required String dayKey,
  }) async {
    final date = _parseDayKey(dayKey);
    final sessions = await _sessionRepository.getSessionsForDate(
      userId: userId,
      date: date,
    );
    if (sessions.isEmpty) {
      return null;
    }

    final comboMap = _groupSessionsByCombo(sessions);
    final highlights = <SessionStoryHighlight>[];

    for (final entry in comboMap.entries) {
      final combo = entry.value;
      final historical = await _loadHistoricalStats(
        gymId: gymId,
        userId: userId,
        combo: combo,
        dayKey: dayKey,
      );
      final dayMetrics = _computeDayMetrics(combo);
      highlights.addAll(
        _buildHighlights(
          combo: combo,
          dayMetrics: dayMetrics,
          historical: historical,
        ),
      );
    }

    final xpSummary = await _buildXpSummary(
      gymId: gymId,
      userId: userId,
      dayKey: dayKey,
      sessions: sessions,
    );
    final totalDurationMs = sessions.fold<int>(
      0,
      (value, session) => value + (session.durationMs ?? 0),
    );

    return SessionStory(
      dayKey: dayKey,
      day: date,
      highlights: highlights,
      xpSummary: xpSummary,
      sessionCount: sessions.length,
      totalDuration: totalDurationMs > 0
          ? Duration(milliseconds: totalDurationMs)
          : null,
      sessions: sessions,
    );
  }

  DateTime _parseDayKey(String dayKey) {
    try {
      return DateTime.parse(dayKey);
    } catch (_) {
      final parts = dayKey.split('-').map(int.tryParse).toList();
      if (parts.length >= 3 && parts[0] != null && parts[1] != null && parts[2] != null) {
        return DateTime(parts[0]!, parts[1]!, parts[2]!);
      }
      return DateTime.now();
    }
  }

  Map<_SessionComboKey, _SessionCombo> _groupSessionsByCombo(
    List<Session> sessions,
  ) {
    final map = <_SessionComboKey, _SessionCombo>{};
    for (final session in sessions) {
      final key = _SessionComboKey(
        deviceId: session.deviceId,
        exerciseId: session.exerciseId ?? '',
      );
      map.putIfAbsent(
        key,
        () => _SessionCombo(
          deviceId: session.deviceId,
          canonicalDeviceName: session.canonicalDeviceName,
          isMulti: session.isMultiDevice,
          exerciseId: session.exerciseId,
          exerciseName: session.exerciseName,
        ),
      );
      map[key]!.sessions.add(session);
    }
    return map;
  }

  Future<_HistoricalStats> _loadHistoricalStats({
    required String gymId,
    required String userId,
    required _SessionCombo combo,
    required String dayKey,
  }) async {
    final deviceRef = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(combo.deviceId)
        .collection('sessions');
    Query<Map<String, dynamic>> query = deviceRef.where(
      'userId',
      isEqualTo: userId,
    );
    query = query.orderBy('createdAt', descending: true).limit(500);

    try {
      final snap = await query.get();
      var hadPrevious = false;
      var bestE1rm = 0.0;
      var bestVolume = 0.0;
      for (final doc in snap.docs) {
        if (combo.sessionIds.contains(doc.id)) {
          continue;
        }
        final data = Map<String, dynamic>.from(doc.data());
        data['sessionId'] ??= doc.id;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        if (createdAt == null) {
          continue;
        }
        final sessionDay = logicDayKey(createdAt);
        if (sessionDay == dayKey) {
          continue;
        }
        final snapshot = DeviceSessionSnapshot.fromJson(data);
        if (!_matchesExercise(combo, snapshot.exerciseId)) {
          continue;
        }
        hadPrevious = true;
        final metrics = _computeSnapshotMetrics(snapshot);
        bestE1rm = math.max(bestE1rm, metrics.maxE1rm);
        bestVolume = math.max(bestVolume, metrics.totalVolume);
      }
      return _HistoricalStats(
        hasPrevious: hadPrevious,
        bestE1rm: bestE1rm,
        bestVolume: bestVolume,
      );
    } on FirebaseException {
      return const _HistoricalStats();
    }
  }

  bool _matchesExercise(_SessionCombo combo, String? exerciseId) {
    final wanted = combo.exerciseId ?? '';
    if (wanted.isEmpty) {
      return exerciseId == null || exerciseId.isEmpty;
    }
    return exerciseId == wanted;
  }

  _SessionMetrics _computeSessionMetrics(Session session) {
    var maxE1rm = 0.0;
    var totalVolume = 0.0;
    for (final set in session.sets) {
      final weight = set.weight;
      final reps = set.reps;
      final e1rm = weight * (1 + reps / 30);
      maxE1rm = math.max(maxE1rm, e1rm);
      totalVolume += weight * reps;
      if (set.dropWeightKg != null && set.dropReps != null) {
        final dropWeight = set.dropWeightKg!;
        final dropReps = set.dropReps!;
        final dropE1rm = dropWeight * (1 + dropReps / 30);
        maxE1rm = math.max(maxE1rm, dropE1rm);
        totalVolume += dropWeight * dropReps;
      }
    }
    return _SessionMetrics(maxE1rm: maxE1rm, totalVolume: totalVolume);
  }

  _SessionMetrics _computeSnapshotMetrics(DeviceSessionSnapshot snapshot) {
    var maxE1rm = 0.0;
    var totalVolume = 0.0;
    for (final set in snapshot.sets) {
      final weight = set.kg.toDouble();
      final reps = set.reps;
      final e1rm = weight * (1 + reps / 30);
      maxE1rm = math.max(maxE1rm, e1rm);
      totalVolume += weight * reps;
      for (final drop in set.drops) {
        final dropWeight = drop.kg.toDouble();
        final dropReps = drop.reps;
        final dropE1rm = dropWeight * (1 + dropReps / 30);
        maxE1rm = math.max(maxE1rm, dropE1rm);
        totalVolume += dropWeight * dropReps;
      }
    }
    return _SessionMetrics(maxE1rm: maxE1rm, totalVolume: totalVolume);
  }

  _DayMetrics _computeDayMetrics(_SessionCombo combo) {
    var bestE1rm = 0.0;
    var bestVolume = 0.0;
    for (final session in combo.sessions) {
      final metrics = _computeSessionMetrics(session);
      bestE1rm = math.max(bestE1rm, metrics.maxE1rm);
      bestVolume = math.max(bestVolume, metrics.totalVolume);
    }
    return _DayMetrics(bestE1rm: bestE1rm, bestVolume: bestVolume);
  }

  Iterable<SessionStoryHighlight> _buildHighlights({
    required _SessionCombo combo,
    required _DayMetrics dayMetrics,
    required _HistoricalStats historical,
  }) {
    final highlights = <SessionStoryHighlight>[];
    if (!historical.hasPrevious) {
      if (combo.isMulti && (combo.exerciseName?.isNotEmpty ?? false)) {
        highlights.add(SessionStoryHighlight(
          type: SessionStoryHighlightType.firstExercise,
          deviceName: combo.exerciseName!,
          canonicalDeviceName: combo.canonicalDeviceName,
          exerciseName: combo.exerciseName,
        ));
      } else {
        highlights.add(SessionStoryHighlight(
          type: SessionStoryHighlightType.firstDevice,
          deviceName: combo.canonicalDeviceName,
          canonicalDeviceName: combo.canonicalDeviceName,
          exerciseName: combo.exerciseName,
        ));
      }
    }
    if (dayMetrics.bestE1rm > historical.bestE1rm + 0.01) {
      highlights.add(SessionStoryHighlight(
        type: SessionStoryHighlightType.e1rmPr,
        deviceName: combo.exerciseName ?? combo.canonicalDeviceName,
        canonicalDeviceName: combo.canonicalDeviceName,
        exerciseName: combo.exerciseName,
        metricValue: dayMetrics.bestE1rm,
      ));
    }
    if (dayMetrics.bestVolume > historical.bestVolume + 0.01) {
      highlights.add(SessionStoryHighlight(
        type: SessionStoryHighlightType.volumePr,
        deviceName: combo.exerciseName ?? combo.canonicalDeviceName,
        canonicalDeviceName: combo.canonicalDeviceName,
        exerciseName: combo.exerciseName,
        metricValue: dayMetrics.bestVolume,
      ));
    }
    return highlights;
  }

  Future<SessionStoryXpSummary> _buildXpSummary({
    required String gymId,
    required String userId,
    required String dayKey,
    required List<Session> sessions,
  }) async {
    final deviceXp = <String, SessionStoryDeviceXp>{};
    for (final session in sessions) {
      final entry = deviceXp.putIfAbsent(
        session.deviceId,
        () => SessionStoryDeviceXp(
          deviceId: session.deviceId,
          deviceName: session.deviceName,
          canonicalDeviceName: session.canonicalDeviceName,
          exerciseNames: <String>[],
          xp: 0,
          sessionCount: 0,
        ),
      );
      final exercises = <String>{...entry.exerciseNames};
      if (session.exerciseName != null && session.exerciseName!.isNotEmpty) {
        exercises.add(session.exerciseName!);
      }
      deviceXp[session.deviceId] = SessionStoryDeviceXp(
        deviceId: entry.deviceId,
        deviceName: entry.deviceName,
        canonicalDeviceName: entry.canonicalDeviceName,
        exerciseNames: exercises.toList()..sort(),
        xp: entry.xp + LevelService.xpPerSession,
        sessionCount: entry.sessionCount + 1,
      );
    }

    final muscleXp = await _loadMuscleXp(
      gymId: gymId,
      userId: userId,
      dayKey: dayKey,
    );
    final dailyXp = await _loadDailyXp(userId: userId, dayKey: dayKey);
    final totalXp = dailyXp ?? sessions.length * LevelService.xpPerSession;

    return SessionStoryXpSummary(
      dailyXp: totalXp,
      deviceXp: deviceXp.values.toList()
        ..sort((a, b) => b.xp.compareTo(a.xp)),
      muscleXp: muscleXp,
    );
  }

  Future<int?> _loadDailyXp({
    required String userId,
    required String dayKey,
  }) async {
    try {
      final ref = _firestore
          .collection('users')
          .doc(userId)
          .collection('trainingDayXP')
          .doc(dayKey);
      final snap = await ref.get();
      if (!snap.exists) return null;
      final xp = (snap.data()?['xp'] as num?)?.toInt();
      return xp;
    } on FirebaseException {
      return null;
    }
  }

  Future<List<SessionStoryMuscleXp>> _loadMuscleXp({
    required String gymId,
    required String userId,
    required String dayKey,
  }) async {
    try {
      final doc = await _firestore
          .collection('gyms')
          .doc(gymId)
          .collection('users')
          .doc(userId)
          .collection('rank')
          .doc('stats')
          .collection('muscleXpHistory')
          .doc(dayKey)
          .get();
      if (!doc.exists) return const [];
      final data = doc.data() ?? {};
      final list = <SessionStoryMuscleXp>[];
      data.forEach((key, value) {
        if (key.endsWith('XP') && key != 'dailyXP') {
          final group = key.substring(0, key.length - 2);
          final xp = (value as num?)?.toInt() ?? 0;
          if (xp > 0) {
            list.add(SessionStoryMuscleXp(muscleGroupId: group, xp: xp));
          }
        }
      });
      list.sort((a, b) => b.xp.compareTo(a.xp));
      return list;
    } on FirebaseException {
      return const [];
    }
  }
}

class _SessionComboKey {
  final String deviceId;
  final String exerciseId;

  const _SessionComboKey({required this.deviceId, required this.exerciseId});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _SessionComboKey &&
        other.deviceId == deviceId &&
        other.exerciseId == exerciseId;
  }

  @override
  int get hashCode => Object.hash(deviceId, exerciseId);
}

class _SessionCombo {
  final String deviceId;
  final String canonicalDeviceName;
  final bool isMulti;
  final String? exerciseId;
  final String? exerciseName;
  final List<Session> sessions = [];

  _SessionCombo({
    required this.deviceId,
    required this.canonicalDeviceName,
    required this.isMulti,
    this.exerciseId,
    this.exerciseName,
  });

  Set<String> get sessionIds => sessions.map((s) => s.sessionId).toSet();
}

class _HistoricalStats {
  final bool hasPrevious;
  final double bestE1rm;
  final double bestVolume;

  const _HistoricalStats({
    this.hasPrevious = false,
    this.bestE1rm = 0,
    this.bestVolume = 0,
  });
}

class _SessionMetrics {
  final double maxE1rm;
  final double totalVolume;

  const _SessionMetrics({required this.maxE1rm, required this.totalVolume});
}

class _DayMetrics {
  final double bestE1rm;
  final double bestVolume;

  const _DayMetrics({required this.bestE1rm, required this.bestVolume});
}
