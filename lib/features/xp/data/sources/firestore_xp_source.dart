import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/logging/xp_trace.dart';
import 'package:tapem/core/time/logic_day.dart';
import 'package:tapem/features/rank/data/sources/firestore_rank_source.dart';
import 'package:tapem/features/rank/domain/models/level_info.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';
import 'package:tapem/features/xp/domain/device_xp_result.dart';
import 'package:tapem/features/xp/domain/day_xp_breakdown.dart';
import 'package:tapem/features/xp/domain/muscle_xp_calculator.dart';
import 'package:tapem/features/xp/domain/session_xp_award.dart';
import 'package:tapem/features/xp/domain/training_day_xp_engine.dart';

class _SeasonWindow {
  const _SeasonWindow({
    required this.id,
    required this.start,
    required this.end,
  });

  final String id;
  final DateTime start;
  final DateTime end;

  bool contains(DateTime date) {
    return !date.isBefore(start) && !date.isAfter(end);
  }
}

final List<_SeasonWindow> _seasonWindows = [
  _SeasonWindow(
    id: '2025',
    start: DateTime.utc(2025, 1, 1),
    end: DateTime.utc(2025, 12, 31, 23, 59, 59, 999),
  ),
  _SeasonWindow(
    id: '2026',
    start: DateTime.utc(2026, 1, 1),
    end: DateTime.utc(2026, 12, 31, 23, 59, 59, 999),
  ),
];

const String _xpRulesetId = 'xp_ruleset_v2';
const int _xpRulesetVersion = 1;

const bool _logDeviceXpWatchers = false;

class FirestoreXpSource {
  final FirebaseFirestore _firestore;
  final FirestoreRankSource _rankSource;

  FirestoreXpSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _rankSource = FirestoreRankSource(firestore: firestore);

  Future<SessionXpAward> addSessionXp({
    required String gymId,
    required String userId,
    required String deviceId,
    required String sessionId,
    required bool showInLeaderboard,
    required bool isMulti,
    String? exerciseId,
    required String traceId,
    required DateTime sessionDate,
    required String timeZone,
    List<String> primaryMuscleGroupIds = const [],
    List<String> secondaryMuscleGroupIds = const [],
  }) async {
    assert(LevelService.xpPerSession == 50);
    final sessionDay = DateTime(
      sessionDate.year,
      sessionDate.month,
      sessionDate.day,
    );
    final dayKey = logicDayKey(sessionDay);
    final userRef = _firestore.collection('users').doc(userId);
    final dayCollection = userRef.collection('trainingDayXP');
    final penaltyCollection = userRef.collection('xpPenalties');
    final statsRef = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(userId)
        .collection('rank')
        .doc('stats');

    XpTrace.log('FS_IN', {
      'gymId': gymId,
      'uid': userId,
      'deviceId': deviceId,
      'sessionId': sessionId,
      'isMulti': isMulti,
      'exerciseId': exerciseId ?? '',
      'dayKey': dayKey,
      'showInLeaderboard': showInLeaderboard,
      'traceId': traceId,
      'timeZone': timeZone,
    });

    final existingDaysSnap = await dayCollection.get();
    QueryDocumentSnapshot<Map<String, dynamic>>? existingDayDoc;
    for (final doc in existingDaysSnap.docs) {
      if (doc.id == dayKey) {
        existingDayDoc = doc;
        break;
      }
    }

    final dailyOutcome = await _processDailyXp(
      existingDaysSnap: existingDaysSnap,
      existingDayDoc: existingDayDoc,
      trainingDayCollection: dayCollection,
      penaltyCollection: penaltyCollection,
      statsRef: statsRef,
      sessionDay: sessionDay,
      dayKey: dayKey,
      timeZone: timeZone,
      traceId: traceId,
    );

    final leaderboardResult = await _rankSource.addXp(
      gymId: gymId,
      userId: userId,
      deviceId: deviceId,
      sessionId: sessionId,
      showInLeaderboard: showInLeaderboard,
      isMulti: isMulti,
      exerciseId: exerciseId,
      traceId: traceId,
    );

    if (leaderboardResult == DeviceXpResult.okAdded ||
        leaderboardResult == DeviceXpResult.okAddedNoLeaderboard) {
      await _applyMuscleXp(
        statsRef: statsRef,
        primaryMuscleGroupIds: primaryMuscleGroupIds,
        secondaryMuscleGroupIds: secondaryMuscleGroupIds,
        traceId: traceId,
      );
    }

    final deviceResult =
        !dailyOutcome.newlyCredited &&
            (leaderboardResult == DeviceXpResult.okAdded ||
                leaderboardResult == DeviceXpResult.okAddedNoLeaderboard)
        ? DeviceXpResult.okAddedNoLeaderboard
        : leaderboardResult;

    XpTrace.log('FS_OUT', {
      'result': deviceResult.name,
      'traceId': traceId,
      'xpDelta': dailyOutcome.xpDelta,
      'dayXp': dailyOutcome.dayXp ?? 0,
      'penaltiesWritten': dailyOutcome.penalties.length,
    });

    return SessionXpAward(
      result: deviceResult,
      totalXp: dailyOutcome.totalXp,
      dayXp: dailyOutcome.dayXp,
      xpDelta: dailyOutcome.xpDelta,
      components: dailyOutcome.components,
      penalties: dailyOutcome.penalties,
      rulesetId: _xpRulesetId,
      rulesetVersion: _xpRulesetVersion,
    );
  }

