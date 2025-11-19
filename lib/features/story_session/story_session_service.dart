import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/storage/daily_stats_cache_store.dart';
import 'package:tapem/core/time/logic_day.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';

import 'data/story_session_history_store.dart';
import 'data/story_session_pr_store.dart';
import 'data/story_session_summary_store.dart';
import 'domain/models/story_achievement.dart';
import 'domain/models/story_daily_xp.dart';
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
        dailyXp: const StoryDailyXp.empty(),
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
    required StoryDailyXp dayXp,
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
    required StoryDailyXp dayXp,
  }) async {
    final hasPrAchievement = summary.achievements
        .any((achievement) => achievement.type == StoryAchievementType.personalRecord);
    final hasFirstTimeAchievement = summary.achievements.any(
      (achievement) =>
          achievement.type == StoryAchievementType.newDevice ||
          achievement.type == StoryAchievementType.newExercise,
    );

    if (sessions.isEmpty ||
        (_hasNonDailyAchievements(summary) &&
            !(hasPrAchievement && hasFirstTimeAchievement))) {
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
    final dayKey = logicDayKey(date);
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

      final bestE1rm = _bestE1rmForSession(session);
      if (bestE1rm != null) {
        final previousBest = await _ensurePreviousPr(
          gymId: gymId,
          userId: userId,
          deviceId: session.deviceId,
          exerciseId: exerciseId,
          before: startOfDay,
          dayKey: dayKey,
        );
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
    required StoryDailyXp dayXp,
  }) async {
    if (sessions.isEmpty) return null;
    final generatedAt = _now();

    final startOfDay = DateTime(date.year, date.month, date.day);
    final newDevices = <String, Session>{};
    final newExercises = <String, Session>{};

    for (final session in sessions) {
      final deviceId = session.deviceId;
      final exerciseId = session.exerciseId;
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

      if (isMulti && exerciseId != null && exerciseId.isNotEmpty) {
        final resolvedExerciseId = exerciseId;
        final key = '$deviceId::$resolvedExerciseId';
        if (!newExercises.containsKey(key)) {
          final seenExercise = await _historyStore.hasSeenExercise(
            gymId,
            userId,
            deviceId,
            resolvedExerciseId,
          );
          final existedBefore = await _hasPriorUsage(
            gymId: gymId,
            userId: userId,
            deviceId: deviceId,
            exerciseId: resolvedExerciseId,
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
    final prUpdates = <String, StorySessionPrCacheEntry>{};
    for (final session in sessions) {
      final bestPr = _bestPrForSession(session);
      if (bestPr == null) continue;
      final bestE1rm = bestPr.e1rm;
      final exerciseId = session.exerciseId ?? '';
      final recordKey = '${session.deviceId}::$exerciseId';
      final previousBest = await _ensurePreviousPr(
        gymId: gymId,
        userId: userId,
        deviceId: session.deviceId,
        exerciseId: session.exerciseId,
        before: startOfDay,
        dayKey: dayKey,
      );
      final pendingUpdate = prUpdates[recordKey];
      final hasBaseline = previousBest != null || pendingUpdate != null;

      if (!hasBaseline) {
        prUpdates[recordKey] = StorySessionPrCacheEntry(
          value: double.parse(bestE1rm.toStringAsFixed(3)),
          dayKey: dayKey,
        );
        continue;
      }

      final baseline = max(previousBest ?? 0, pendingUpdate?.value ?? 0);
      if (bestE1rm > baseline + 0.01) {
        final existing = newPrs[recordKey];
        if (existing == null || bestE1rm > existing.e1rm) {
          newPrs[recordKey] = _PrCandidate(
            session: session,
            e1rm: bestE1rm,
            weight: bestPr.weight,
            reps: bestPr.reps,
          );
        }
        prUpdates[recordKey] = StorySessionPrCacheEntry(
          value: double.parse(bestE1rm.toStringAsFixed(3)),
          dayKey: dayKey,
        );
      } else if (bestE1rm > baseline &&
          (pendingUpdate == null || bestE1rm > pendingUpdate.value)) {
        prUpdates[recordKey] = StorySessionPrCacheEntry(
          value: double.parse(bestE1rm.toStringAsFixed(3)),
          dayKey: dayKey,
        );
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
      StoryAchievement(
        type: StoryAchievementType.dailyXp,
        xp: dayXp.xp,
        xpComponents: dayXp.components,
        xpPenalties: dayXp.penalties,
      ),
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
          e1rm: candidate.e1rm,
          prWeight: candidate.weight,
          prReps: candidate.reps,
        ),
      );
    }

    final stats = _deriveStatsFromSessions(sessions);

    final summary = StorySessionSummary(
      gymId: gymId,
      userId: userId,
      dayKey: dayKey,
      totalXp: dayXp.xp,
      generatedAt: generatedAt,
      achievements: achievementsBuffer,
      stats: stats,
      dailyXp: dayXp,
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
    await _prStore.write(gymId, userId, prUpdates);

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
      if (startTime != null) {
        final currentEarliest = earliestStart;
        if (currentEarliest == null || startTime.isBefore(currentEarliest)) {
          earliestStart = startTime;
        }
      }
      final endTime = session.endTime;
      if (endTime != null) {
        final currentLatest = latestEnd;
        if (currentLatest == null || endTime.isAfter(currentLatest)) {
          latestEnd = endTime;
        }
      }

      final deviceId = session.deviceId;
      final exerciseId = session.exerciseId;
      final hasExercise = exerciseId != null && exerciseId.isNotEmpty;
      final activityKey = hasExercise ? '$deviceId::$exerciseId' : deviceId;
      uniqueActivities.add(activityKey);
    }

    final start = earliestStart;
    final end = latestEnd;
    if (totalDurationMs == 0 && start != null && end != null) {
      final diff = end.difference(start).inMilliseconds;
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
    required String dayKey,
  }) async {
    final key = '$deviceId::${exerciseId ?? ''}';
    final cached = await _prStore.readEntry(gymId, userId, key);
    if (cached != null) {
      final cachedDayKey = cached.dayKey;
      final isBeforeRequestedDay =
          cachedDayKey == null || cachedDayKey.compareTo(dayKey) < 0;
      if (isBeforeRequestedDay && cached.value > 0) {
        return cached.value;
      }
    }
    final value = await _loadPreviousBestE1rm(
      gymId: gymId,
      userId: userId,
      deviceId: deviceId,
      exerciseId: exerciseId,
      before: before,
    );
    if (value != null) {
      await _prStore.write(
        gymId,
        userId,
        {
          key: StorySessionPrCacheEntry(value: value),
        },
      );
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
    final bestPr = _bestPrForSession(session);
    return bestPr?.e1rm;
  }

  _PrPerformance? _bestPrForSession(Session session) {
    _PrPerformance? best;
    for (final set in session.sets) {
      final weight = set.weight;
      final reps = set.reps;
      if (weight <= 0 || reps <= 0) continue;
      final e1rm = _calculateE1rm(weight, reps);
      if (best == null || e1rm > best.e1rm) {
        best = _PrPerformance(e1rm: e1rm, weight: weight, reps: reps);
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
      final remoteXp = (data['totalXp'] as num?)?.toInt() ?? 0;
      final achievements = (data['achievements'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(StoryAchievement.fromJson)
          .toList();
      final rawDailyXp = data['dailyXp'];
      StoryDailyXp dailyXp;
      if (rawDailyXp is Map) {
        dailyXp = StoryDailyXp.fromJson(
          rawDailyXp.map((key, value) => MapEntry('$key', value)),
        );
      } else {
        final dailyAchievement = achievements.firstWhere(
          (achievement) => achievement.type == StoryAchievementType.dailyXp,
          orElse: () =>
              const StoryAchievement(type: StoryAchievementType.dailyXp),
        );
        dailyXp = StoryDailyXp(
          xp: remoteXp,
          components: dailyAchievement.xpComponents,
          penalties: dailyAchievement.xpPenalties,
        );
      }
      return StorySessionSummary(
        gymId: gymId,
        userId: userId,
        dayKey: dayKey,
        totalXp: remoteXp,
        generatedAt:
            (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        achievements: achievements,
        stats: data['stats'] is Map<String, dynamic>
            ? StorySessionStats.fromJson(data['stats'] as Map<String, dynamic>)
            : const StorySessionStats.empty(),
        dailyXp: dailyXp,
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
        'dailyXp': summary.dailyXp.toJson(),
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

  Future<StoryDailyXp> _resolveDayXp({
    required String gymId,
    required String userId,
    required DateTime date,
  }) async {
    final xpPerSession = LevelService.xpPerSession;
    final dayKey = logicDayKey(date);
    StoryDailyXp? cacheDaily;
    try {
      final xpEntry = await _dailyStatsCache.read(gymId, userId);
      if (xpEntry != null && xpEntry.isSameCalendarDay(date)) {
        cacheDaily = StoryDailyXp(
          xp: xpEntry.xp,
          totalXp: xpEntry.totalXp,
          computedTotalXp: xpEntry.computedTotalXp,
          components: _mapComponents(xpEntry.components),
          penalties: _mapPenalties(xpEntry.penalties),
        );
      }
    } catch (_) {
      // Ignore cache read issues and fall back to Firestore.
    }

    try {
      final dayRef = _firestore.collection('users').doc(userId).collection('trainingDayXP');
      final snap = await dayRef.doc(dayKey).get();
      final data = snap.data();
      if (snap.exists && data != null) {
        final remote = _dailyXpFromDoc(data, fallbackPenalties: cacheDaily?.penalties);
        return cacheDaily != null ? _mergeDailyXpDetails(remote, cacheDaily) : remote;
      }
    } on FirebaseException {
      // Ignore remote read issues and fall back to cache/defaults.
    }

    if (cacheDaily != null) {
      return cacheDaily;
    }

    return StoryDailyXp(xp: xpPerSession);
  }

  StorySessionSummary _normalizeSummary({
    required StorySessionSummary summary,
    required StoryDailyXp dayXp,
  }) {
    final merged = _mergeDailyXpDetails(dayXp, summary.dailyXp);
    final achievements = summary.achievements;
    List<StoryAchievement>? updatedAchievements;
    final idx = achievements.indexWhere((a) => a.type == StoryAchievementType.dailyXp);
    if (idx >= 0) {
      final daily = achievements[idx];
      final needsUpdate =
          (daily.xp ?? 0) != merged.xp ||
          !_listsEqual(daily.xpComponents, merged.components) ||
          !_listsEqual(daily.xpPenalties, merged.penalties);
      if (needsUpdate) {
        updatedAchievements = List.of(achievements);
        updatedAchievements[idx] = daily.copyWith(
          xp: merged.xp,
          xpComponents: merged.components,
          xpPenalties: merged.penalties,
        );
      }
    } else if (merged.xp != 0 || merged.hasBreakdown) {
      updatedAchievements = [
        StoryAchievement(
          type: StoryAchievementType.dailyXp,
          xp: merged.xp,
          xpComponents: merged.components,
          xpPenalties: merged.penalties,
        ),
        ...achievements,
      ];
    }

    if (summary.totalXp == merged.xp && summary.dailyXp == merged &&
        updatedAchievements == null) {
      return summary;
    }

    return summary.copyWith(
      totalXp: merged.xp,
      achievements: updatedAchievements ?? achievements,
      dailyXp: merged,
    );
  }
}

final storySessionServiceProvider = Provider<StorySessionService>((ref) {
  return StorySessionService(
    firestore: FirebaseFirestore.instance,
  );
});

StoryDailyXp _dailyXpFromDoc(
  Map<String, dynamic> data, {
  List<StoryXpPenalty>? fallbackPenalties,
}) {
  final xp = (data['xp'] as num?)?.toInt() ?? 0;
  final totalXp = (data['totalXp'] as num?)?.toInt();
  final computedTotal = (data['computedTotalXp'] as num?)?.toInt();
  final runningTotal = (data['runningTotalXp'] as num?)?.toInt();
  final metadata = _coerceMetadata(data['metadata']);
  final components = _mapComponents(data['components']);
  return StoryDailyXp(
    xp: xp,
    totalXp: totalXp,
    computedTotalXp: computedTotal,
    runningTotalXp: runningTotal,
    metadata: metadata,
    components: components,
    penalties: fallbackPenalties ?? const [],
  );
}

Map<String, dynamic> _coerceMetadata(dynamic raw) {
  if (raw is Map) {
    return raw.map((key, value) => MapEntry('$key', value));
  }
  return const {};
}

List<StoryXpComponent> _mapComponents(dynamic raw) {
  if (raw is List) {
    return List.unmodifiable(raw.whereType<Map>().map((entry) {
      return StoryXpComponent.fromJson(
        entry.map((key, value) => MapEntry('$key', value)),
      );
    }));
  }
  if (raw is List<Map<String, dynamic>>) {
    return List.unmodifiable(raw.map(StoryXpComponent.fromJson));
  }
  return const [];
}

List<StoryXpPenalty> _mapPenalties(dynamic raw) {
  if (raw is List) {
    return List.unmodifiable(raw.whereType<Map>().map((entry) {
      return StoryXpPenalty.fromJson(
        entry.map((key, value) => MapEntry('$key', value)),
      );
    }));
  }
  if (raw is List<Map<String, dynamic>>) {
    return List.unmodifiable(raw.map(StoryXpPenalty.fromJson));
  }
  return const [];
}

StoryDailyXp _mergeDailyXpDetails(StoryDailyXp incoming, StoryDailyXp existing) {
  final xp = incoming.xp != 0 || existing.xp == 0 ? incoming.xp : existing.xp;
  final totalXp = incoming.totalXp ?? existing.totalXp;
  final computedTotalXp = incoming.computedTotalXp ?? existing.computedTotalXp;
  final runningTotalXp = incoming.runningTotalXp ?? existing.runningTotalXp;
  final metadata = incoming.metadata.isNotEmpty ? incoming.metadata : existing.metadata;
  final components = incoming.components.isNotEmpty
      ? incoming.components
      : existing.components;
  final penalties = incoming.penalties.isNotEmpty
      ? incoming.penalties
      : existing.penalties;
  return StoryDailyXp(
    xp: xp,
    totalXp: totalXp,
    computedTotalXp: computedTotalXp,
    runningTotalXp: runningTotalXp,
    metadata: metadata,
    components: components,
    penalties: penalties,
  );
}

bool _listsEqual<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class _PrCandidate {
  final Session session;
  final double e1rm;
  final double weight;
  final int reps;

  const _PrCandidate({
    required this.session,
    required this.e1rm,
    required this.weight,
    required this.reps,
  });
}

class _PrPerformance {
  final double e1rm;
  final double weight;
  final int reps;

  const _PrPerformance({
    required this.e1rm,
    required this.weight,
    required this.reps,
  });
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
