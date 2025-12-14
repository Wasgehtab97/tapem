import 'package:tapem/features/coaching/domain/models/coach_client_relation.dart';

abstract class CoachingRepository {
  Future<List<CoachClientRelation>> getRelationsForCoach({
    required String coachId,
  });

  Future<List<CoachClientRelation>> getRelationsForClient({
    required String clientId,
  });

  Future<void> requestCoaching({
    required String gymId,
    required String coachId,
    required String clientId,
  });

  Future<void> updateRelationStatus({
    required String relationId,
    required String status,
    String? endedReason,
  });
}