  Future<_DailyXpOutcome> _processDailyXp({
    required QuerySnapshot<Map<String, dynamic>> existingDaysSnap,
    required QueryDocumentSnapshot<Map<String, dynamic>>? existingDayDoc,
    required CollectionReference<Map<String, dynamic>> trainingDayCollection,
    required CollectionReference<Map<String, dynamic>> penaltyCollection,
    required DocumentReference<Map<String, dynamic>> statsRef,
    required DateTime sessionDay,
    required String dayKey,
    required String timeZone,
    required String traceId,
  }) async {
    if (existingDayDoc != null) {
      final statsSnap = await statsRef.get();
      final totalXp = (statsSnap.data()?['dailyXP'] as num?)?.toInt();
      final components = _deserializeComponents(
        existingDayDoc.data()['components'],
      );
      final xp = (existingDayDoc.data()['xp'] as num?)?.toInt();
      XpTrace.log('FS_SKIP', {
        'reason': 'alreadyCredited',
        'dayKey': dayKey,
        'traceId': traceId,
      });
      return _DailyXpOutcome(
        newlyCredited: false,
        totalXp: totalXp,
        dayXp: xp,
        xpDelta: 0,
        components: components,
        penalties: const [],
      );
    }

    final existingPenaltySnap = await penaltyCollection.get();
    final existingTrainingDays = existingDaysSnap.docs
        .map((doc) => _parseDayKey(doc.id))
        .whereType<DateTime>()
        .toList();

    final engine = _buildEngine();
    final previousLedger = engine.buildLedger(
      trainingDays: existingTrainingDays,
      timeZone: timeZone,
    );
    final nextLedger = engine.buildLedger(
      trainingDays: [...existingTrainingDays, sessionDay],
      timeZone: timeZone,
    );

    final trainingEvents = nextLedger.events
        .where((event) => event.type == XpLedgerEventType.trainingDay)
        .toList();
    final dayEvent = trainingEvents.firstWhere(
      (event) => event.day.isoDate == dayKey,
      orElse: () {
        throw StateError('Ledger missing training event for $dayKey');
      },
    );

    final prevPenaltyEvents = previousLedger.events
        .where((event) => event.type != XpLedgerEventType.trainingDay)
        .toList();
    final nextPenaltyEvents = nextLedger.events
        .where((event) => event.type != XpLedgerEventType.trainingDay)
        .toList();

    final prevPenaltyIds = prevPenaltyEvents.map(_penaltyDocId).toSet();
    final nextPenaltyIds = nextPenaltyEvents.map(_penaltyDocId).toSet();
    final penaltiesToDelete = prevPenaltyIds.difference(nextPenaltyIds);
    final newPenaltySummaries = nextPenaltyEvents
        .where((event) => !prevPenaltyIds.contains(_penaltyDocId(event)))
        .map(_penaltySummary)
        .toList();

    await _applyLedgerUpdates(
      trainingDayCollection: trainingDayCollection,
      existingTrainingDocs: existingDaysSnap.docs,
      penaltyCollection: penaltyCollection,
      existingPenaltyDocs: existingPenaltySnap.docs,
      trainingEvents: trainingEvents,
      penaltyEvents: nextPenaltyEvents,
      penaltyKeysToDelete: penaltiesToDelete,
      statsRef: statsRef,
      totalXp: nextLedger.totalXp,
      computedTotalXp: nextLedger.computedTotalXp,
      traceId: traceId,
    );

    final xpDelta = nextLedger.totalXp - previousLedger.totalXp;
    final components = dayEvent.components
        .map((component) => component.toJson())
        .toList();

    return _DailyXpOutcome(
      newlyCredited: true,
      totalXp: nextLedger.totalXp,
      dayXp: dayEvent.xpDelta,
      xpDelta: xpDelta,
      components: components,
      penalties: newPenaltySummaries,
    );
  }

