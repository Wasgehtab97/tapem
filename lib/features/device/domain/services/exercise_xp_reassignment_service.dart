import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:tapem/core/time/logic_day.dart';
import 'package:tapem/features/training_details/data/session_meta_source.dart';
import 'package:tapem/features/xp/domain/muscle_xp_calculator.dart';

/// Reassigns muscle XP for all sessions of an exercise when the configuration
/// changes.
class ExerciseXpReassignmentService {
  final FirebaseFirestore _firestore;
  final SessionMetaSource _metaSource;

  ExerciseXpReassignmentService({
    FirebaseFirestore? firestore,
    SessionMetaSource? metaSource,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _metaSource = metaSource ?? SessionMetaSource(firestore: firestore);

  Future<void> reassign({
    required String gymId,
    required String deviceId,
    required String exerciseId,
    required String userId,
    required List<String> newPrimaryIds,
    required List<String> newSecondaryIds,
  }) async {
    final normalizedPrimary = _normalize(newPrimaryIds);
    final normalizedSecondary = _normalize(
      newSecondaryIds,
      exclude: normalizedPrimary,
    );

    final query = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('sessions')
        .where('userId', isEqualTo: userId)
        .where('exerciseId', isEqualTo: exerciseId)
        .get();

    if (query.docs.isEmpty) return;

    final adjustments = <_SessionAdjustment>[];
    for (final doc in query.docs) {
      final data = doc.data();
      final sessionId = (data['sessionId'] as String?) ?? doc.id;
      final createdAtRaw = data['createdAt'];
      DateTime? createdAt;
      if (createdAtRaw is Timestamp) {
        createdAt = createdAtRaw.toDate();
      }
      final sessionPrimary = _normalize(
        _stringListFrom(data['primaryMuscleGroupIds']),
      );
      final sessionSecondary = _normalize(
        _stringListFrom(data['secondaryMuscleGroupIds']),
        exclude: sessionPrimary,
      );
      if (MuscleXpCalculator.listsEqual(sessionPrimary, normalizedPrimary) &&
          MuscleXpCalculator.listsEqual(sessionSecondary, normalizedSecondary)) {
        continue;
      }
      adjustments.add(
        _SessionAdjustment(
          reference: doc.reference,
          sessionId: sessionId,
          createdAt: createdAt,
          previousPrimary: sessionPrimary,
          previousSecondary: sessionSecondary,
        ),
      );
    }

    if (adjustments.isEmpty) {
      return;
    }

    final metas = await Future.wait(adjustments.map((adj) async {
      try {
        return await _metaSource.getMetaBySessionId(
          gymId: gymId,
          uid: userId,
          sessionId: adj.sessionId,
        );
      } catch (e) {
        debugPrint('⚠️ Failed to load session meta for ${adj.sessionId}: $e');
        return null;
      }
    }));

    final globalDelta = <String, int>{};
    final historyDelta = <String, Map<String, int>>{};
    final newDelta = MuscleXpCalculator.calculateDelta(
      normalizedPrimary,
      normalizedSecondary,
    );
    final revision = DateTime.now().millisecondsSinceEpoch;

    WriteBatch? batch;
    var ops = 0;
    Future<void> commitBatch() async {
      if (batch != null && ops > 0) {
        await batch!.commit();
      }
      batch = _firestore.batch();
      ops = 0;
    }

    await commitBatch();

    for (var i = 0; i < adjustments.length; i++) {
      final adj = adjustments[i];
      final meta = metas[i];
      final dayKey = (meta?['dayKey'] as String?) ??
          logicDayKey((adj.createdAt ?? DateTime.now()).toLocal());

      final oldDelta = MuscleXpCalculator.calculateDelta(
        adj.previousPrimary,
        adj.previousSecondary,
      );
      final keys = {...oldDelta.keys, ...newDelta.keys};
      for (final key in keys) {
        final change = (newDelta[key] ?? 0) - (oldDelta[key] ?? 0);
        if (change == 0) continue;
        globalDelta[key] = (globalDelta[key] ?? 0) + change;
        final dayMap = historyDelta.putIfAbsent(dayKey, () => {});
        dayMap[key] = (dayMap[key] ?? 0) + change;
      }

      batch!.update(adj.reference, {
        'primaryMuscleGroupIds': normalizedPrimary,
        'secondaryMuscleGroupIds': normalizedSecondary,
        'muscleGroupRevision': revision,
      });
      ops++;
      if (ops >= 400) {
        await commitBatch();
      }
    }

    if (ops > 0 && batch != null) {
      await batch!.commit();
    }

    if (globalDelta.isEmpty && historyDelta.isEmpty) {
      return;
    }

    final statsRef = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(userId)
        .collection('rank')
        .doc('stats');

    if (globalDelta.isNotEmpty) {
      final statsUpdates = <String, dynamic>{};
      globalDelta.forEach((key, value) {
        if (value != 0) {
          statsUpdates['${key}XP'] = FieldValue.increment(value);
        }
      });
      if (statsUpdates.isNotEmpty) {
        await statsRef.set(statsUpdates, SetOptions(merge: true));
      }
    }

    for (final entry in historyDelta.entries) {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      entry.value.forEach((key, value) {
        if (value != 0) {
          updates['${key}XP'] = FieldValue.increment(value);
        }
      });
      if (updates.length > 1) {
        await statsRef
            .collection('muscleXpHistory')
            .doc(entry.key)
            .set(updates, SetOptions(merge: true));
      }
    }
  }

  List<String> _normalize(List<String> values, {List<String>? exclude}) {
    final result = <String>[];
    final existing = {...?exclude};
    for (final raw in values) {
      final value = raw.trim();
      if (value.isEmpty) continue;
      if (existing.add(value)) {
        result.add(value);
      }
    }
    return result;
  }

  List<String> _stringListFrom(dynamic value) {
    if (value is Iterable) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }
}

class _SessionAdjustment {
  final DocumentReference<Map<String, dynamic>> reference;
  final String sessionId;
  final DateTime? createdAt;
  final List<String> previousPrimary;
  final List<String> previousSecondary;

  _SessionAdjustment({
    required this.reference,
    required this.sessionId,
    required this.createdAt,
    required this.previousPrimary,
    required this.previousSecondary,
  });
}
