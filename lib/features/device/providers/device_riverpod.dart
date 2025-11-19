// lib/features/device/providers/device_riverpod.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_provider.dart';
import '../data/repositories/device_repository_impl.dart';
import '../data/repositories/exercise_repository_impl.dart';
import '../data/sources/firestore_device_source.dart';
import '../data/sources/firestore_exercise_source.dart';
import '../domain/repositories/device_repository.dart';
import '../domain/repositories/exercise_repository.dart';
import '../domain/services/exercise_xp_reassignment_service.dart';
import '../domain/usecases/create_device_usecase.dart';
import '../domain/usecases/create_exercise_usecase.dart';
import '../domain/usecases/delete_device_usecase.dart';
import '../domain/usecases/delete_exercise_usecase.dart';
import '../domain/usecases/get_device_by_nfc_code.dart';
import '../domain/usecases/get_devices_for_gym.dart';
import '../domain/usecases/get_exercises_for_device.dart';
import '../domain/usecases/set_device_muscle_groups_usecase.dart';
import '../domain/usecases/update_device_muscle_groups_usecase.dart';
import '../domain/usecases/update_exercise_muscle_groups_usecase.dart';
import '../domain/usecases/update_exercise_usecase.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return DeviceRepositoryImpl(
    FirestoreDeviceSource(firestore: firestore),
  );
});

final getDevicesForGymProvider = Provider<GetDevicesForGym>((ref) {
  return GetDevicesForGym(ref.watch(deviceRepositoryProvider));
});

final getDeviceByNfcCodeProvider = Provider<GetDeviceByNfcCode>((ref) {
  return GetDeviceByNfcCode(ref.watch(deviceRepositoryProvider));
});

final deleteDeviceUseCaseProvider = Provider<DeleteDeviceUseCase>((ref) {
  return DeleteDeviceUseCase(ref.watch(deviceRepositoryProvider));
});

final createDeviceUseCaseProvider = Provider<CreateDeviceUseCase>((ref) {
  return CreateDeviceUseCase(ref.watch(deviceRepositoryProvider));
});

final setDeviceMuscleGroupsUseCaseProvider =
    Provider<SetDeviceMuscleGroupsUseCase>((ref) {
  return SetDeviceMuscleGroupsUseCase(ref.watch(deviceRepositoryProvider));
});

final updateDeviceMuscleGroupsUseCaseProvider =
    Provider<UpdateDeviceMuscleGroupsUseCase>((ref) {
  return UpdateDeviceMuscleGroupsUseCase(ref.watch(deviceRepositoryProvider));
});

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return ExerciseRepositoryImpl(
    FirestoreExerciseSource(firestore: firestore),
  );
});

final getExercisesForDeviceProvider = Provider<GetExercisesForDevice>((ref) {
  return GetExercisesForDevice(ref.watch(exerciseRepositoryProvider));
});

final createExerciseUseCaseProvider = Provider<CreateExerciseUseCase>((ref) {
  return CreateExerciseUseCase(ref.watch(exerciseRepositoryProvider));
});

final deleteExerciseUseCaseProvider = Provider<DeleteExerciseUseCase>((ref) {
  return DeleteExerciseUseCase(ref.watch(exerciseRepositoryProvider));
});

final updateExerciseUseCaseProvider = Provider<UpdateExerciseUseCase>((ref) {
  return UpdateExerciseUseCase(ref.watch(exerciseRepositoryProvider));
});

final updateExerciseMuscleGroupsUseCaseProvider =
    Provider<UpdateExerciseMuscleGroupsUseCase>((ref) {
  return UpdateExerciseMuscleGroupsUseCase(
    ref.watch(exerciseRepositoryProvider),
  );
});

final exerciseXpReassignmentServiceProvider =
    Provider<ExerciseXpReassignmentService>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return ExerciseXpReassignmentService(
    firestore: firestore,
  );
});
