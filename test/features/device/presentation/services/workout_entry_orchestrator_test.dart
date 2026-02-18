import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/device/presentation/services/workout_entry_orchestrator.dart';

void main() {
  test('duplicate guard ignores identical event within window', () {
    var now = DateTime(2026, 2, 13, 12, 0, 0);
    final orchestrator = WorkoutEntryOrchestrator(
      duplicateWindow: const Duration(milliseconds: 1200),
      now: () => now,
    );

    final firstIgnored = orchestrator.shouldIgnoreDuplicate(
      gymId: 'gym-1',
      deviceId: 'device-1',
      exerciseId: 'exercise-1',
      userId: 'user-1',
    );
    final secondIgnored = orchestrator.shouldIgnoreDuplicate(
      gymId: 'gym-1',
      deviceId: 'device-1',
      exerciseId: 'exercise-1',
      userId: 'user-1',
    );

    expect(firstIgnored, isFalse);
    expect(secondIgnored, isTrue);
  });

  test('duplicate guard allows different event keys', () {
    final orchestrator = WorkoutEntryOrchestrator(
      duplicateWindow: const Duration(milliseconds: 1200),
    );

    final firstIgnored = orchestrator.shouldIgnoreDuplicate(
      gymId: 'gym-1',
      deviceId: 'device-1',
      exerciseId: 'exercise-1',
      userId: 'user-1',
    );
    final secondIgnored = orchestrator.shouldIgnoreDuplicate(
      gymId: 'gym-1',
      deviceId: 'device-1',
      exerciseId: 'exercise-2',
      userId: 'user-1',
    );

    expect(firstIgnored, isFalse);
    expect(secondIgnored, isFalse);
  });

  test('duplicate guard expires after debounce window', () {
    var now = DateTime(2026, 2, 13, 12, 0, 0);
    final orchestrator = WorkoutEntryOrchestrator(
      duplicateWindow: const Duration(milliseconds: 1200),
      now: () => now,
    );

    final firstIgnored = orchestrator.shouldIgnoreDuplicate(
      gymId: 'gym-1',
      deviceId: 'device-1',
      exerciseId: 'exercise-1',
      userId: 'user-1',
    );
    now = now.add(const Duration(milliseconds: 1300));
    final secondIgnored = orchestrator.shouldIgnoreDuplicate(
      gymId: 'gym-1',
      deviceId: 'device-1',
      exerciseId: 'exercise-1',
      userId: 'user-1',
    );

    expect(firstIgnored, isFalse);
    expect(secondIgnored, isFalse);
  });
}
