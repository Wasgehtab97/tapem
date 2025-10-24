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
import 'package:tapem/features/xp/domain/muscle_xp_calculator.dart';
import 'package:tapem/features/xp/domain/session_xp_award.dart';
import 'package:tapem/features/xp/domain/training_day_xp_engine.dart';

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
    final sessionDay = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
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

    if (existingDayDoc != null) {
      final statsSnap = await statsRef.get();
      final totalXp = (statsSnap.data()?['dailyXP'] as num?)?.toInt();
      final components = _deserializeComponents(existingDayDoc.data()['components']);
      final xp = (existingDayDoc.data()['xp'] as num?)?.toInt() ?? 0;
      XpTrace.log('FS_SKIP', {
        'reason': 'alreadyCredited',
        'dayKey': dayKey,
        'traceId': traceId,
      });
      return SessionXpAward(
        result: DeviceXpResult.alreadyToday,
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
      trainingDayCollection: dayCollection,
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

    final xpDelta = nextLedger.totalXp - previousLedger.totalXp;
    final components = dayEvent.components.map((component) => component.toJson()).toList();

    XpTrace.log('FS_OUT', {
      'result': leaderboardResult.name,
      'traceId': traceId,
      'xpDelta': xpDelta,
      'dayXp': dayEvent.xpDelta,
      'penaltiesWritten': newPenaltySummaries.length,
    });

    return SessionXpAward(
      result: leaderboardResult,
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
    return TrainingDayXpEngine(
      config: const XpEngineConfig(minTotalXp: 0),
    );
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
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> existingTrainingDocs,
    required CollectionReference<Map<String, dynamic>> penaltyCollection,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> existingPenaltyDocs,
    required List<XpLedgerEvent> trainingEvents,
    required List<XpLedgerEvent> penaltyEvents,
    required Set<String> penaltyKeysToDelete,
    required DocumentReference<Map<String, dynamic>> statsRef,
    required int totalXp,
    required int computedTotalXp,
    required String traceId,
  }) async {
    final operations = <void Function(WriteBatch)>[];

    final desiredTrainingIds =
        trainingEvents.map((event) => event.day.isoDate).toSet();
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
      (batch) => batch.set(
        statsRef,
        statsData,
        SetOptions(merge: true),
      ),
    );

    XpTrace.log('FS_LEDGER_APPLY', {
      'trainingEvents': trainingEvents.length,
      'penaltyEvents': penaltyEvents.length,
      'ops': operations.length,
      'traceId': traceId,
    });

    await _commitBatchOperations(operations);
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
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String _penaltyDocId(XpLedgerEvent event) {
    final gapIndex = (event.metadata['gapIndex'] as num?)?.toInt() ?? 0;
    final weekIndex = (event.metadata['missedWeekNumber'] as num?)?.toInt() ?? 0;
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

    final timeZone = (targetDoc.data()['timeZone'] as String?) ??
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
        if (key.endsWith('XP') && key != 'dailyXP') {
          final group = key.substring(0, key.length - 2);
          map[group] = (entry.value as int? ?? 0);
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
    debugPrint(
      '👀 watchDeviceXp gymId=$gymId deviceId=$deviceId userId=$userId',
    );
    return doc.snapshots().map((snap) {
      final xp = (snap.data()?['xp'] as int?) ?? 0;
      debugPrint('📥 deviceXp snapshot $xp');
      return xp;
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
