import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/core/storage/daily_stats_cache_store.dart';
import 'package:tapem/core/time/logic_day.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';
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
        stats: const StorySessionStats.empty(),
      );
    }

    final dayXp = await _resolveDayXp(
      gymId: gymId,
      userId: userId,
      date: date,
    );

    final cached = await _summaryStore.read(gymId, userId, dayKey);
    if (cached != null && !_needsStatsRebuild(cached, sessions)) {
      return _finalizeSummary(
        summary: cached,
        gymId: gymId,
        userId: userId,
        dayKey: dayKey,
        date: date,
        sessions: sessions,
        dayXp: dayXp,
        isCachedLocal: true,
      );
    }

    final remote = await _loadRemoteSummary(gymId, userId, dayKey);
    if (remote != null && !_needsStatsRebuild(remote, sessions)) {
      return _finalizeSummary(
        summary: remote,
        gymId: gymId,
        userId: userId,
        dayKey: dayKey,
        date: date,
        sessions: sessions,
        dayXp: dayXp,
        isCachedLocal: false,
      );
    }

    final summary = await _buildSummary(
      gymId: gymId,
      userId: userId,
      date: date,
      dayKey: dayKey,
      sessions: sessions,
      dayXp: dayXp,
    );
    if (summary != null) {
      return _finalizeSummary(
        summary: summary,
        gymId: gymId,
        userId: userId,
        dayKey: dayKey,
        date: date,
        sessions: sessions,
        dayXp: dayXp,
        isCachedLocal: false,
      );
    }
    return summary;
  }

  Future<StorySessionSummary> _finalizeSummary({
    required StorySessionSummary summary,
    required String gymId,
    required String userId,
    required String dayKey,
    required DateTime date,
    required List<Session> sessions,
    required int dayXp,
    required bool isCachedLocal,
  }) async {
    final normalized = _normalizeSummary(summary: summary, dayXp: dayXp);
    if (!isCachedLocal || normalized != summary) {
      await _summaryStore.write(normalized);
    }
    if (normalized != summary) {
      await _persistRemoteSummary(normalized);
    }

    final ensured = await _ensureHighlights(
      summary: normalized,
      gymId: gymId,
      userId: userId,
      dayKey: dayKey,
      date: date,
      sessions: sessions,
      dayXp: dayXp,
    );
    if (ensured != normalized) {
      await _summaryStore.write(ensured);
      await _persistRemoteSummary(ensured);
      return ensured;
    }
    return normalized;
  }

  Future<StorySessionSummary> _ensureHighlights({
    required StorySessionSummary summary,
    required String gymId,
    required String userId,
    required String dayKey,
    required DateTime date,
    required List<Session> sessions,
    required int dayXp,
  }) async {
    if (sessions.isEmpty || _hasNonDailyAchievements(summary)) {
      return summary;
    }

    final shouldRebuild = await _shouldRebuildHighlights(
      gymId: gymId,
      userId: userId,
      date: date,
      sessions: sessions,
    );
    if (!shouldRebuild) {
      return summary;
    }

    final rebuilt = await _buildSummary(
      gymId: gymId,
      userId: userId,
      date: date,
      dayKey: dayKey,
      sessions: sessions,
      dayXp: dayXp,
    );
    if (rebuilt == null) {
      return summary;
    }
    return _normalizeSummary(summary: rebuilt, dayXp: dayXp);
  }

  Future<bool> _shouldRebuildHighlights({
    required String gymId,
    required String userId,
    required DateTime date,
    required List<Session> sessions,
  }) async {
    if (sessions.isEmpty) {
      return false;
    }
    final startOfDay = DateTime(date.year, date.month, date.day);
    for (final session in sessions) {
      if (!session.isMulti) {
        final seenDevice =
            await _historyStore.hasSeenDevice(gymId, userId, session.deviceId);
        final existedBefore = await _hasPriorUsage(
          gymId: gymId,
          userId: userId,
          deviceId: session.deviceId,
          exerciseId: null,
          before: startOfDay,
        );
        final shouldTrigger =
            existedBefore == false || (existedBefore == null && !seenDevice);
        if (shouldTrigger) {
          return true;
        }
      }

      final exerciseId = session.exerciseId;
      if (session.isMulti && exerciseId != null && exerciseId.isNotEmpty) {
        final seenExercise = await _historyStore.hasSeenExercise(
          gymId,
          userId,
          session.deviceId,
          exerciseId,
        );
        final existedBefore = await _hasPriorUsage(
          gymId: gymId,
          userId: userId,
          deviceId: session.deviceId,
          exerciseId: exerciseId,
          before: startOfDay,
        );
        final shouldTrigger =
            existedBefore == false || (existedBefore == null && !seenExercise);
        if (shouldTrigger) {
          return true;
        }
      }

      final topSet = _bestPrSetForSession(session);
      if (topSet != null) {
        final bestE1rm = topSet.e1rm;
        final recordKey = '${session.deviceId}::${exerciseId ?? ''}';
        var previousBest = await _prStore.read(gymId, userId, recordKey);
        if (previousBest == null || previousBest <= 0) {
          previousBest = await _loadPreviousBestE1rm(
            gymId: gymId,
            userId: userId,
            deviceId: session.deviceId,
            exerciseId: exerciseId,
            before: startOfDay,
          );
        }
        final baseline = previousBest ?? 0;
        if (bestE1rm > baseline + 0.01) {
          return true;
        }
      }
    }
    return false;
  }

  bool _hasNonDailyAchievements(StorySessionSummary summary) {
    return summary.achievements
        .any((achievement) => achievement.type != StoryAchievementType.dailyXp);
  }

  Future<StorySessionSummary?> _buildSummary({
    required String gymId,
    required String userId,
    required DateTime date,
    required String dayKey,
    required List<Session> sessions,
    required int dayXp,
  }) async {
    if (sessions.isEmpty) return null;
    final generatedAt = _now();

    final startOfDay = DateTime(date.year, date.month, date.day);
    final newDevices = <String, Session>{};
    final newExercises = <String, Session>{};

    for (final session in sessions) {
      final deviceId = session.deviceId;
      final exerciseId = session.exerciseId;
      final hasExercise = exerciseId != null && exerciseId.isNotEmpty;
      final isMulti = session.isMulti;

      if (!isMulti && !newDevices.containsKey(deviceId)) {
        final seenDevice =
            await _historyStore.hasSeenDevice(gymId, userId, deviceId);
        final existedBefore = await _hasPriorUsage(
          gymId: gymId,
          userId: userId,
          deviceId: deviceId,
          exerciseId: null,
          before: startOfDay,
        );
        final shouldAdd = existedBefore == false || (existedBefore == null && !seenDevice);
        if (shouldAdd) {
          newDevices[deviceId] = session;
        }
      }

      if (isMulti && hasExercise) {
        final key = '$deviceId::$exerciseId';
        if (!newExercises.containsKey(key)) {
          final seenExercise = await _historyStore.hasSeenExercise(
            gymId,
            userId,
            deviceId,
            exerciseId!,
          );
          final existedBefore = await _hasPriorUsage(
            gymId: gymId,
            userId: userId,
            deviceId: deviceId,
            exerciseId: exerciseId,
            before: startOfDay,
          );
          final shouldAdd =
              existedBefore == false || (existedBefore == null && !seenExercise);
          if (shouldAdd) {
            newExercises[key] = session;
          }
        }
      }
    }

    final newPrs = <String, _PrCandidate>{};
    for (final session in sessions) {
      final topSet = _bestPrSetForSession(session);
      if (topSet == null) continue;
      final bestE1rm = topSet.e1rm;
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
        if (existing == null || bestE1rm > existing.topSet.e1rm) {
          newPrs[recordKey] = _PrCandidate(session: session, topSet: topSet);
        }
      }
    }

    final nameRequests = <_ExerciseKey>{};
    for (final session in newExercises.values) {
      final exerciseId = session.exerciseId;
      if (exerciseId != null && exerciseId.isNotEmpty) {
        final exerciseName = session.exerciseName;
        if (exerciseName == null || exerciseName.trim().isEmpty) {
          nameRequests.add(
            _ExerciseKey(deviceId: session.deviceId, exerciseId: exerciseId),
          );
        }
      }
    }
    for (final candidate in newPrs.values) {
      final exerciseId = candidate.session.exerciseId;
      if (exerciseId != null && exerciseId.isNotEmpty) {
        final exerciseName = candidate.session.exerciseName;
        if (exerciseName == null || exerciseName.trim().isEmpty) {
          nameRequests.add(
            _ExerciseKey(deviceId: candidate.session.deviceId, exerciseId: exerciseId),
          );
        }
      }
    }

    final resolvedExerciseNames = nameRequests.isNotEmpty
        ? await _loadExerciseNames(gymId: gymId, exerciseKeys: nameRequests)
        : const <_ExerciseKey, String>{};

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
      final exerciseId = session.exerciseId;
      final resolvedName = (exerciseId != null && exerciseId.isNotEmpty)
          ? resolvedExerciseNames[_ExerciseKey(deviceId: session.deviceId, exerciseId: exerciseId)]
          : null;
      final displayName = (session.exerciseName?.trim().isNotEmpty ?? false)
          ? session.exerciseName!.trim()
          : (resolvedName ?? session.deviceName);
      final deviceName = session.deviceName.trim();
      final isDuplicateDevice = newDevices.containsKey(session.deviceId) &&
          displayName.trim().toLowerCase() == deviceName.toLowerCase();
      if (isDuplicateDevice) {
        continue;
      }
      achievementsBuffer.add(
        StoryAchievement(
          type: StoryAchievementType.newExercise,
          deviceName: session.deviceName,
          exerciseName: displayName,
        ),
      );
    }

    for (final candidate in newPrs.values) {
      final exerciseId = candidate.session.exerciseId;
      final resolvedName = (exerciseId != null && exerciseId.isNotEmpty)
          ? resolvedExerciseNames[
              _ExerciseKey(deviceId: candidate.session.deviceId, exerciseId: exerciseId)
            ]
          : null;
      final exerciseName = (candidate.session.exerciseName?.trim().isNotEmpty ?? false)
          ? candidate.session.exerciseName!.trim()
          : resolvedName;
      achievementsBuffer.add(
        StoryAchievement(
          type: StoryAchievementType.personalRecord,
          deviceName: candidate.session.deviceName,
          exerciseName: exerciseName ?? candidate.session.deviceName,
          e1rm: candidate.topSet.e1rm,
          topSetWeight: candidate.topSet.weight,
          topSetReps: candidate.topSet.reps,
        ),
      );
    }

    final stats = _deriveStatsFromSessions(sessions);

    final summary = StorySessionSummary(
      gymId: gymId,
      userId: userId,
      dayKey: dayKey,
      totalXp: dayXp,
      generatedAt: generatedAt,
      achievements: achievementsBuffer,
      stats: stats,
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
          entry.key: double.parse(entry.value.topSet.e1rm.toStringAsFixed(3)),
      },
    );

    return summary;
  }

  int? _sessionDurationMs(Session session) {
    final durationMs = session.durationMs;
    if (durationMs != null && durationMs > 0) {
      return durationMs;
    }
    final start = session.startTime;
    final end = session.endTime;
    if (start != null && end != null) {
      final diff = end.difference(start).inMilliseconds;
      if (diff > 0) {
        return diff;
      }
    }
    return null;
  }

  StorySessionStats _deriveStatsFromSessions(List<Session> sessions) {
    if (sessions.isEmpty) {
      return const StorySessionStats.empty();
    }

    final uniqueActivities = <String>{};
    var totalSets = 0;
    var totalDurationMs = 0;
    DateTime? earliestStart;
    DateTime? latestEnd;

    for (final session in sessions) {
      totalSets += session.sets.length;
      final sessionDuration = _sessionDurationMs(session);
      if (sessionDuration != null) {
        totalDurationMs += sessionDuration;
      }

      final startTime = session.startTime;
      if (startTime != null &&
          (earliestStart == null || startTime.isBefore(earliestStart!))) {
        earliestStart = startTime;
      }
      final endTime = session.endTime;
      if (endTime != null &&
          (latestEnd == null || endTime.isAfter(latestEnd!))) {
        latestEnd = endTime;
      }

      final deviceId = session.deviceId;
      final exerciseId = session.exerciseId;
      final hasExercise = exerciseId != null && exerciseId.isNotEmpty;
      final activityKey = hasExercise ? '$deviceId::$exerciseId' : deviceId;
      uniqueActivities.add(activityKey);
    }

    if (totalDurationMs == 0 && earliestStart != null && latestEnd != null) {
      final diff = latestEnd!.difference(earliestStart!).inMilliseconds;
      if (diff > 0) {
        totalDurationMs = diff;
      }
    }

    return StorySessionStats(
      exerciseCount: uniqueActivities.length,
      setCount: totalSets,
      durationMs: totalDurationMs,
    );
  }

  DateTime? _latestActivityTimestamp(List<Session> sessions) {
    DateTime? latest;
    for (final session in sessions) {
      final candidate =
          session.endTime ?? session.startTime ?? session.timestamp;
      if (latest == null || candidate.isAfter(latest)) {
        latest = candidate;
      }
    }
    return latest;
  }

  bool _needsStatsRebuild(StorySessionSummary summary, List<Session> sessions) {
    if (sessions.isEmpty) return false;
    final derivedStats = _deriveStatsFromSessions(sessions);
    final stats = summary.stats;
    if (stats.exerciseCount != derivedStats.exerciseCount ||
        stats.setCount != derivedStats.setCount ||
        stats.durationMs != derivedStats.durationMs) {
      return true;
    }
    final latestActivity = _latestActivityTimestamp(sessions);
    if (latestActivity != null && summary.generatedAt.isBefore(latestActivity)) {
      return true;
    }
    return false;
  }

  Future<bool?> _hasPriorUsage({
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
      return null;
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

  _PrSet? _bestPrSetForSession(Session session) {
    _PrSet? best;
    for (final set in session.sets) {
      final weight = set.weight;
      final reps = set.reps;
      if (weight <= 0 || reps <= 0) continue;
      final e1rm = _calculateE1rm(weight, reps);
      if (best == null || e1rm > best.e1rm) {
        best = _PrSet(weight: weight, reps: reps, e1rm: e1rm);
      }
    }
    return best;
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
      final xpPerSession = LevelService.xpPerSession;
      final remoteXp = (data['totalXp'] as num?)?.toInt() ?? 0;
      final sanitizedXp = remoteXp.clamp(0, xpPerSession);
      return StorySessionSummary(
        gymId: gymId,
        userId: userId,
        dayKey: dayKey,
        totalXp: sanitizedXp,
        generatedAt:
            (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        achievements: (data['achievements'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(StoryAchievement.fromJson)
            .toList(),
        stats: data['stats'] is Map<String, dynamic>
            ? StorySessionStats.fromJson(data['stats'] as Map<String, dynamic>)
            : const StorySessionStats.empty(),
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
        'stats': summary.stats.toJson(),
      }, SetOptions(merge: true));
    } on FirebaseException {
      // Ignore persistence errors; summary remains available locally.
    }
  }

  Future<Map<_ExerciseKey, String>> _loadExerciseNames({
    required String gymId,
    required Iterable<_ExerciseKey> exerciseKeys,
  }) async {
    final result = <_ExerciseKey, String>{};
    final uniqueKeys = exerciseKeys.toSet();
    for (final key in uniqueKeys) {
      if (key.exerciseId.isEmpty) continue;
      try {
        final snap = await _firestore
            .collection('gyms')
            .doc(gymId)
            .collection('devices')
            .doc(key.deviceId)
            .collection('exercises')
            .doc(key.exerciseId)
            .get();
        if (!snap.exists) continue;
        final name = (snap.data()?['name'] as String?)?.trim();
        if (name != null && name.isNotEmpty) {
          result[key] = name;
        }
      } on FirebaseException {
        // Ignore lookup issues; we'll fall back to IDs or device names.
      }
    }
    return result;
  }

  Future<int> _resolveDayXp({
    required String gymId,
    required String userId,
    required DateTime date,
  }) async {
    final xpPerSession = LevelService.xpPerSession;
    try {
      final xpEntry = await _dailyStatsCache.read(gymId, userId);
      if (xpEntry == null || !xpEntry.isSameCalendarDay(date)) {
        return xpPerSession;
      }
      final clamped = xpEntry.xp.clamp(0, xpPerSession);
      if (clamped > 0) {
        return clamped;
      }
      if (xpEntry.totalXp > 0) {
        return min(xpEntry.totalXp, xpPerSession);
      }
    } catch (_) {
      // Ignore cache read issues and fall back to default XP.
    }
    return xpPerSession;
  }

  StorySessionSummary _normalizeSummary({
    required StorySessionSummary summary,
    required int dayXp,
  }) {
    final achievements = summary.achievements;
    List<StoryAchievement>? updatedAchievements;
    final idx = achievements.indexWhere((a) => a.type == StoryAchievementType.dailyXp);
    if (idx >= 0) {
      final daily = achievements[idx];
      final currentXp = daily.xp ?? 0;
      if (currentXp != dayXp) {
        updatedAchievements = List.of(achievements);
        updatedAchievements[idx] = daily.copyWith(xp: dayXp);
      }
    } else {
      updatedAchievements = [
        StoryAchievement(type: StoryAchievementType.dailyXp, xp: dayXp),
        ...achievements,
      ];
    }

    if (summary.totalXp == dayXp && updatedAchievements == null) {
      return summary;
    }

    return summary.copyWith(
      totalXp: dayXp,
      achievements: updatedAchievements ?? achievements,
    );
  }
}

class _PrCandidate {
  final Session session;
  final _PrSet topSet;

  const _PrCandidate({required this.session, required this.topSet});
}

class _PrSet {
  final double weight;
  final int reps;
  final double e1rm;

  const _PrSet({required this.weight, required this.reps, required this.e1rm});
}

class _ExerciseKey {
  final String deviceId;
  final String exerciseId;

  const _ExerciseKey({required this.deviceId, required this.exerciseId});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _ExerciseKey && other.deviceId == deviceId && other.exerciseId == exerciseId;
  }

  @override
  int get hashCode => Object.hash(deviceId, exerciseId);
}
