// lib/features/history/data/repositories/history_repository_impl.dart

import '../sources/firestore_history_source.dart';
import '../dtos/workout_log_dto.dart';
import '../../domain/models/workout_log.dart';
import '../../domain/usecases/get_history_for_device.dart';

class HistoryRepositoryImpl implements GetHistoryForDeviceRepository {
  final FirestoreHistorySource _source;
  HistoryRepositoryImpl(this._source);

  @override
  Future<List<WorkoutLog>> getHistory({
    required String gymId,
    required String deviceId,
    required String userId,
    String? exerciseId,
  }) async {
    final dtos = await _source.getLogs(
      gymId: gymId,
      deviceId: deviceId,
      userId: userId,
      exerciseId: exerciseId,
    );

    final Map<String, List<WorkoutLogDto>> grouped = {};
    for (var dto in dtos) {
      grouped.putIfAbsent(dto.sessionId, () => []).add(dto);
    }

    final List<WorkoutLog> logs = [];
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

      logs.addAll(list.map((d) => d.toModel()));
    }

    return logs;
  }
}
