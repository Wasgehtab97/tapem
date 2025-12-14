import 'package:tapem/features/coaching/data/sources/firestore_coaching_source.dart';
import 'package:tapem/features/coaching/domain/models/coach_client_relation.dart';
import 'package:tapem/features/coaching/domain/repositories/coaching_repository.dart';

class CoachingRepositoryImpl implements CoachingRepository {
  final FirestoreCoachingSource _source;

  CoachingRepositoryImpl(this._source);

  @override
  Future<List<CoachClientRelation>> getRelationsForCoach({
    required String coachId,
  }) {
    return _source.getRelationsForCoach(coachId: coachId);
  }

  @override
  Future<List<CoachClientRelation>> getRelationsForClient({
    required String clientId,
  }) {
    return _source.getRelationsForClient(clientId: clientId);
  }

  @override
  Future<void> requestCoaching({
    required String gymId,
    required String coachId,
    required String clientId,
  }) {
    return _source.requestCoaching(
      gymId: gymId,
      coachId: coachId,
      clientId: clientId,
    );
  }

  @override
  Future<void> updateRelationStatus({
    required String relationId,
    required String status,
    String? endedReason,
  }) {
    return _source.updateRelationStatus(
      relationId: relationId,
      status: status,
      endedReason: endedReason,
    );
  }
}

