import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/core/storage/daily_stats_cache_store.dart';
import 'package:tapem/core/time/logic_day.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';

import 'data/story_session_history_store.dart';
import 'data/story_session_pr_store.dart';
import 'data/story_session_summary_store.dart';
import 'domain/models/story_achievement.dart';
import 'domain/models/story_session_summary.dart';

class StorySessionService {
  StorySessionService({
    FirebaseFirestore? firestore,
    DailyStatsCache? dailyStatsCache,
    StorySessionSummaryStore? summaryStore,
    StorySessionHistoryStore? historyStore,
    StorySessionPrStore? prStore,
    DateTime Function()? now,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _dailyStatsCache = dailyStatsCache ?? const DailyStatsCacheStore(),
        _summaryStore = summaryStore ?? const StorySessionSummaryStore(),
        _historyStore = historyStore ?? const StorySessionHistoryStore(),
        _prStore = prStore ?? const StorySessionPrStore(),
        _now = now ?? DateTime.now;

  final FirebaseFirestore _firestore;
  final DailyStatsCache _dailyStatsCache;
  final StorySessionSummaryStore _summaryStore;
  final StorySessionHistoryStore _historyStore;
  final StorySessionPrStore _prStore;
  final DateTime Function() _now;

  Future<StorySessionSummary?> getSummary({
    required String gymId,
    required String userId,
    required DateTime date,
    required List<Session> sessions,
  }) async {
    final dayKey = logicDayKey(date);
    if (sessions.isEmpty) {
      return StorySessionSummary(
        gymId: gymId,
        userId: userId,
        dayKey: dayKey,
        totalXp: 0,
        generatedAt: _now(),
        achievements: const [],
      );
    }

    final cached = await _summaryStore.read(gymId, userId, dayKey);
    if (cached != null) {
      return cached;
    }

    final remote = await _loadRemoteSummary(gymId, userId, dayKey);
    if (remote != null) {
      await _summaryStore.write(remote);
      return remote;
    }

    final summary = await _buildSummary(
      gymId: gymId,
      userId: userId,
      date: date,
      dayKey: dayKey,
      sessions: sessions,
    );
    if (summary != null) {
      await _summaryStore.write(summary);
      await _persistRemoteSummary(summary);
    }
    return summary;
  }

  Future<StorySessionSummary?> _buildSummary({
    required String gymId,
    required String userId,
    required DateTime date,
    required String dayKey,
    required List<Session> sessions,
  }) async {
    if (sessions.isEmpty) return null;
    final generatedAt = _now();
    final xpEntry = await _dailyStatsCache.read(gymId, userId);
    final dayXp = (xpEntry != null && xpEntry.isSameCalendarDay(date))
        ? xpEntry.xp
        : 50;

    final startOfDay = DateTime(date.year, date.month, date.day);
    final newDevices = <String, Session>{};
    final newExercises = <String, Session>{};

    for (final session in sessions) {
      final deviceId = session.deviceId;
      final exerciseId = session.exerciseId;
      final hasExercise = exerciseId != null && exerciseId.isNotEmpty;

      final seenDevice = await _historyStore.hasSeenDevice(gymId, userId, deviceId);
      if (!seenDevice && !newDevices.containsKey(deviceId)) {
        final existedBefore = await _hasPriorUsage(
          gymId: gymId,
          userId: userId,
          deviceId: deviceId,
          exerciseId: null,
          before: startOfDay,
        );
        if (!existedBefore) {
          newDevices[deviceId] = session;
        }
      }

      if (hasExercise) {
        final key = '$deviceId::$exerciseId';
        final seenExercise =
            await _historyStore.hasSeenExercise(gymId, userId, deviceId, exerciseId!);
        if (!seenExercise && !newExercises.containsKey(key)) {
          final existedBefore = await _hasPriorUsage(
            gymId: gymId,
            userId: userId,
            deviceId: deviceId,
            exerciseId: exerciseId,
            before: startOfDay,
          );
          if (!existedBefore) {
            newExercises[key] = session;
          }
        }
      }
    }

    final newPrs = <String, _PrCandidate>{};
    for (final session in sessions) {
      final bestE1rm = _bestE1rmForSession(session);
      if (bestE1rm == null) continue;
      final exerciseId = session.exerciseId ?? '';
      final recordKey = '${session.deviceId}::$exerciseId';
      final previousBest = await _ensurePreviousPr(
        gymId: gymId,
        userId: userId,
        deviceId: session.deviceId,
        exerciseId: session.exerciseId,
        before: startOfDay,
      );
      if (bestE1rm > (previousBest ?? 0) + 0.01) {
        final existing = newPrs[recordKey];
        if (existing == null || bestE1rm > existing.e1rm) {
          newPrs[recordKey] = _PrCandidate(session: session, e1rm: bestE1rm);
        }
      }
    }

    final achievementsBuffer = <StoryAchievement>[
      StoryAchievement(type: StoryAchievementType.dailyXp, xp: dayXp),
    ];

    for (final entry in newDevices.values) {
      achievementsBuffer.add(
        StoryAchievement(
          type: StoryAchievementType.newDevice,
          deviceName: entry.deviceName,
        ),
      );
    }

    for (final entry in newExercises.entries) {
      final session = entry.value;
      achievementsBuffer.add(
        StoryAchievement(
          type: StoryAchievementType.newExercise,
          deviceName: session.deviceName,
          exerciseName: session.exerciseName ?? session.exerciseId,
        ),
      );
    }

    for (final candidate in newPrs.values) {
      achievementsBuffer.add(
        StoryAchievement(
          type: StoryAchievementType.personalRecord,
          deviceName: candidate.session.deviceName,
          exerciseName: candidate.session.exerciseName ?? candidate.session.exerciseId,
          e1rm: candidate.e1rm,
        ),
      );
    }

    final summary = StorySessionSummary(
      gymId: gymId,
      userId: userId,
      dayKey: dayKey,
      totalXp: dayXp,
      generatedAt: generatedAt,
      achievements: achievementsBuffer,
    );

    await _historyStore.markDeviceSeen(gymId, userId, newDevices.keys);
    await _historyStore.markExerciseSeen(
      gymId,
      userId,
      newExercises.keys.map((key) {
        final parts = key.split('::');
        return MapEntry(parts.first, parts.last);
      }),
    );
    await _prStore.write(
      gymId,
      userId,
      {
        for (final entry in newPrs.entries)
          entry.key: double.parse(entry.value.e1rm.toStringAsFixed(3)),
      },
    );

    return summary;
  }

  Future<bool> _hasPriorUsage({
    required String gymId,
    required String userId,
    required String deviceId,
    String? exerciseId,
    required DateTime before,
  }) async {
    final collection = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('logs');
    var query = collection
        .where('userId', isEqualTo: userId)
        .where('timestamp', isLessThan: Timestamp.fromDate(before));
    if (exerciseId != null && exerciseId.isNotEmpty) {
      query = query.where('exerciseId', isEqualTo: exerciseId);
    }
    try {
      final snap = await query.limit(1).get();
      return snap.docs.isNotEmpty;
    } on FirebaseException {
      return false;
    }
  }

  Future<double?> _ensurePreviousPr({
    required String gymId,
    required String userId,
    required String deviceId,
    String? exerciseId,
    required DateTime before,
  }) async {
    final key = '${deviceId}::${exerciseId ?? ''}';
    final cached = await _prStore.read(gymId, userId, key);
    if (cached != null && cached > 0) {
      return cached;
    }
    final value = await _loadPreviousBestE1rm(
      gymId: gymId,
      userId: userId,
      deviceId: deviceId,
      exerciseId: exerciseId,
      before: before,
    );
    if (value != null) {
      await _prStore.write(gymId, userId, {key: value});
    }
    return value;
  }

  Future<double?> _loadPreviousBestE1rm({
    required String gymId,
    required String userId,
    required String deviceId,
    String? exerciseId,
    required DateTime before,
  }) async {
    final collection = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('logs');
    var query = collection
        .where('userId', isEqualTo: userId)
        .where('timestamp', isLessThan: Timestamp.fromDate(before))
        .orderBy('timestamp', descending: true)
        .limit(25);
    if (exerciseId != null && exerciseId.isNotEmpty) {
      query = query.where('exerciseId', isEqualTo: exerciseId);
    }
    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await query.get();
    } on FirebaseException {
      return null;
    }
    if (snap.docs.isEmpty) return null;
    var best = 0.0;
    for (final doc in snap.docs) {
      final data = doc.data();
      final weight = (data['weight'] as num?)?.toDouble() ?? 0;
      final reps = (data['reps'] as num?)?.toInt() ?? 0;
      if (weight <= 0 || reps <= 0) continue;
      final e1rm = _calculateE1rm(weight, reps);
      best = max(best, e1rm);
    }
    return best > 0 ? best : null;
  }

  double? _bestE1rmForSession(Session session) {
    var best = 0.0;
    for (final set in session.sets) {
      final weight = set.weight;
      final reps = set.reps;
      if (weight <= 0 || reps <= 0) continue;
      final e1rm = _calculateE1rm(weight, reps);
      if (e1rm > best) {
        best = e1rm;
      }
    }
    return best > 0 ? best : null;
  }

  double _calculateE1rm(double weight, int reps) {
    return weight * (1 + reps / 30);
  }

  Future<StorySessionSummary?> _loadRemoteSummary(
    String gymId,
    String userId,
    String dayKey,
  ) async {
    final ref = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(userId)
        .collection('session_stories')
        .doc(dayKey);
    try {
      final snap = await ref.get();
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return StorySessionSummary(
        gymId: gymId,
        userId: userId,
        dayKey: dayKey,
        totalXp: (data['totalXp'] as num?)?.toInt() ?? 0,
        generatedAt:
            (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        achievements: (data['achievements'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(StoryAchievement.fromJson)
            .toList(),
      );
    } on FirebaseException {
      return null;
    }
  }

  Future<void> _persistRemoteSummary(StorySessionSummary summary) async {
    final ref = _firestore
        .collection('gyms')
        .doc(summary.gymId)
        .collection('users')
        .doc(summary.userId)
        .collection('session_stories')
        .doc(summary.dayKey);
    try {
      await ref.set({
        'totalXp': summary.totalXp,
        'generatedAt': Timestamp.fromDate(summary.generatedAt),
        'achievements': summary.achievements.map((a) => a.toJson()).toList(),
      }, SetOptions(merge: true));
    } on FirebaseException {
      // Ignore persistence errors; summary remains available locally.
    }
  }
}

class _PrCandidate {
  final Session session;
  final double e1rm;

  const _PrCandidate({required this.session, required this.e1rm});
}
