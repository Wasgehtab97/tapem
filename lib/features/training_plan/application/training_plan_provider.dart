import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan.dart';
import 'package:tapem/features/training_plan/data/sources/firestore_training_plan_source.dart';
import 'package:tapem/features/training_plan/data/repositories/training_plan_repository_impl.dart';
import 'package:tapem/features/training_plan/domain/repositories/training_plan_repository.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan_stats.dart';
import 'package:tapem/features/training_plan/domain/models/training_day_assignment.dart';
import 'package:tapem/features/training_plan/domain/repositories/training_schedule_repository.dart';
import 'package:tapem/features/training_plan/data/sources/firestore_training_schedule_source.dart';
import 'package:tapem/features/training_plan/data/repositories/training_schedule_repository_impl.dart';

class ClientPlanStatsKey {
  const ClientPlanStatsKey({
    required this.clientId,
    required this.planId,
  });

  final String clientId;
  final String planId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClientPlanStatsKey &&
        other.clientId == clientId &&
        other.planId == planId;
  }

  @override
  int get hashCode => Object.hash(clientId, planId);
}

class PlanStatsOwnerKey {
  const PlanStatsOwnerKey({
    required this.userId,
    required this.planId,
  });

  final String userId;
  final String planId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlanStatsOwnerKey &&
        other.userId == userId &&
        other.planId == planId;
  }

  @override
  int get hashCode => Object.hash(userId, planId);
}

final trainingPlanRepositoryProvider = Provider<TrainingPlanRepository>((ref) {
  return TrainingPlanRepositoryImpl(
    FirestoreTrainingPlanSource(FirebaseFirestore.instance),
  );
});

final trainingScheduleRepositoryProvider =
    Provider<TrainingScheduleRepository>((ref) {
  return TrainingScheduleRepositoryImpl(
    FirestoreTrainingScheduleSource(FirebaseFirestore.instance),
  );
});

final trainingPlansProvider = FutureProvider<List<TrainingPlan>>((ref) async {
  final authState = ref.watch(authViewStateProvider);
  final gymId = authState.gymCode;
  final userId = authState.userId;

  if (userId == null || gymId == null) {
    return [];
  }

  final repository = ref.watch(trainingPlanRepositoryProvider);
  try {
    return await repository.getPlans(gymId: gymId, userId: userId);
  } catch (e) {
    //ignore: avoid_print
    print('🔴 Error loading training plans: $e');
    rethrow;
  }
});

final trainingPlanStatsProvider =
    FutureProvider.family<TrainingPlanStats, String>((ref, planId) async {
  final authState = ref.watch(authViewStateProvider);
  final userId = authState.userId;
  if (userId == null) {
    return TrainingPlanStats.empty();
  }
  final repo = ref.watch(trainingPlanRepositoryProvider);
  try {
    return await repo.getStats(userId: userId, planId: planId);
  } catch (_) {
    return TrainingPlanStats.empty();
  }
});

/// Stats für einen Plan, explizit für einen Owner-User (z.B. Client).
final trainingPlanStatsForOwnerProvider =
    FutureProvider.family<TrainingPlanStats, PlanStatsOwnerKey>((ref, key) async {
  final repo = ref.watch(trainingPlanRepositoryProvider);
  try {
    return await repo.getStats(userId: key.userId, planId: key.planId);
  } catch (_) {
    return TrainingPlanStats.empty();
  }
});

/// Stats-Provider für einen bestimmten Client-Plan (Coach-Views).
final clientTrainingPlanStatsProvider =
    FutureProvider.family<TrainingPlanStats, ClientPlanStatsKey>((ref, key) async {
  final repo = ref.watch(trainingPlanRepositoryProvider);
  try {
    return await repo.getStats(userId: key.clientId, planId: key.planId);
  } catch (_) {
    return TrainingPlanStats.empty();
  }
});

/// Lädt Trainingspläne eines bestimmten Clients (für Coach-Views).
final clientTrainingPlansProvider =
    FutureProvider.family<List<TrainingPlan>, String>((ref, String clientId) async {
  final authState = ref.watch(authViewStateProvider);
  final gymId = authState.gymCode;

  if (gymId == null || gymId.isEmpty) {
    return [];
  }

  final repository = ref.watch(trainingPlanRepositoryProvider);
  try {
    return await repository.getPlans(gymId: gymId, userId: clientId);
  } catch (e) {
    //ignore: avoid_print
    print('🔴 Error loading client training plans: $e');
    rethrow;
  }
});

/// Lädt Plan-Zuweisung für einen Trainingstag (Owner = aktueller User).
final trainingScheduleForDayProvider =
    FutureProvider.family<TrainingDayAssignment?, String>((ref, String dateKey) async {
  final authState = ref.watch(authViewStateProvider);
  final userId = authState.userId;
  if (userId == null) {
    return null;
  }
  final repo = ref.watch(trainingScheduleRepositoryProvider);
  try {
    return await repo.getAssignment(userId: userId, dateKey: dateKey);
  } catch (e) {
    //ignore: avoid_print
    print('🔴 Error loading training schedule for $dateKey: $e');
    return null;
  }
});

/// Lädt Plan-Zuweisung für einen Trainingstag eines Clients (Coach-View).
final clientTrainingScheduleForDayProvider =
    FutureProvider.family<TrainingDayAssignment?, Map<String, String>>(
  (ref, Map<String, String> params) async {
    final clientId = params['clientId'] ?? '';
    final dateKey = params['dateKey'] ?? '';
    if (clientId.isEmpty || dateKey.isEmpty) {
      return null;
    }
    final repo = ref.watch(trainingScheduleRepositoryProvider);
    try {
      return await repo.getAssignment(userId: clientId, dateKey: dateKey);
    } catch (e) {
      //ignore: avoid_print
      print(
        '🔴 Error loading client training schedule clientId=$clientId dateKey=$dateKey: $e',
      );
      return null;
    }
  },
);

/// Alle Plan-Zuweisungen eines Jahres (Owner = aktueller User).
final trainingScheduleForYearProvider =
    FutureProvider.family<List<TrainingDayAssignment>, int>((ref, int year) async {
  final authState = ref.watch(authViewStateProvider);
  final userId = authState.userId;
  if (userId == null) {
    return [];
  }
  final repo = ref.watch(trainingScheduleRepositoryProvider);
  try {
    return await repo.getAssignmentsForYear(userId: userId, year: year);
  } catch (e) {
    //ignore: avoid_print
    print('🔴 Error loading training schedule for year=$year: $e');
    return [];
  }
});
