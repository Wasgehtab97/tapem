// lib/features/device/providers/device_riverpod.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  return DeviceRepositoryImpl(
    FirestoreDeviceSource(firestore: FirebaseFirestore.instance),
  );
});

final getDevicesForGymProvider = Provider<GetDevicesForGym>((ref) {
  return GetDevicesForGym(ref.read(deviceRepositoryProvider));
});

final getDeviceByNfcCodeProvider = Provider<GetDeviceByNfcCode>((ref) {
  return GetDeviceByNfcCode(ref.read(deviceRepositoryProvider));
});

final deleteDeviceUseCaseProvider = Provider<DeleteDeviceUseCase>((ref) {
  return DeleteDeviceUseCase(ref.read(deviceRepositoryProvider));
});

final createDeviceUseCaseProvider = Provider<CreateDeviceUseCase>((ref) {
  return CreateDeviceUseCase(ref.read(deviceRepositoryProvider));
});

final setDeviceMuscleGroupsUseCaseProvider =
    Provider<SetDeviceMuscleGroupsUseCase>((ref) {
  return SetDeviceMuscleGroupsUseCase(ref.read(deviceRepositoryProvider));
});

final updateDeviceMuscleGroupsUseCaseProvider =
    Provider<UpdateDeviceMuscleGroupsUseCase>((ref) {
  return UpdateDeviceMuscleGroupsUseCase(ref.read(deviceRepositoryProvider));
});

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepositoryImpl(
    FirestoreExerciseSource(firestore: FirebaseFirestore.instance),
  );
});

final getExercisesForDeviceProvider = Provider<GetExercisesForDevice>((ref) {
  return GetExercisesForDevice(ref.read(exerciseRepositoryProvider));
});

final createExerciseUseCaseProvider = Provider<CreateExerciseUseCase>((ref) {
  return CreateExerciseUseCase(ref.read(exerciseRepositoryProvider));
});

final deleteExerciseUseCaseProvider = Provider<DeleteExerciseUseCase>((ref) {
  return DeleteExerciseUseCase(ref.read(exerciseRepositoryProvider));
});

final updateExerciseUseCaseProvider = Provider<UpdateExerciseUseCase>((ref) {
  return UpdateExerciseUseCase(ref.read(exerciseRepositoryProvider));
});

final updateExerciseMuscleGroupsUseCaseProvider =
    Provider<UpdateExerciseMuscleGroupsUseCase>((ref) {
  return UpdateExerciseMuscleGroupsUseCase(
    ref.read(exerciseRepositoryProvider),
  );
});

final exerciseXpReassignmentServiceProvider =
    Provider<ExerciseXpReassignmentService>((ref) {
  return ExerciseXpReassignmentService(
    firestore: FirebaseFirestore.instance,
  );
});
