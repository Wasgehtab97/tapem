import 'package:tapem/domain/models/dashboard_data.dart';
import 'package:tapem/domain/repositories/dashboard_repository.dart';
import 'package:tapem/data/sources/dashboard/firestore_dashboard_source.dart';

/// Firestore-Implementierung von [DashboardRepository].
class DashboardRepositoryImpl implements DashboardRepository {
  final FirestoreDashboardSource _source;
  DashboardRepositoryImpl({FirestoreDashboardSource? source})
      : _source = source ?? FirestoreDashboardSource();

  @override
  Future<DashboardData> loadDevice(String deviceId, {String? secretCode}) {
    return _source.loadDevice(deviceId, secretCode: secretCode);
  }

  @override
  Future<void> addSet({
    required String deviceId,
    required String exercise,
    required int sets,
    required double weight,
    required int reps,
  }) {
    return _source.addSet(
      deviceId: deviceId,
      exercise: exercise,
      sets: sets,
      weight: weight,
      reps: reps,
    );
  }

  @override
  Future<void> finishSession({
    required String deviceId,
    required String exercise,
  }) {
    return _source.finishSession(deviceId: deviceId, exercise: exercise);
  }
}
