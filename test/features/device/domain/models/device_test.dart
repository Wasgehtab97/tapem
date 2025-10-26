import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/device/domain/models/device.dart';

void main() {
  group('Device', () {
    test('toJson serializes all core fields', () {
      final device = Device(
        uid: 'd1',
        id: 42,
        name: 'Leg Press',
        description: 'Test device',
        nfcCode: 'ABC123',
        isMulti: true,
        muscleGroupIds: const ['legs', 'core'],
        primaryMuscleGroups: const ['legs'],
        secondaryMuscleGroups: const ['core'],
        muscleGroups: const ['legs', 'core'],
      );

      expect(device.toJson(), {
        'id': 42,
        'name': 'Leg Press',
        'description': 'Test device',
        'nfcCode': 'ABC123',
        'isMulti': true,
        'muscleGroupIds': const ['legs', 'core'],
        'muscleGroups': const ['legs', 'core'],
        'primaryMuscleGroups': const ['legs'],
        'secondaryMuscleGroups': const ['core'],
      });
    });

    test('fromJson falls back to combined muscle groups when missing', () {
      final json = {
        'uid': 'd2',
        'id': 1,
        'name': 'Chest Fly',
        'primaryMuscleGroups': const ['chest'],
        'secondaryMuscleGroups': const ['shoulders'],
      };

      final device = Device.fromJson(json);

      expect(device.uid, 'd2');
      expect(device.muscleGroups, ['chest', 'shoulders']);
      expect(device.muscleGroupIds, isEmpty);
      expect(device.primaryMuscleGroups, ['chest']);
      expect(device.secondaryMuscleGroups, ['shoulders']);
    });

    test('copyWith overrides selected fields and keeps defaults', () {
      final device = Device(
        uid: 'base',
        id: 10,
        name: 'Row',
        description: 'Base',
        isMulti: false,
        muscleGroupIds: const ['back'],
        primaryMuscleGroups: const ['back'],
        secondaryMuscleGroups: const [],
      );

      final updated = device.copyWith(
        name: 'Row Machine',
        description: 'Updated',
        isMulti: true,
        muscleGroupIds: const ['back', 'biceps'],
        secondaryMuscleGroups: const ['biceps'],
      );

      expect(updated.name, 'Row Machine');
      expect(updated.description, 'Updated');
      expect(updated.isMulti, isTrue);
      expect(updated.muscleGroupIds, ['back', 'biceps']);
      expect(updated.primaryMuscleGroups, ['back']);
      expect(updated.secondaryMuscleGroups, ['biceps']);
      expect(updated.muscleGroups, ['back', 'biceps']);
    });
  });
}
