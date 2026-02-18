import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/providers/firebase_provider.dart';
import 'package:tapem/features/device/data/local/workout_context_cache_store.dart';
import 'package:tapem/features/device/data/repositories/workout_data_repository_impl.dart';
import 'package:tapem/features/device/data/sources/firestore_workout_context_source.dart';
import 'package:tapem/features/device/domain/repositories/workout_data_repository.dart';
import 'package:tapem/features/training_details/providers/session_repository_provider.dart';

final workoutDataRepositoryProvider = Provider<WorkoutDataRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final sessionRepository = ref.watch(sessionRepositoryProvider);
  return WorkoutDataRepositoryImpl(
    sessionRepository: sessionRepository,
    remoteSource: FirestoreWorkoutContextSource(firestore: firestore),
    cacheStore: const WorkoutContextCacheStore(),
  );
});
