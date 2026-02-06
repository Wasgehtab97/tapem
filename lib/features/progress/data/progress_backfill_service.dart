import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressBackfillResult {
  final int sessionCount;
  final int exerciseCount;

  const ProgressBackfillResult({
    required this.sessionCount,
    required this.exerciseCount,
  });
}

class ProgressBackfillService {
  final FirebaseFirestore _firestore;

  ProgressBackfillService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<ProgressBackfillResult> backfillYear({
    required String gymId,
    required String userId,
    required int year,
  }) async {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year + 1, 1, 1).subtract(
      const Duration(milliseconds: 1),
    );

    final sessions = <String, _SessionAgg>{};
    DocumentSnapshot<Map<String, dynamic>>? lastDoc;
    const pageSize = 500;

    while (true) {
      var query = _firestore
          .collectionGroup('logs')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('timestamp')
          .limit(pageSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snap = await query.get();
      if (snap.docs.isEmpty) {
        break;
      }

      for (final doc in snap.docs) {
        final data = doc.data();
        final sessionId = data['sessionId'] as String?;
        if (sessionId == null || sessionId.isEmpty) continue;

        final ts = data['timestamp'];
        if (ts is! Timestamp) continue;

        final weight = (data['weight'] as num?)?.toDouble() ?? 0.0;
        final reps = (data['reps'] as num?)?.toInt() ?? 0;
        if (weight <= 0 || reps <= 0) continue;

        final deviceRef = doc.reference.parent.parent;
        final deviceId = deviceRef?.id ?? data['deviceId'] as String? ?? '';
        if (deviceId.isEmpty) continue;
        final gymRef = deviceRef?.parent.parent;
        final gymIdFromPath = gymRef?.id ?? '';
        if (gymIdFromPath.isNotEmpty && gymIdFromPath != gymId) {
          continue;
        }

        final exerciseId = (data['exerciseId'] as String? ?? '').trim();
        final e1rm = _calculateE1rm(weight, reps);

        final existing = sessions[sessionId];
        if (existing == null) {
          sessions[sessionId] = _SessionAgg(
            sessionId: sessionId,
            deviceId: deviceId,
            exerciseId: exerciseId,
            timestamp: ts.toDate(),
            bestE1rm: e1rm,
          );
        } else {
          if (e1rm > existing.bestE1rm) {
            existing.bestE1rm = e1rm;
          }
          final candidateTs = ts.toDate();
          if (candidateTs.isAfter(existing.timestamp)) {
            existing.timestamp = candidateTs;
          }
        }
      }

      lastDoc = snap.docs.last;
    }

    if (sessions.isEmpty) {
      return const ProgressBackfillResult(sessionCount: 0, exerciseCount: 0);
    }

    final deviceCache = <String, _DeviceMeta>{};
    final exerciseCache = <String, String>{};
    final pointsByKey = <String, Map<String, _DayPoint>>{};
    final sessionCounts = <String, int>{};
    final lastSessionAt = <String, DateTime>{};
    final metaByKey = <String, _ProgressMeta>{};

    for (final session in sessions.values) {
      final isMulti = session.exerciseId.isNotEmpty;
      final key = isMulti
          ? '${session.deviceId}::${session.exerciseId}'
          : session.deviceId;

      sessionCounts[key] = (sessionCounts[key] ?? 0) + 1;
      final dayKey = _dayKey(session.timestamp);

      final dayMap = pointsByKey.putIfAbsent(key, () => {});
      final existingPoint = dayMap[dayKey];
      if (existingPoint == null ||
          session.timestamp.isAfter(existingPoint.timestamp)) {
        dayMap[dayKey] = _DayPoint(
          sessionId: session.sessionId,
          timestamp: session.timestamp,
          e1rm: session.bestE1rm,
        );
      }

      final currentLast = lastSessionAt[key];
      if (currentLast == null || session.timestamp.isAfter(currentLast)) {
        lastSessionAt[key] = session.timestamp;
      }

      if (!metaByKey.containsKey(key)) {
        final deviceMeta =
            await _resolveDeviceMeta(gymId, session.deviceId, deviceCache);
        final exerciseName = isMulti
            ? await _resolveExerciseName(
                gymId,
                session.deviceId,
                session.exerciseId,
                exerciseCache,
              )
            : '';
        final title = isMulti
            ? (exerciseName.isNotEmpty
                ? exerciseName
                : session.exerciseId)
            : deviceMeta.name;
        final subtitle = isMulti ? deviceMeta.name : deviceMeta.description;
        metaByKey[key] = _ProgressMeta(
          deviceId: session.deviceId,
          exerciseId: session.exerciseId,
          isMulti: isMulti,
          title: title,
          subtitle: subtitle,
        );
      }
    }

    WriteBatch batch = _firestore.batch();
    var opCount = 0;
    final indexRef = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(userId)
        .collection('progressIndex')
        .doc(year.toString());

    Future<void> commitBatch() async {
      if (opCount == 0) return;
      await batch.commit();
      batch = _firestore.batch();
      opCount = 0;
    }

    final itemsMap = <String, dynamic>{};
    for (final entry in pointsByKey.entries) {
      final key = entry.key;
      final meta = metaByKey[key];
      if (meta == null) continue;
      final pointsMap = entry.value.map(
        (day, point) => MapEntry(day, {
          'sessionId': point.sessionId,
          'ts': Timestamp.fromDate(point.timestamp),
          'e1rm': point.e1rm,
        }),
      );

      final progressRef = _firestore
          .collection('gyms')
          .doc(gymId)
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc(key)
          .collection('years')
          .doc(year.toString());

      batch.set(
        progressRef,
        {
          'deviceId': meta.deviceId,
          'exerciseId': meta.exerciseId,
          'isMulti': meta.isMulti,
          'title': meta.title,
          'subtitle': meta.subtitle,
          'year': year,
          'updatedAt': FieldValue.serverTimestamp(),
          'sessionCount': sessionCounts[key] ?? 0,
          'pointsByDay': pointsMap,
        },
        SetOptions(merge: false),
      );
      opCount++;

      itemsMap[key] = {
        'deviceId': meta.deviceId,
        'exerciseId': meta.exerciseId,
        'isMulti': meta.isMulti,
        'title': meta.title,
        'subtitle': meta.subtitle,
        'sessionCount': sessionCounts[key] ?? 0,
        'lastSessionAt': Timestamp.fromDate(lastSessionAt[key] ?? start),
      };

      if (opCount >= 400) {
        await commitBatch();
      }
    }

    if (opCount >= 400) {
      await commitBatch();
    }
    batch.set(
      indexRef,
      {
        'year': year,
        'updatedAt': FieldValue.serverTimestamp(),
        'items': itemsMap,
      },
      SetOptions(merge: false),
    );
    opCount++;

    await commitBatch();

    return ProgressBackfillResult(
      sessionCount: sessions.length,
      exerciseCount: pointsByKey.length,
    );
  }

