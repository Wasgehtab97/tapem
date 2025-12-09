import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan.dart';
import 'package:tapem/features/training_plan/data/sources/firestore_training_plan_source.dart';
import 'package:tapem/features/training_plan/data/repositories/training_plan_repository_impl.dart';
import 'package:tapem/features/training_plan/domain/repositories/training_plan_repository.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan_stats.dart';

final trainingPlanRepositoryProvider = Provider<TrainingPlanRepository>((ref) {
  return TrainingPlanRepositoryImpl(
    FirestoreTrainingPlanSource(FirebaseFirestore.instance),
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
