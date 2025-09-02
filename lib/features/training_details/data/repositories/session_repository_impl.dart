import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/features/training_details/data/dtos/session_dto.dart';
import 'package:tapem/features/training_details/data/sources/firestore_session_source.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';
import 'package:tapem/features/training_details/domain/repositories/session_repository.dart';

class SessionRepositoryImpl implements SessionRepository {
  final FirestoreSessionSource _source;
  SessionRepositoryImpl(this._source);

  @override
  Future<List<Session>> getSessionsForDate({
    required String userId,
    required DateTime date,
  }) async {
    final dtos = await _source.getSessionsForDate(userId: userId, date: date);
    debugPrint('SessionRepositoryImpl: processing ' + dtos.length.toString() + ' log dtos');

    // 1) Gruppieren
    final Map<String, List<SessionDto>> grouped = {};
    for (var dto in dtos) {
      grouped.putIfAbsent(dto.sessionId, () => []).add(dto);
    }

    final List<Session> sessions = [];

    // 2) Für jede Gruppe: sortieren, Sets mappen, Namen+Description holen
    for (var entry in grouped.entries) {
      final list = entry.value;
      final rawNums = list.map((d) => d.setNumber).toList();
      elogUi('SESSION_READ_RAW_SETS', {
        'sessionId': entry.key,
        'rawSetNumbers': rawNums,
        'rawCount': list.length,
      });

      var usedKey = 'setNumber';
      if (list.any((d) => d.setNumber <= 0)) {
        usedKey = 'timestamp';
        list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        elogUi('ORDER_FALLBACK_USED', {
          'sessionId': entry.key,
          'reason': 'missing',
        });
        try {
          await _source.backfillSetNumbers(list);
        } catch (_) {}
      } else {
        list.sort((a, b) => a.setNumber.compareTo(b.setNumber));
      }

      elogUi('SESSION_SORT_APPLIED', {
        'sessionId': entry.key,
        'usedKey': usedKey,
        'sortedSetNumbers': list.map((e) => e.setNumber).toList(),
        'finalCount': list.length,
      });

      final first = list.first;

      // Referenz aufs Device-Dokument:
      final deviceRef = first.reference.parent.parent!;
      debugPrint('SessionRepositoryImpl: read path=' +
          deviceRef.path +
          ' owner=' +
          first.userId);

      var deviceName = first.deviceId;
      var deviceDescription = '';
      var isMulti = false;
      try {
        final deviceSnap = await deviceRef.get();
        debugPrint('SessionRepositoryImpl: success path=' + deviceRef.path);
        final data = deviceSnap.data();
        if (data != null) {
          deviceName = (data['name'] as String?) ?? first.deviceId;
          deviceDescription = (data['description'] as String?) ?? '';
          isMulti = (data['isMulti'] as bool?) ?? false;
        }
      } on FirebaseException catch (e) {
        debugPrint('SessionRepositoryImpl: failure path=' +
            deviceRef.path +
            ' code=' +
            e.code);
      }
      debugPrint('SessionRepositoryImpl: deviceName=' +
          deviceName +
          ' isMulti=' +
          isMulti.toString());

      if (isMulti && first.exerciseId.isNotEmpty) {
        final exRef = deviceRef.collection('exercises').doc(first.exerciseId);
        debugPrint('SessionRepositoryImpl: read path=' +
            exRef.path +
            ' owner=' +
            first.userId);
        try {
          final exSnap = await exRef.get();
          debugPrint('SessionRepositoryImpl: success path=' + exRef.path);
          if (exSnap.exists) {
            final exName = (exSnap.data()?['name'] as String?) ?? '';
            if (exName.isNotEmpty) deviceName = exName;
          }
        } on FirebaseException catch (e) {
          debugPrint('SessionRepositoryImpl: failure path=' +
              exRef.path +
              ' code=' +
              e.code);
        }
      }

      final sets = list
          .map((dto) => SessionSet(
                weight: dto.weight,
                reps: dto.reps,
                setNumber: dto.setNumber,
                dropWeightKg: dto.dropWeightKg,
                dropReps: dto.dropReps,
              ))
          .toList();

      sessions.add(
        Session(
          sessionId: first.sessionId,
          deviceId: first.deviceId,
          deviceName: deviceName,
          deviceDescription: deviceDescription,
          timestamp: first.timestamp,
          note: first.note,
          sets: sets,
        ),
      );
    }

    // 3) Neueste zuerst
    sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sessions;
  }
}