  List<Map<String, dynamic>> _deserializeComponents(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((component) => Map<String, dynamic>.from(component))
        .toList();
  }

  TrainingDayXpEngine _buildEngine() {
    return TrainingDayXpEngine(config: const XpEngineConfig(minTotalXp: 0));
  }

  DateTime? _parseDayKey(String dayKey) {
    try {
      return DateTime.parse(dayKey);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _penaltySummary(XpLedgerEvent event) {
    return {
      'id': _penaltyDocId(event),
      'type': event.type.name,
      'xpDelta': event.xpDelta,
      'day': event.day.isoDate,
      'metadata': Map<String, dynamic>.from(event.metadata),
    };
  }

  Future<void> _applyLedgerUpdates({
    required CollectionReference<Map<String, dynamic>> trainingDayCollection,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>>
    existingTrainingDocs,
    required CollectionReference<Map<String, dynamic>> penaltyCollection,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>>
    existingPenaltyDocs,
    required List<XpLedgerEvent> trainingEvents,
    required List<XpLedgerEvent> penaltyEvents,
    required Set<String> penaltyKeysToDelete,
    required DocumentReference<Map<String, dynamic>> statsRef,
    required int totalXp,
    required int computedTotalXp,
    required String traceId,
  }) async {
    final seasonTotals = _computeSeasonTotals(
      trainingEvents: trainingEvents,
      penaltyEvents: penaltyEvents,
    );

    final operations = <void Function(WriteBatch)>[];

    final desiredTrainingIds = trainingEvents
        .map((event) => event.day.isoDate)
        .toSet();
    final trainingDocRefs = {
      for (final doc in existingTrainingDocs) doc.id: doc.reference,
    };
    for (final entry in trainingDocRefs.entries) {
      if (!desiredTrainingIds.contains(entry.key)) {
        operations.add((batch) => batch.delete(entry.value));
      }
    }
    for (final event in trainingEvents) {
      final ref = trainingDayCollection.doc(event.day.isoDate);
      operations.add(
        (batch) => batch.set(
          ref,
          _buildTrainingDayData(
            event: event,
            totalXp: totalXp,
            computedTotalXp: computedTotalXp,
          ),
        ),
      );
    }

    final penaltyDocRefs = {
      for (final doc in existingPenaltyDocs) doc.id: doc.reference,
    };
    for (final key in penaltyKeysToDelete) {
      final ref = penaltyDocRefs[key] ?? penaltyCollection.doc(key);
      operations.add((batch) => batch.delete(ref));
    }
    for (final event in penaltyEvents) {
      final ref = penaltyCollection.doc(_penaltyDocId(event));
      operations.add(
        (batch) => batch.set(
          ref,
          _buildPenaltyData(
            event: event,
            totalXp: totalXp,
            computedTotalXp: computedTotalXp,
          ),
        ),
      );
    }

    final statsData = <String, dynamic>{
      'dailyXP': totalXp,
      'dailyComputedTotalXp': computedTotalXp,
      'dailyTrainingDays': trainingEvents.length,
      'dailyLedgerComputedAt': FieldValue.serverTimestamp(),
      'dailyLedgerVersion': 2,
      'dailyXpRulesetId': _xpRulesetId,
      'dailyXpRulesetVersion': _xpRulesetVersion,
      'seasonXP': seasonTotals,
    };
    if (trainingEvents.isEmpty) {
      statsData['dailyLastTrainingDay'] = FieldValue.delete();
      statsData['dailyStreakLength'] = 0;
      statsData['dailyTimeZone'] = FieldValue.delete();
    } else {
      final last = trainingEvents.last;
      statsData['dailyLastTrainingDay'] = last.day.isoDate;
      statsData['dailyStreakLength'] =
          (last.metadata['streakLength'] as num?)?.toInt() ?? 0;
      statsData['dailyTimeZone'] = last.day.timeZone;
    }
    operations.add(
      (batch) => batch.set(statsRef, statsData, SetOptions(merge: true)),
    );

    XpTrace.log('FS_LEDGER_APPLY', {
      'trainingEvents': trainingEvents.length,
      'penaltyEvents': penaltyEvents.length,
      'ops': operations.length,
      'traceId': traceId,
    });

    await _commitBatchOperations(operations);
  }

  Map<String, int> _computeSeasonTotals({
    required Iterable<XpLedgerEvent> trainingEvents,
    required Iterable<XpLedgerEvent> penaltyEvents,
  }) {
    final totals = {for (final season in _seasonWindows) season.id: 0};
    final events = <XpLedgerEvent>[...trainingEvents, ...penaltyEvents];

    for (final event in events) {
      for (final season in _seasonWindows) {
        if (season.contains(event.day.canonicalDate)) {
          totals[season.id] = (totals[season.id] ?? 0) + event.xpDelta;
        }
      }
    }
    return totals;
  }

  Map<String, dynamic> _buildTrainingDayData({
    required XpLedgerEvent event,
    required int totalXp,
    required int computedTotalXp,
  }) {
    return {
      'xp': event.xpDelta,
      'components': [
        for (final component in event.components)
          Map<String, dynamic>.from(component.toJson()),
      ],
      'metadata': Map<String, dynamic>.from(event.metadata),
      'trainingDayIndex':
          (event.metadata['trainingDayIndex'] as num?)?.toInt() ?? 0,
      'streakLength': (event.metadata['streakLength'] as num?)?.toInt() ?? 0,
      'runningTotalXp': event.runningTotalXp,
      'computedTotalXp': computedTotalXp,
      'totalXp': totalXp,
      'timeZone': event.day.timeZone,
      'ledgerVersion': 2,
      'xpRulesetId': _xpRulesetId,
      'xpRulesetVersion': _xpRulesetVersion,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _buildPenaltyData({
    required XpLedgerEvent event,
    required int totalXp,
    required int computedTotalXp,
  }) {
    return {
      'xp': event.xpDelta,
      'type': event.type.name,
      'metadata': Map<String, dynamic>.from(event.metadata),
      'day': event.day.isoDate,
      'timeZone': event.day.timeZone,
      'runningTotalXp': event.runningTotalXp,
      'totalXp': totalXp,
      'computedTotalXp': computedTotalXp,
      'ledgerVersion': 2,
      'xpRulesetId': _xpRulesetId,
      'xpRulesetVersion': _xpRulesetVersion,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String _penaltyDocId(XpLedgerEvent event) {
    final gapIndex = (event.metadata['gapIndex'] as num?)?.toInt() ?? 0;
    final weekIndex =
        (event.metadata['missedWeekNumber'] as num?)?.toInt() ?? 0;
    return '${event.day.isoDate}_${event.type.name}_g$gapIndex-w$weekIndex';
  }

  Future<void> _commitBatchOperations(
    List<void Function(WriteBatch)> operations,
  ) async {
    if (operations.isEmpty) {
      return;
    }
    final commits = <WriteBatch>[];
    var batch = _firestore.batch();
    var opCount = 0;

    void enqueueBatch() {
      if (opCount == 0) {
        return;
      }
      commits.add(batch);
      batch = _firestore.batch();
      opCount = 0;
    }

    for (final op in operations) {
      op(batch);
      opCount++;
      if (opCount >= 400) {
        enqueueBatch();
      }
    }
    enqueueBatch();

    for (final writeBatch in commits) {
      await writeBatch.commit();
    }
  }

  Future<void> removeSessionXp({
    required String gymId,
    required String userId,
    required String deviceId,
    required String sessionId,
    required String dayKey,
    Iterable<String> exerciseIds = const [],
    List<String> primaryMuscleGroupIds = const [],
    List<String> secondaryMuscleGroupIds = const [],
  }) async {
    final userRef = _firestore.collection('users').doc(userId);
    final dayCollection = userRef.collection('trainingDayXP');
    final penaltyCollection = userRef.collection('xpPenalties');
    final statsRef = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(userId)
        .collection('rank')
        .doc('stats');
    final lbUser = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('leaderboard')
        .doc(userId);
    final lbSess = lbUser.collection('sessions').doc(sessionId);
    final lbDay = lbUser.collection('days').doc(dayKey);

    XpTrace.log('FS_REMOVE_IN', {
      'gymId': gymId,
      'uid': userId,
      'deviceId': deviceId,
      'sessionId': sessionId,
      'dayKey': dayKey,
      'exerciseCount': exerciseIds.where((e) => e.isNotEmpty).length,
    });

    final daySnapshot = await dayCollection.get();
    QueryDocumentSnapshot<Map<String, dynamic>>? targetDoc;
    for (final doc in daySnapshot.docs) {
      if (doc.id == dayKey) {
        targetDoc = doc;
        break;
      }
    }
    if (targetDoc == null) {
      XpTrace.log('FS_REMOVE_SKIP', {
        'reason': 'missingDayDoc',
        'dayKey': dayKey,
        'gymId': gymId,
        'uid': userId,
      });
      return;
    }
    final penaltySnapshot = await penaltyCollection.get();

    final timeZone =
        (targetDoc.data()['timeZone'] as String?) ??
        DateTime.now().timeZoneName;

    final engine = _buildEngine();
    final existingDays = daySnapshot.docs
        .map((doc) => _parseDayKey(doc.id))
        .whereType<DateTime>()
        .toList();
    final remainingDays = daySnapshot.docs
        .where((doc) => doc.id != dayKey)
        .map((doc) => _parseDayKey(doc.id))
        .whereType<DateTime>()
        .toList();

    final previousLedger = engine.buildLedger(
      trainingDays: existingDays,
      timeZone: timeZone,
    );
    final nextLedger = engine.buildLedger(
      trainingDays: remainingDays,
      timeZone: timeZone,
    );

    final nextTrainingEvents = nextLedger.events
        .where((event) => event.type == XpLedgerEventType.trainingDay)
        .toList();
    final prevPenaltyEvents = previousLedger.events
        .where((event) => event.type != XpLedgerEventType.trainingDay)
        .toList();
    final nextPenaltyEvents = nextLedger.events
        .where((event) => event.type != XpLedgerEventType.trainingDay)
        .toList();

    final prevPenaltyIds = prevPenaltyEvents.map(_penaltyDocId).toSet();
    final nextPenaltyIds = nextPenaltyEvents.map(_penaltyDocId).toSet();
    final penaltiesToDelete = prevPenaltyIds.difference(nextPenaltyIds);
    final newPenaltySummaries = nextPenaltyEvents
        .where((event) => !prevPenaltyIds.contains(_penaltyDocId(event)))
        .map(_penaltySummary)
        .toList();

    await _applyLedgerUpdates(
      trainingDayCollection: dayCollection,
      existingTrainingDocs: daySnapshot.docs,
      penaltyCollection: penaltyCollection,
      existingPenaltyDocs: penaltySnapshot.docs,
      trainingEvents: nextTrainingEvents,
      penaltyEvents: nextPenaltyEvents,
      penaltyKeysToDelete: penaltiesToDelete,
      statsRef: statsRef,
      totalXp: nextLedger.totalXp,
      computedTotalXp: nextLedger.computedTotalXp,
      traceId: 'remove:$dayKey:$sessionId',
    );

    final xpDelta = nextLedger.totalXp - previousLedger.totalXp;

    XpTrace.log('FS_REMOVE_LEDGER', {
      'dayKey': dayKey,
      'xpDelta': xpDelta,
      'penaltiesWritten': newPenaltySummaries.length,
      'penaltiesDeleted': penaltiesToDelete.length,
      'remainingDays': nextTrainingEvents.length,
    });

    await _firestore.runTransaction((tx) async {
      final lbUserSnap = await tx.get(lbUser);
      final lbSessSnap = await tx.get(lbSess);
      final lbDaySnap = await tx.get(lbDay);

      const xpDelta = LevelService.xpPerSession;

      if (lbUserSnap.exists) {
        final info = LevelInfo.fromMap(lbUserSnap.data());
        final updated = LevelService().removeXp(info, xpDelta);
        if (updated.level != info.level || updated.xp != info.xp) {
          tx.update(lbUser, {
            'xp': updated.xp,
            'level': updated.level,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      if (lbSessSnap.exists) {
        tx.delete(lbSess);
      }
      if (lbDaySnap.exists) {
        tx.delete(lbDay);
      }
    });

    XpTrace.log('FS_REMOVE_OUT', {
      'gymId': gymId,
      'uid': userId,
      'deviceId': deviceId,
      'sessionId': sessionId,
      'dayKey': dayKey,
    });

    final delta = MuscleXpCalculator.calculateDelta(
      primaryMuscleGroupIds,
      secondaryMuscleGroupIds,
    );
    if (delta.isNotEmpty) {
      final updates = <String, dynamic>{};
      delta.forEach((key, value) {
        updates['${key}XP'] = FieldValue.increment(-value);
      });
      await statsRef.set(updates, SetOptions(merge: true));
      await _updateMuscleXpHistory(
        statsRef: statsRef,
        dayKey: dayKey,
        delta: delta.map((key, value) => MapEntry(key, -value)),
      );
      XpTrace.log('FS_MUSCLE_REMOVE', {
        'traceId': 'remove:$dayKey:$sessionId',
        'primary': primaryMuscleGroupIds.length,
        'secondary': secondaryMuscleGroupIds.length,
        'delta': delta,
      });
    }
  }

  Future<void> _applyMuscleXp({
    required DocumentReference<Map<String, dynamic>> statsRef,
    required List<String> primaryMuscleGroupIds,
    required List<String> secondaryMuscleGroupIds,
    required String traceId,
  }) async {
    final delta = MuscleXpCalculator.calculateDelta(
      primaryMuscleGroupIds,
      secondaryMuscleGroupIds,
    );
    if (delta.isEmpty) return;
    final updates = <String, dynamic>{};
    delta.forEach((key, value) {
      updates['${key}XP'] = FieldValue.increment(value);
    });
    await statsRef.set(updates, SetOptions(merge: true));
    final dayKey = logicDayKey(DateTime.now());
    await _updateMuscleXpHistory(
      statsRef: statsRef,
      dayKey: dayKey,
      delta: delta,
    );
    XpTrace.log('FS_MUSCLE_APPLY', {
      'traceId': traceId,
      'primary': primaryMuscleGroupIds.length,
      'secondary': secondaryMuscleGroupIds.length,
      'delta': delta,
    });
  }

  Future<void> _updateMuscleXpHistory({
    required DocumentReference<Map<String, dynamic>> statsRef,
    required String dayKey,
    required Map<String, int> delta,
  }) async {
    if (delta.isEmpty) return;
    final historyDoc = statsRef.collection('muscleXpHistory').doc(dayKey);
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    delta.forEach((key, value) {
      updates['${key}XP'] = FieldValue.increment(value);
    });
    await historyDoc.set(updates, SetOptions(merge: true));
  }

  Stream<int> watchDayXp({required String userId, required DateTime date}) {
    final dateStr = logicDayKey(date);
    final ref = _firestore
        .collection('users')
        .doc(userId)
        .collection('trainingDayXP')
        .doc(dateStr);
    debugPrint('👀 watchDayXp userId=$userId date=$dateStr');
    return ref.snapshots().map((snap) {
      final xp = (snap.data()?['xp'] as int?) ?? 0;
      debugPrint('📥 dayXp snapshot $xp');
      return xp;
    });
  }

  Stream<DayXpBreakdown> watchDayBreakdown({
    required String userId,
    required DateTime date,
  }) {
    final dayKey = logicDayKey(date);
    final userRef = _firestore.collection('users').doc(userId);
    final dayRef = userRef.collection('trainingDayXP').doc(dayKey);
    final penaltiesRef = userRef
        .collection('xpPenalties')
        .where('day', isEqualTo: dayKey);

    debugPrint('👀 watchDayBreakdown userId=$userId date=$dayKey');
    return dayRef.snapshots().asyncMap((daySnap) async {
      final dayData = daySnap.data() ?? const <String, dynamic>{};
      final componentsRaw = dayData['components'] as List<dynamic>? ?? const [];
      final components = componentsRaw
          .whereType<Map>()
          .map(
            (raw) => DayXpComponentBreakdown(
              code: (raw['code'] as String?) ?? 'unknown',
              amount: (raw['amount'] as num?)?.toInt() ?? 0,
              metadata: _asMetadataMap(raw['metadata']),
            ),
          )
          .toList(growable: false);

      final penaltiesSnap = await penaltiesRef.get();
      final penalties =
          penaltiesSnap.docs
              .map((doc) {
                final data = doc.data();
                return DayXpPenaltyBreakdown(
                  id: doc.id,
                  type: (data['type'] as String?) ?? 'unknown',
                  xpDelta: (data['xp'] as num?)?.toInt() ?? 0,
                  metadata: _asMetadataMap(data['metadata']),
                );
              })
              .toList(growable: false)
            ..sort((a, b) => a.id.compareTo(b.id));

      return DayXpBreakdown(
        dayKey: dayKey,
        dayXp: (dayData['xp'] as num?)?.toInt() ?? 0,
        components: components,
        penalties: penalties,
        rulesetId: dayData['xpRulesetId'] as String?,
        rulesetVersion: (dayData['xpRulesetVersion'] as num?)?.toInt(),
      );
    });
  }

  Map<String, dynamic> _asMetadataMap(dynamic raw) {
    if (raw is! Map) {
      return const <String, dynamic>{};
    }
    return Map<String, dynamic>.from(raw);
  }

  Stream<Map<String, int>> watchMuscleXp({
    required String gymId,
    required String userId,
  }) {
    final doc = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(userId)
        .collection('rank')
        .doc('stats');
    debugPrint('👀 watchMuscleXp userId=$userId gymId=$gymId');
    return doc.snapshots().map((snap) {
      final data = snap.data() ?? {};
      final map = <String, int>{};
      for (final entry in data.entries) {
        final key = entry.key;
        if (key.endsWith('XP') && key != 'dailyXP' && key != 'seasonXP') {
          final value = (entry.value as num?)?.toInt();
          if (value == null) {
            continue;
          }
          final group = key.substring(0, key.length - 2);
          map[group] = value;
        }
      }
      debugPrint('📥 muscleXp snapshot ${map.length} entries $map');
      return map;
    });
  }

  Stream<Map<String, Map<String, int>>> watchMuscleXpHistory({
    required String gymId,
    required String userId,
  }) {
    final col = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(userId)
        .collection('rank')
        .doc('stats')
        .collection('muscleXpHistory')
        .orderBy(FieldPath.documentId);
    debugPrint('👀 watchMuscleXpHistory userId=$userId gymId=$gymId');
    return col.snapshots().map((snap) {
      final map = <String, Map<String, int>>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final dayMap = <String, int>{};
        data.forEach((key, value) {
          if (key.endsWith('XP') && key != 'dailyXP') {
            final group = key.substring(0, key.length - 2);
            dayMap[group] = (value as num?)?.toInt() ?? 0;
          }
        });
        map[doc.id] = dayMap;
      }
      debugPrint('📥 muscleXpHistory snapshot days=${map.length}');
      return map;
    });
  }

  Stream<Map<String, int>> watchTrainingDaysXp(String userId) {
    final col = _firestore
        .collection('users')
        .doc(userId)
        .collection('trainingDayXP');
    debugPrint('👀 watchTrainingDaysXp userId=$userId');
    return col.snapshots().map((snap) {
      final map = <String, int>{};
      for (final doc in snap.docs) {
        map[doc.id] = (doc.data()['xp'] as int? ?? 0);
      }
      debugPrint('📥 trainingDays snapshot ${map.length} days');
      return map;
    });
  }

  Stream<int> watchDeviceXp({
    required String gymId,
    required String deviceId,
    required String userId,
  }) {
    final doc = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('leaderboard')
        .doc(userId);
    if (kDebugMode && _logDeviceXpWatchers) {
      debugPrint(
        '👀 watchDeviceXp gymId=$gymId deviceId=$deviceId userId=$userId',
      );
    }
    return doc.snapshots().map((snap) {
      final xp = (snap.data()?['xp'] as int?) ?? 0;
      if (kDebugMode && _logDeviceXpWatchers) {
        debugPrint('📥 deviceXp snapshot $xp');
      }
      return xp;
    });
  }

  Stream<Map<String, int>> watchDeviceXpBulk({
    required String gymId,
    required String userId,
    required List<String> deviceIds,
  }) {
    if (deviceIds.isEmpty) {
      return Stream.value(<String, int>{});
    }
    final deviceIdSet = deviceIds.toSet();
    final query = _firestore
        .collectionGroup('leaderboard')
        .where('userId', isEqualTo: userId);
    return query.snapshots().map((snap) {
      final map = <String, int>{};
      for (final id in deviceIds) {
        map[id] = 0;
      }
      for (final doc in snap.docs) {
        final deviceRef = doc.reference.parent.parent;
        final gymRef = deviceRef?.parent.parent;
        if (deviceRef == null || gymRef == null) {
          continue;
        }
        if (gymRef.id != gymId) {
          continue;
        }
        final deviceId = deviceRef.id;
        if (!deviceIdSet.contains(deviceId)) {
          continue;
        }
        final data = doc.data();
        final xp = (data['xp'] as int?) ?? 0;
        map[deviceId] = xp;
      }
      return map;
    });
  }

  Future<int> fetchStatsDailyXp({
    required String gymId,
    required String userId,
  }) async {
    final doc = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(userId)
        .collection('rank')
        .doc('stats');
    debugPrint('📄 fetchStatsDailyXp gymId=$gymId userId=$userId');
    final snap = await doc.get();
    final xp = (snap.data()?['dailyXP'] as int?) ?? 0;
    debugPrint('📄 stats dailyXP fetch $xp');
    return xp;
  }

  Stream<int> watchStatsDailyXp({
    required String gymId,
    required String userId,
  }) {
    final doc = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(userId)
        .collection('rank')
        .doc('stats');
    debugPrint('👀 watchStatsDailyXp gymId=$gymId userId=$userId');
    return doc.snapshots().map((snap) {
      final xp = (snap.data()?['dailyXP'] as int?) ?? 0;
      debugPrint('📥 stats dailyXP snapshot $xp');
      return xp;
    });
  }
}

class _DailyXpOutcome {
  const _DailyXpOutcome({
    required this.newlyCredited,
    required this.totalXp,
    required this.dayXp,
    required this.xpDelta,
    required this.components,
    required this.penalties,
  });

  final bool newlyCredited;
  final int? totalXp;
  final int? dayXp;
  final int xpDelta;
  final List<Map<String, dynamic>> components;
  final List<Map<String, dynamic>> penalties;
}
