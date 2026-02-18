import 'package:flutter/foundation.dart';
import 'package:tapem/core/services/workout_session_coordinator.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';

enum WorkoutEntryApplyStatus { applied, ignoredDuplicate }

class WorkoutEntryApplyResult {
  const WorkoutEntryApplyResult({required this.status, required this.session});

  final WorkoutEntryApplyStatus status;
  final WorkoutDaySession? session;

  bool get isDuplicate => status == WorkoutEntryApplyStatus.ignoredDuplicate;
}

/// Central orchestration for adding/focusing workout sessions from
/// external event sources (Gym list, NFC button, global NFC listener).
///
/// Includes a short duplicate-event guard to avoid rapid double creation
/// attempts when multiple scanners/listeners emit the same selection.
class WorkoutEntryOrchestrator {
  WorkoutEntryOrchestrator({
    Duration duplicateWindow = const Duration(milliseconds: 1200),
    DateTime Function()? now,
  }) : _duplicateWindow = duplicateWindow,
       _now = now ?? DateTime.now;

  final Duration _duplicateWindow;
  final DateTime Function() _now;
  final Map<String, int> _recentEventMs = <String, int>{};

  WorkoutEntryApplyResult _duplicateResult({
    required WorkoutDayController controller,
    required String gymId,
    required String deviceId,
    required String exerciseId,
    required String userId,
  }) {
    final key = WorkoutDayController.contextKey(
      gymId: gymId,
      deviceId: deviceId,
      exerciseId: exerciseId,
      userId: userId,
    );
    return WorkoutEntryApplyResult(
      status: WorkoutEntryApplyStatus.ignoredDuplicate,
      session: controller.sessionForKey(key),
    );
  }

  String _eventKey({
    required String gymId,
    required String deviceId,
    required String exerciseId,
    required String userId,
  }) => '$gymId|$deviceId|$exerciseId|$userId';

  void _pruneOldEvents(int nowMs) {
    if (_recentEventMs.isEmpty) return;
    final threshold = nowMs - _duplicateWindow.inMilliseconds;
    _recentEventMs.removeWhere((_, ts) => ts < threshold);
  }

  bool shouldIgnoreDuplicate({
    required String gymId,
    required String deviceId,
    required String exerciseId,
    required String userId,
  }) {
    final nowMs = _now().millisecondsSinceEpoch;
    _pruneOldEvents(nowMs);
    final eventKey = _eventKey(
      gymId: gymId,
      deviceId: deviceId,
      exerciseId: exerciseId,
      userId: userId,
    );
    final previous = _recentEventMs[eventKey];
    if (previous != null &&
        nowMs - previous <= _duplicateWindow.inMilliseconds) {
      return true;
    }
    _recentEventMs[eventKey] = nowMs;
    return false;
  }

  Future<WorkoutEntryApplyResult> addOrFocusFromExternalSource({
    required WorkoutDayController controller,
    required WorkoutSessionCoordinator coordinator,
    required String gymId,
    required String deviceId,
    required String exerciseId,
    required String userId,
    String? exerciseName,
  }) async {
    if (shouldIgnoreDuplicate(
      gymId: gymId,
      deviceId: deviceId,
      exerciseId: exerciseId,
      userId: userId,
    )) {
      final eventKey = _eventKey(
        gymId: gymId,
        deviceId: deviceId,
        exerciseId: exerciseId,
        userId: userId,
      );
      debugPrint(
        '⚠️ [WorkoutEntryOrchestrator] duplicate event ignored: $eventKey',
      );
      return _duplicateResult(
        controller: controller,
        gymId: gymId,
        deviceId: deviceId,
        exerciseId: exerciseId,
        userId: userId,
      );
    }
    final session = controller.addOrFocusSession(
      gymId: gymId,
      deviceId: deviceId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      userId: userId,
    );
    await coordinator.onExerciseAddedFromGymOrNfc(uid: userId, gymId: gymId);
    return WorkoutEntryApplyResult(
      status: WorkoutEntryApplyStatus.applied,
      session: session,
    );
  }
}
