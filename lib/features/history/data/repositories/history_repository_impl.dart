// lib/features/history/data/repositories/history_repository_impl.dart
import '../../domain/models/workout_log.dart';
import '../../domain/repositories/history_repository.dart';
import '../dtos/workout_log_dto.dart';
import '../sources/firestore_history_source.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final FirestoreHistorySource _source;
  HistoryRepositoryImpl(this._source);

  @override
  Future<List<WorkoutLog>> getHistory(
      String gymId, String deviceId, String userId) async {
    final dtos = await _source.getLogs(gymId, deviceId, userId);
    return dtos.map((dto) => dto.toModel()).toList();
  }
}
