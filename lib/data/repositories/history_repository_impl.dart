import 'package:tapem/domain/models/exercise_entry.dart';
import 'package:tapem/domain/repositories/history_repository.dart';
import 'package:tapem/data/sources/history/firestore_history_source.dart';

/// Firestore-Implementierung von [HistoryRepository].
class HistoryRepositoryImpl implements HistoryRepository {
  final FirestoreHistorySource _source;
  HistoryRepositoryImpl({FirestoreHistorySource? source})
      : _source = source ?? FirestoreHistorySource();

  @override
  Future<String?> getCurrentUserId() {
    return _source.getCurrentUserId();
  }

  @override
  Future<List<ExerciseEntry>> fetchHistory({
    required String userId,
    required String deviceId,
    String? exercise,
  }) async {
    final raw = await _source.fetchHistory(
      userId: userId,
      deviceId: deviceId,
      exercise: exercise,
    );
    // raw enthält jeweils Map mit Feld 'id'
    return raw
        .map((m) => ExerciseEntry.fromMap(
              m,
              id: m['id'] as String,
            ))
        .toList();
  }
}
