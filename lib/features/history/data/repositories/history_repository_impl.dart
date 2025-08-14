// lib/features/history/data/repositories/history_repository_impl.dart

import '../sources/firestore_history_source.dart';
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
    return dtos.map((d) => d.toModel()).toList();
  }
}
