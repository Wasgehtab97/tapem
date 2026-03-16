import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';
import 'package:tapem/features/training_plan/application/create_training_plan_from_day_usecase.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan_stats.dart';
import 'package:tapem/features/training_plan/domain/repositories/training_plan_repository.dart';

class _FakeTrainingPlanRepository implements TrainingPlanRepository {
  String? savedUserId;
  TrainingPlan? savedPlan;

  @override
  Future<void> savePlan({
    required String userId,
    required TrainingPlan plan,
  }) async {
    savedUserId = userId;
    savedPlan = plan;
  }

  @override
  Future<void> deletePlan({required String userId, required String planId}) {
    throw UnimplementedError();
  }

  @override
  Future<List<TrainingPlan>> getPlans({
    required String gymId,
    required String userId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TrainingPlanStats> getStats({
    required String userId,
    required String planId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> incrementCompletion({
    required String userId,
    required String planId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateDefaultSetCount({
    required String userId,
    required String planId,
    required int defaultSetCount,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> reorderPlans({
    required String userId,
    required List<String> orderedPlanIds,
  }) {
    throw UnimplementedError();
  }
}

Session _session({
  required String sessionId,
  required String deviceId,
  String? exerciseId,
  String? exerciseName,
  required String deviceName,
}) {
  return Session(
    sessionId: sessionId,
    gymId: 'gym-1',
    userId: 'user-1',
    deviceId: deviceId,
    deviceName: deviceName,
    exerciseId: exerciseId,
    exerciseName: exerciseName,
    timestamp: DateTime(2026, 3, 14, 10, 0, 0),
    note: '',
    sets: const <SessionSet>[],
  );
}

void main() {
  test(
    'creates plan with ordered and deduplicated exercises from sessions',
    () async {
      final repo = _FakeTrainingPlanRepository();
      final useCase = CreateTrainingPlanFromDayUseCase(repository: repo);

      final result = await useCase.execute(
        userId: 'user-1',
        gymId: 'gym-1',
        planName: 'Pull Day',
        sessions: <Session>[
          _session(
            sessionId: 's1',
            deviceId: 'device-a',
            exerciseId: 'ex-1',
            exerciseName: 'Lat Pulldown',
            deviceName: 'Nautilus',
          ),
          _session(
            sessionId: 's2',
            deviceId: 'device-b',
            exerciseId: 'ex-2',
            exerciseName: 'Row',
            deviceName: 'Cybex',
          ),
          _session(
            sessionId: 's3',
            deviceId: 'device-a',
            exerciseId: 'ex-1',
            exerciseName: 'Lat Pulldown',
            deviceName: 'Nautilus',
          ),
        ],
      );

      expect(repo.savedUserId, 'user-1');
      expect(repo.savedPlan, isNotNull);
      expect(repo.savedPlan!.gymId, 'gym-1');
      expect(repo.savedPlan!.name, 'Pull Day');
      expect(repo.savedPlan!.exercises.length, 2);
      expect(repo.savedPlan!.exercises[0].deviceId, 'device-a');
      expect(repo.savedPlan!.exercises[0].exerciseId, 'ex-1');
      expect(repo.savedPlan!.exercises[0].orderIndex, 0);
      expect(repo.savedPlan!.exercises[1].deviceId, 'device-b');
      expect(repo.savedPlan!.exercises[1].exerciseId, 'ex-2');
      expect(repo.savedPlan!.exercises[1].orderIndex, 1);
      expect(result.duplicatesRemoved, 1);
      expect(result.invalidSessionsSkipped, 0);
    },
  );

  test(
    'falls back to deviceId and deviceName when exercise fields are missing',
    () async {
      final repo = _FakeTrainingPlanRepository();
      final useCase = CreateTrainingPlanFromDayUseCase(repository: repo);

      await useCase.execute(
        userId: 'user-1',
        gymId: 'gym-1',
        planName: 'Fallback Day',
        sessions: <Session>[
          _session(
            sessionId: 's1',
            deviceId: 'device-a',
            exerciseId: null,
            exerciseName: null,
            deviceName: 'Chest Press',
          ),
        ],
      );

      final saved = repo.savedPlan!;
      expect(saved.exercises.single.exerciseId, 'device-a');
      expect(saved.exercises.single.name, 'Chest Press');
    },
  );

  test('throws invalidPlanName when name is empty', () async {
    final repo = _FakeTrainingPlanRepository();
    final useCase = CreateTrainingPlanFromDayUseCase(repository: repo);

    expect(
      () => useCase.execute(
        userId: 'user-1',
        gymId: 'gym-1',
        planName: '   ',
        sessions: <Session>[],
      ),
      throwsA(
        isA<CreateTrainingPlanFromDayException>().having(
          (error) => error.code,
          'code',
          CreateTrainingPlanFromDayErrorCode.invalidPlanName,
        ),
      ),
    );
  });

  test('throws invalidPlanName when name exceeds max length', () async {
    final repo = _FakeTrainingPlanRepository();
    final useCase = CreateTrainingPlanFromDayUseCase(repository: repo);
    final tooLongName = 'x' * 61;

    expect(
      () => useCase.execute(
        userId: 'user-1',
        gymId: 'gym-1',
        planName: tooLongName,
        sessions: <Session>[],
      ),
      throwsA(
        isA<CreateTrainingPlanFromDayException>().having(
          (error) => error.code,
          'code',
          CreateTrainingPlanFromDayErrorCode.invalidPlanName,
        ),
      ),
    );
  });

  test('throws missingUserContext when userId is empty', () async {
    final repo = _FakeTrainingPlanRepository();
    final useCase = CreateTrainingPlanFromDayUseCase(repository: repo);

    expect(
      () => useCase.execute(
        userId: ' ',
        gymId: 'gym-1',
        planName: 'Plan Name',
        sessions: <Session>[],
      ),
      throwsA(
        isA<CreateTrainingPlanFromDayException>().having(
          (error) => error.code,
          'code',
          CreateTrainingPlanFromDayErrorCode.missingUserContext,
        ),
      ),
    );
  });

  test('throws missingGymContext when gymId is empty', () async {
    final repo = _FakeTrainingPlanRepository();
    final useCase = CreateTrainingPlanFromDayUseCase(repository: repo);

    expect(
      () => useCase.execute(
        userId: 'user-1',
        gymId: '',
        planName: 'Plan Name',
        sessions: <Session>[],
      ),
      throwsA(
        isA<CreateTrainingPlanFromDayException>().having(
          (error) => error.code,
          'code',
          CreateTrainingPlanFromDayErrorCode.missingGymContext,
        ),
      ),
    );
  });

  test('throws noExercisesFound when all sessions are invalid', () async {
    final repo = _FakeTrainingPlanRepository();
    final useCase = CreateTrainingPlanFromDayUseCase(repository: repo);

    expect(
      () => useCase.execute(
        userId: 'user-1',
        gymId: 'gym-1',
        planName: 'Invalid Day',
        sessions: <Session>[
          _session(
            sessionId: 's1',
            deviceId: '',
            exerciseId: '',
            exerciseName: '',
            deviceName: '',
          ),
        ],
      ),
      throwsA(
        isA<CreateTrainingPlanFromDayException>().having(
          (error) => error.code,
          'code',
          CreateTrainingPlanFromDayErrorCode.noExercisesFound,
        ),
      ),
    );
  });
}
