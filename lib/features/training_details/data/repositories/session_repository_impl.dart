import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/features/training_details/data/dtos/session_dto.dart';
import 'package:tapem/features/training_details/data/sources/firestore_session_source.dart';
import 'package:tapem/features/training_details/data/session_meta_source.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';
import 'package:tapem/features/training_details/domain/repositories/session_repository.dart';

class SessionRepositoryImpl implements SessionRepository {
  final FirestoreSessionSource _source;
  final SessionMetaSource _meta;
  SessionRepositoryImpl(this._source, this._meta);

  @override
  Future<List<Session>> getSessionsForDate({
    required String userId,
    required DateTime date,
  }) async {
    final dtos = await _source.getSessionsForDate(userId: userId, date: date);

    // 1) Gruppieren
    final Map<String, List<SessionDto>> grouped = {};
    for (var dto in dtos) {
      grouped.putIfAbsent(dto.sessionId, () => []).add(dto);
    }

    final List<Session> sessions = [];

    // 2) Für jede Gruppe: sortieren, Sets mappen, Namen+Description holen
    final deviceCache =
        <String, DocumentSnapshot<Map<String, dynamic>>>{};
    final exerciseCache =
        <String, DocumentSnapshot<Map<String, dynamic>>>{};
    for (var entry in grouped.entries) {
      final list = entry.value;
      if (list.any((d) => d.setNumber <= 0)) {
        list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        try {
          await _source.backfillSetNumbers(list);
        } catch (_) {}
      } else {
        list.sort((a, b) => a.setNumber.compareTo(b.setNumber));
      }

      final first = list.first;
      final deviceRef = first.reference.parent.parent!;
      var deviceName = first.deviceId;
      var deviceDescription = '';
      var isMulti = false;

      DocumentSnapshot<Map<String, dynamic>>? deviceSnap =
          deviceCache[deviceRef.path];
      if (deviceSnap == null) {
        try {
          deviceSnap = await deviceRef.get();
          deviceCache[deviceRef.path] = deviceSnap;
        } on FirebaseException {
          deviceSnap = null;
        }
      }

      final data = deviceSnap?.data();
      if (data != null) {
        deviceName = (data['name'] as String?) ?? first.deviceId;
        deviceDescription = (data['description'] as String?) ?? '';
        isMulti = (data['isMulti'] as bool?) ?? false;
      }

      if (isMulti && first.exerciseId.isNotEmpty) {
        final exRef = deviceRef.collection('exercises').doc(first.exerciseId);
        DocumentSnapshot<Map<String, dynamic>>? exSnap =
            exerciseCache[exRef.path];
        if (exSnap == null) {
          try {
            exSnap = await exRef.get();
            exerciseCache[exRef.path] = exSnap;
          } on FirebaseException {
            exSnap = null;
          }
        }
        if (exSnap != null && exSnap.exists) {
          final exName = (exSnap.data()?['name'] as String?) ?? '';
          if (exName.isNotEmpty) deviceName = exName;
        }
      }

      final sets = list
          .map((dto) => SessionSet(
                weight: dto.weight,
                reps: dto.reps,
                setNumber: dto.setNumber,
                dropWeightKg: dto.dropWeightKg,
                dropReps: dto.dropReps,
                isBodyweight: dto.isBodyweight,
              ))
          .toList();

      final gymId = deviceRef.parent.parent!.id;
      DateTime? startTime;
      DateTime? endTime;
      int? durationMs;
      try {
        final meta = await _meta.getMetaBySessionId(
          gymId: gymId,
          uid: first.userId,
          sessionId: first.sessionId,
        );
        if (meta != null) {
          final startTs = meta['startTime'];
          final endTs = meta['endTime'];
          if (startTs is Timestamp) startTime = startTs.toDate();
          if (endTs is Timestamp) endTime = endTs.toDate();
          durationMs = (meta['durationMs'] as num?)?.toInt();
        }
      } catch (_) {}

      sessions.add(
        Session(
          sessionId: first.sessionId,
          deviceId: first.deviceId,
          deviceName: deviceName,
          deviceDescription: deviceDescription,
          timestamp: first.timestamp,
          note: first.note,
          sets: sets,
          startTime: startTime,
          endTime: endTime,
          durationMs: durationMs,
        ),
      );
    }

    sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sessions;
  }
}
