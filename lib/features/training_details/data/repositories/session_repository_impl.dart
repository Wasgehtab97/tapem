import 'package:cloud_firestore/cloud_firestore.dart';
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

    // 1) Gruppieren
    final Map<String, List<SessionDto>> grouped = {};
    for (var dto in dtos) {
      grouped.putIfAbsent(dto.sessionId, () => []).add(dto);
    }

    final List<Session> sessions = [];

    // 2) Für jede Gruppe: sortieren, Sets mappen, Namen+Description holen
    for (var entry in grouped.entries) {
      final list =
          entry.value..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final first = list.first;

      // Referenz aufs Device-Dokument:
      final deviceRef = first.reference.parent.parent!;
      final deviceSnap = await deviceRef.get();
      final data = deviceSnap.data()!;

      var deviceName = (data['name'] as String?) ?? first.deviceId;
      final deviceDescription = (data['description'] as String?) ?? '';
      final isMulti = (data['isMulti'] as bool?) ?? false;

      if (isMulti && first.exerciseId.isNotEmpty) {
        final exSnap =
            await deviceRef.collection('exercises').doc(first.exerciseId).get();
        if (exSnap.exists) {
          final exName = (exSnap.data()?["name"] as String?) ?? '';
          if (exName.isNotEmpty) deviceName = exName;
        }
      }

      final sets =
          list
              .map((dto) => SessionSet(weight: dto.weight, reps: dto.reps))
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