  double _calculateE1rm(double weight, int reps) {
    return weight * (1 + reps / 30);
  }

  String _dayKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<_DeviceMeta> _resolveDeviceMeta(
    String gymId,
    String deviceId,
    Map<String, _DeviceMeta> cache,
  ) async {
    final cached = cache[deviceId];
    if (cached != null) return cached;
    final ref =
        _firestore.collection('gyms').doc(gymId).collection('devices').doc(deviceId);
    final snap = await ref.get();
    final data = snap.data();
    final meta = _DeviceMeta(
      name: data?['name'] as String? ?? deviceId,
      description: data?['description'] as String? ?? '',
    );
    cache[deviceId] = meta;
    return meta;
  }

  Future<String> _resolveExerciseName(
    String gymId,
    String deviceId,
    String exerciseId,
    Map<String, String> cache,
  ) async {
    if (exerciseId.isEmpty) return '';
    final key = '$deviceId::$exerciseId';
    final cached = cache[key];
    if (cached != null) return cached;
    final ref = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('exercises')
        .doc(exerciseId);
    final snap = await ref.get();
    final name = snap.data()?['name'] as String? ?? '';
    cache[key] = name;
    return name;
  }
}

class _SessionAgg {
  final String sessionId;
  final String deviceId;
  final String exerciseId;
  DateTime timestamp;
  double bestE1rm;

  _SessionAgg({
    required this.sessionId,
    required this.deviceId,
    required this.exerciseId,
    required this.timestamp,
    required this.bestE1rm,
  });
}

class _DayPoint {
  final String sessionId;
  final DateTime timestamp;
  final double e1rm;

  _DayPoint({
    required this.sessionId,
    required this.timestamp,
    required this.e1rm,
  });
}

class _DeviceMeta {
  final String name;
  final String description;

  _DeviceMeta({
    required this.name,
    required this.description,
  });
}

class _ProgressMeta {
  final String deviceId;
  final String exerciseId;
  final bool isMulti;
  final String title;
  final String subtitle;

  _ProgressMeta({
    required this.deviceId,
    required this.exerciseId,
    required this.isMulti,
    required this.title,
    required this.subtitle,
  });
}
