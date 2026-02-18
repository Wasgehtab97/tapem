import 'dart:collection';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:tapem/core/drafts/session_draft_repository.dart';
import 'package:tapem/core/drafts/session_draft_repository_impl.dart';
import 'package:tapem/core/providers/challenge_provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/providers/gym_scoped_resettable.dart';
import 'package:tapem/core/providers/xp_provider.dart';
import 'package:tapem/core/services/workout_session_coordinator.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';
import 'package:tapem/core/sync/sync_service.dart';
import 'package:tapem/features/community/data/community_stats_writer.dart';
import 'package:tapem/features/device/data/repositories/device_repository_impl.dart';
import 'package:tapem/features/device/data/repositories/workout_data_repository_impl.dart';
import 'package:tapem/features/device/data/sources/firestore_device_source.dart';
import 'package:tapem/features/device/data/sources/firestore_workout_context_source.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';
import 'package:tapem/features/device/domain/repositories/workout_data_repository.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:tapem/features/training_details/domain/repositories/session_repository.dart';
import 'package:tapem/core/time/logic_day.dart';
import 'package:tapem/services/membership_service.dart';

const bool _enableVerboseWorkoutDayControllerLogs = false;

void _workoutFlowLog(String message) {
  debugPrint('🏁 [WorkoutFlow] $message');
}

void _workoutDayVerboseLog(String message) {
  if (!_enableVerboseWorkoutDayControllerLogs) return;
  debugPrint(message);
}

void _workoutDayVerboseStack(String label) {
  if (!_enableVerboseWorkoutDayControllerLogs) return;
  debugPrintStack(label: label);
}

@immutable
class WorkoutDaySession {
  const WorkoutDaySession({
    required this.key,
    required this.gymId,
    required this.deviceId,
    required this.exerciseId,
    this.exerciseName,
    required this.userId,
    required this.provider,
    required this.canSave,
    required this.isSaving,
    required this.isLoading,
    required this.hasSessionToday,
    required this.error,
  });

  final String key;
  final String gymId;
  final String deviceId;
  final String exerciseId;
  final String? exerciseName;
  final String userId;
  final DeviceProvider provider;
  final bool canSave;
  final bool isSaving;
  final bool isLoading;
  final bool hasSessionToday;
  final String? error;

  bool get canShowSaveAction => canSave && !hasSessionToday && !isSaving;

  bool get hasValidationWarning => hasSessionToday || error != null;

  WorkoutDaySession copyWith({String? exerciseName}) {
    return WorkoutDaySession(
      key: key,
      gymId: gymId,
      deviceId: deviceId,
      exerciseId: exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      userId: userId,
      provider: provider,
      canSave: canSave,
      isSaving: isSaving,
      isLoading: isLoading,
      hasSessionToday: hasSessionToday,
      error: error,
    );
  }

  @override
  int get hashCode => Object.hash(
    key,
    gymId,
    deviceId,
    exerciseId,
    exerciseName,
    userId,
    provider,
    canSave,
    isSaving,
    isLoading,
    hasSessionToday,
    error,
  );

  @override
  bool operator ==(Object other) {
    return other is WorkoutDaySession &&
        other.key == key &&
        other.gymId == gymId &&
        other.deviceId == deviceId &&
        other.exerciseId == exerciseId &&
        other.exerciseName == exerciseName &&
        other.userId == userId &&
        identical(other.provider, provider) &&
        other.canSave == canSave &&
        other.isSaving == isSaving &&
        other.isLoading == isLoading &&
        other.hasSessionToday == hasSessionToday &&
        other.error == error;
  }
}

@immutable
class SaveAllSessionsResult {
  const SaveAllSessionsResult({
    required this.attempted,
    required this.saved,
    required this.failedSessions,
    this.savedSessionKeys = const <String>[],
  });

  final int attempted;
  final int saved;
  final Map<String, String?> failedSessions;
  final List<String> savedSessionKeys;

  bool get hasFailures => failedSessions.isNotEmpty;
}

class WorkoutDayController extends ChangeNotifier
    with GymScopedResettableChangeNotifier {
  WorkoutDayController({
    required FirebaseFirestore firestore,
    required MembershipService membership,
    required SessionRepository sessionRepository,
    SyncService? syncService,
    DeviceRepository? deviceRepository,
    WorkoutDataRepository? workoutDataRepository,
    GetDevicesForGym? getDevicesForGym,
    CommunityStatsWriter? communityStatsWriter,
    SessionDraftRepository Function()? createDraftRepository,
  }) : _firestore = firestore,
       _membership = membership,
       _sessionRepository = sessionRepository,
       _syncService = syncService,
       _communityStatsWriter =
           communityStatsWriter ?? CommunityStatsWriter(firestore: firestore),
       _createDraftRepository =
           createDraftRepository ?? (() => SessionDraftRepositoryImpl()) {
    _deviceRepository =
        deviceRepository ??
        DeviceRepositoryImpl(FirestoreDeviceSource(firestore: firestore));
    _workoutDataRepository =
        workoutDataRepository ??
        WorkoutDataRepositoryImpl(
          sessionRepository: sessionRepository,
          remoteSource: FirestoreWorkoutContextSource(firestore: firestore),
        );
    _getDevicesForGym = getDevicesForGym ?? GetDevicesForGym(_deviceRepository);
  }

  final FirebaseFirestore _firestore;
  MembershipService _membership;
  final SessionRepository _sessionRepository;
  final SyncService? _syncService;
  late final DeviceRepository _deviceRepository;
  late final WorkoutDataRepository _workoutDataRepository;
  late final GetDevicesForGym _getDevicesForGym;
  final CommunityStatsWriter _communityStatsWriter;
  final SessionDraftRepository Function() _createDraftRepository;

  XpProvider? _xpProvider;
  ChallengeProvider? _challengeProvider;
  WorkoutSessionDurationService? _sessionDurationService;
  WorkoutSessionCoordinator? _sessionCoordinator;
  final Set<String> _restoredDraftContexts = <String>{};

  final Map<String, _SessionEntry> _sessions = <String, _SessionEntry>{};
  final List<String> _sessionOrder = <String>[];
  String? _activeUserId;
  String? _focusedSessionKey;
  bool _isSavingAll = false;
  static const int _maxParallelSaveWorkers = 3;
  static const Duration _perSessionSaveTimeout = Duration(seconds: 8);

  // Optional Plan-Kontext für den aktuellen Trainingstag eines Users.
  String? _activePlanId;
  String? _activePlanName;
  String? _activePlanGymId;
  String? _activePlanDayKey;

  void setActiveUser(String? userId) {
    if (_activeUserId == userId) {
      return;
    }
    for (final entry in _sessions.values) {
      entry.dispose();
    }
    _sessions.clear();
    _sessionOrder.clear();
    _focusedSessionKey = null;
    _isSavingAll = false;
    _restoredDraftContexts.clear();
    _clearPlanContext();
    _activeUserId = userId;
    notifyListeners();
  }

  void attachExternalServices({
    required XpProvider xpProvider,
    required ChallengeProvider challengeProvider,
    required WorkoutSessionDurationService sessionDurationService,
    required WorkoutSessionCoordinator sessionCoordinator,
  }) {
    _xpProvider = xpProvider;
    _challengeProvider = challengeProvider;
    _sessionDurationService = sessionDurationService;
    _sessionCoordinator = sessionCoordinator;
    for (final entry in _sessions.values) {
      entry.provider.attachExternalServices(
        xpProvider: xpProvider,
        challengeProvider: challengeProvider,
        sessionDurationService: sessionDurationService,
        sessionCoordinator: sessionCoordinator,
      );
    }
  }

  void updateMembership(MembershipService membership) {
    if (!identical(_membership, membership)) {
      _membership = membership;
    }
  }

  @override
  void resetGymScopedState() {
    _workoutDayVerboseLog(
      '⚠️ [WorkoutDayController] resetGymScopedState triggered',
    );
    _workoutDayVerboseStack('resetGymScopedState_stack');
    for (final entry in _sessions.values) {
      entry.dispose();
    }
    _sessions.clear();
    _sessionOrder.clear();
    _focusedSessionKey = null;
    _isSavingAll = false;
    _restoredDraftContexts.clear();
    _clearPlanContext();
    notifyListeners();
  }

  static String contextKey({
    required String gymId,
    required String deviceId,
    required String exerciseId,
    required String userId,
  }) {
    return '$gymId|$deviceId|$exerciseId|$userId';
  }

  WorkoutDaySession addOrFocusSession({
    required String gymId,
    required String deviceId,
    required String exerciseId,
    required String userId,
    String? exerciseName,
    bool autoFinalizeEnabled = false,
  }) {
    final key = contextKey(
      gymId: gymId,
      deviceId: deviceId,
      exerciseId: exerciseId,
      userId: userId,
    );
    final existing = _sessions[key];
    final previousFocus = _focusedSessionKey;
    if (existing != null) {
      if (exerciseName != null &&
          exerciseName.isNotEmpty &&
          existing.updateExerciseName(exerciseName)) {
        notifyListeners();
      }
      _focusedSessionKey = key;
      final changed = existing.refresh();
      if (previousFocus != key || changed) {
        notifyListeners();
      }
      return existing.snapshot;
    }
    final provider = DeviceProvider(
      firestore: _firestore,
      deviceRepository: _deviceRepository,
      sessionRepository: _sessionRepository,
      getDevicesForGym: _getDevicesForGym,
      draftRepo: _createDraftRepository(),
      membership: _membership,
      communityStatsWriter: _communityStatsWriter,
      syncService: _syncService,
      workoutDataRepository: _workoutDataRepository,
      autoFinalizeEnabled: autoFinalizeEnabled,
      persistEmptyDrafts: true,
    );
    final entry = _SessionEntry(
      key: key,
      gymId: gymId,
      deviceId: deviceId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      userId: userId,
      provider: provider,
    );
    _attachServicesToProvider(provider);
    entry.attachListener(_onEntryChanged);
    _sessions[key] = entry;
    _sessionOrder
      ..remove(key)
      ..add(key);
    _focusedSessionKey = key;
    notifyListeners();
    return entry.snapshot;
  }

  /// Stellt alle gespeicherten Draft-Sessions für Nutzer/Gym wieder her,
  /// z.B. nach App-Restart. Idempotent pro user/gym.
  Future<void> restoreDraftSessions({
    required String userId,
    required String gymId,
  }) async {
    if (userId.isEmpty || gymId.isEmpty) return;
    final key = '$gymId|$userId';
    if (_restoredDraftContexts.contains(key)) return;
    _restoredDraftContexts.add(key);

    final draftRepo = _createDraftRepository();
    final drafts = await draftRepo.getAll();
    for (final entry in drafts.entries) {
      final draft = entry.value;
      if (draft.gymId != gymId || draft.userId != userId) continue;

      final deviceId = draft.deviceId;
      final exerciseId = draft.exerciseId ?? deviceId;
      final existingKey = contextKey(
        gymId: gymId,
        deviceId: deviceId,
        exerciseId: exerciseId,
        userId: userId,
      );
      if (_sessions.containsKey(existingKey)) {
        continue;
      }
      final session = addOrFocusSession(
        gymId: gymId,
        deviceId: deviceId,
        exerciseId: exerciseId,
        userId: userId,
        autoFinalizeEnabled: draft.autoFinalizeEnabled,
      );
      final provider = providerForKey(session.key);
      await provider?.loadDevice(
        gymId: gymId,
        deviceId: deviceId,
        exerciseId: exerciseId,
        userId: userId,
      );
    }
  }

  List<WorkoutDaySession> activeSessions() {
    return List.unmodifiable(_sessions.values.map((entry) => entry.snapshot));
  }

  List<WorkoutDaySession> sessionsFor({
    required String userId,
    required String gymId,
  }) {
    if (userId.isEmpty || gymId.isEmpty) {
      return const <WorkoutDaySession>[];
    }
    if (_sessionOrder.isEmpty) {
      final entries = _sessions.values.where(
        (entry) => entry.userId == userId && entry.gymId == gymId,
      );
      return List.unmodifiable(entries.map((entry) => entry.snapshot));
    }
    final orderedKeys = _sessionOrder.where((key) {
      final entry = _sessions[key];
      return entry != null && entry.userId == userId && entry.gymId == gymId;
    });
    final sessions = <WorkoutDaySession>[];
    for (final key in orderedKeys) {
      final entry = _sessions[key];
      if (entry != null) {
        sessions.add(entry.snapshot);
      }
    }
    return List.unmodifiable(sessions);
  }

  WorkoutDaySession? sessionForKey(String key) {
    return _sessions[key]?.snapshot;
  }

  bool get isSaving =>
      _isSavingAll || _sessions.values.any((entry) => entry.snapshot.isSaving);

  bool get canSave {
    if (_isSavingAll) return false;
    for (final entry in _sessions.values) {
      entry.refresh();
      final snapshot = entry.snapshot;
      if (snapshot.canSave && !snapshot.hasSessionToday && !snapshot.isSaving) {
        return true;
      }
    }
    return false;
  }

  DeviceProvider? providerForKey(String key) {
    return _sessions[key]?.provider;
  }

  WorkoutDaySession? get focusedSession {
    final key = _focusedSessionKey;
    if (key == null) return null;
    return _sessions[key]?.snapshot;
  }

  DeviceProvider? get focusedProvider => focusedSession?.provider;

  bool focusSession(String key) {
    if (!_sessions.containsKey(key)) return false;
    if (_focusedSessionKey == key) {
      return false;
    }
    _focusedSessionKey = key;
    notifyListeners();
    return true;
  }

  bool closeSession(String key) {
    _workoutDayVerboseLog(
      '🔍 [WorkoutDayController] closeSession requested for key=$key',
    );
    _workoutDayVerboseStack('closeSession_stack');

    final entry = _sessions.remove(key);
    _sessionOrder.remove(key);
    if (entry == null) {
      _workoutDayVerboseLog(
        '⚠️ [WorkoutDayController] closeSession: session not found for key=$key',
      );
      return false;
    }
    entry.provider.discardDraftForCancellation();
    entry.dispose();
    if (_focusedSessionKey == key) {
      _focusedSessionKey = _sessionOrder.isEmpty ? null : _sessionOrder.last;
    }
    notifyListeners();
    return true;
  }

  WorkoutDaySession? replaceSession({
    required String oldKey,
    required String gymId,
    required String deviceId,
    required String exerciseId,
    required String exerciseName,
    required String userId,
    bool autoFinalizeEnabled = false,
  }) {
    final oldEntry = _sessions[oldKey];
    if (oldEntry == null) return null;

    final newKey = contextKey(
      gymId: gymId,
      deviceId: deviceId,
      exerciseId: exerciseId,
      userId: userId,
    );

    if (newKey == oldKey) {
      if (exerciseName.isNotEmpty &&
          oldEntry.updateExerciseName(exerciseName)) {
        notifyListeners();
      }
      _focusedSessionKey = newKey;
      return oldEntry.snapshot;
    }

    final filtered = _sessionOrder.where((key) {
      final entry = _sessions[key];
      return entry != null && entry.userId == userId && entry.gymId == gymId;
    }).toList();

    final oldIndex = filtered.indexOf(oldKey);
    if (oldIndex == -1) return null;

    filtered.remove(oldKey);
    filtered.remove(newKey);

    _sessions.remove(oldKey);
    _sessionOrder.remove(oldKey);
    oldEntry.provider.discardDraftForCancellation();
    oldEntry.dispose();

    var entry = _sessions[newKey];
    if (entry == null) {
      final provider = DeviceProvider(
        firestore: _firestore,
        deviceRepository: _deviceRepository,
        sessionRepository: _sessionRepository,
        getDevicesForGym: _getDevicesForGym,
        draftRepo: _createDraftRepository(),
        membership: _membership,
        communityStatsWriter: _communityStatsWriter,
        syncService: _syncService,
        workoutDataRepository: _workoutDataRepository,
        autoFinalizeEnabled: autoFinalizeEnabled,
        persistEmptyDrafts: true,
      );
      entry = _SessionEntry(
        key: newKey,
        gymId: gymId,
        deviceId: deviceId,
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        userId: userId,
        provider: provider,
      );
      _attachServicesToProvider(provider);
      entry.attachListener(_onEntryChanged);
      _sessions[newKey] = entry;
    } else if (exerciseName.isNotEmpty) {
      entry.updateExerciseName(exerciseName);
    }

    final insertIndex = oldIndex.clamp(0, filtered.length);
    filtered.insert(insertIndex, newKey);

    final original = List<String>.from(_sessionOrder);
    _sessionOrder.clear();
    var filteredIdx = 0;
    for (final key in original) {
      final existing = _sessions[key];
      final matches =
          existing != null &&
          existing.userId == userId &&
          existing.gymId == gymId;
      if (matches) {
        if (filteredIdx < filtered.length) {
          _sessionOrder.add(filtered[filteredIdx]);
          filteredIdx += 1;
        }
      } else {
        _sessionOrder.add(key);
      }
    }
    while (filteredIdx < filtered.length) {
      _sessionOrder.add(filtered[filteredIdx]);
      filteredIdx += 1;
    }

    _focusedSessionKey = newKey;
    notifyListeners();
    return _sessions[newKey]?.snapshot;
  }

  bool reorderSessions({
    required String userId,
    required String gymId,
    required int oldIndex,
    required int newIndex,
  }) {
    if (oldIndex == newIndex) return false;
    var filtered = _sessionOrder.where((key) {
      final entry = _sessions[key];
      return entry != null && entry.userId == userId && entry.gymId == gymId;
    }).toList();
    if (oldIndex < 0 || oldIndex >= filtered.length) return false;
    if (newIndex < 0) return false;
    if (newIndex > filtered.length) {
      newIndex = filtered.length;
    }

    final moved = filtered.removeAt(oldIndex);
    filtered.insert(newIndex, moved);

    final original = List<String>.from(_sessionOrder);
    _sessionOrder.clear();
    var filteredIdx = 0;
    for (final key in original) {
      final entry = _sessions[key];
      final matches =
          entry != null && entry.userId == userId && entry.gymId == gymId;
      if (matches) {
        if (filteredIdx < filtered.length) {
          _sessionOrder.add(filtered[filteredIdx]);
          filteredIdx += 1;
        }
      } else {
        _sessionOrder.add(key);
      }
    }
    while (filteredIdx < filtered.length) {
      _sessionOrder.add(filtered[filteredIdx]);
      filteredIdx += 1;
    }
    notifyListeners();
    return true;
  }

  bool closeSessionForContext({
    required String gymId,
    required String deviceId,
    required String exerciseId,
    required String userId,
  }) {
    final key = contextKey(
      gymId: gymId,
      deviceId: deviceId,
      exerciseId: exerciseId,
      userId: userId,
    );
    return closeSession(key);
  }

  int closeAllSessionsFor({required String userId, required String gymId}) {
    final keys = <String>[
      for (final entry in _sessions.entries)
        if (entry.value.userId == userId && entry.value.gymId == gymId)
          entry.key,
    ];
    var closed = 0;
    for (final key in keys) {
      if (closeSession(key)) {
        closed += 1;
      }
    }
    return closed;
  }

  Future<SaveAllSessionsResult> saveAllSessions({
    required String userId,
    required String gymId,
    required bool showInLeaderboard,
    String? userName,
    String? gender,
    double? bodyWeightKg,
    Map<String, int?> plannedRestSecondsBySession = const {},
    WorkoutFinalizeReason finalizeReason = WorkoutFinalizeReason.manualSave,
    DateTime? finalizeEndTime,
  }) async {
    if (_isSavingAll) {
      _workoutFlowLog(
        'save_all_skipped reason=already_saving user=$userId gym=$gymId',
      );
      return const SaveAllSessionsResult(
        attempted: 0,
        saved: 0,
        failedSessions: <String, String?>{},
      );
    }

    final entries = List<_SessionEntry>.from(_sessions.values);
    var attempted = 0;
    var saved = 0;
    final failures = <String, String?>{};
    final savedKeys = <String>[];
    final staleKeys = <String>[];
    final saveEntries = <_SessionEntry>[];

    _workoutFlowLog(
      'save_all_begin reason=${finalizeReason.name} user=$userId gym=$gymId requestedEnd=${(finalizeEndTime ?? DateTime.now()).toIso8601String()}',
    );
    _isSavingAll = true;
    notifyListeners();
    try {
      for (final entry in entries) {
        entry.refresh();
        if (entry.userId != userId || entry.gymId != gymId) {
          staleKeys.add(entry.key);
          continue;
        }
        final snapshot = entry.snapshot;
        if (!snapshot.canShowSaveAction) {
          continue;
        }
        saveEntries.add(entry);
      }

      attempted = saveEntries.length;
      _workoutFlowLog(
        'save_all_candidates total=${entries.length} stale=${staleKeys.length} attempted=$attempted',
      );
      if (saveEntries.isNotEmpty) {
        final queue = ListQueue<_SessionEntry>.from(saveEntries);
        final workerCount = math.min(_maxParallelSaveWorkers, queue.length);
        final workers = List<Future<void>>.generate(workerCount, (_) async {
          while (queue.isNotEmpty) {
            final entry = queue.removeFirst();
            final provider = entry.provider;
            var ok = false;
            String? error;
            try {
              ok = await provider
                  .saveWorkoutSession(
                    gymId: entry.gymId,
                    userId: userId,
                    showInLeaderboard: showInLeaderboard,
                    userName: userName,
                    gender: gender,
                    bodyWeightKg: bodyWeightKg,
                    plannedRestSeconds: plannedRestSecondsBySession[entry.key],
                  )
                  .timeout(
                    _perSessionSaveTimeout,
                    onTimeout: () {
                      _workoutFlowLog(
                        'save_session_timeout key=${entry.key} timeoutMs=${_perSessionSaveTimeout.inMilliseconds}',
                      );
                      return false;
                    },
                  );
              error = provider.error;
            } catch (e, st) {
              error = e.toString();
              _workoutFlowLog(
                '[WorkoutDayController] saveWorkoutSession failed for key=${entry.key}: $e',
              );
              debugPrintStack(stackTrace: st);
            }
            if (ok) {
              savedKeys.add(entry.key);
            } else {
              failures[entry.key] = error;
            }
          }
        });
        await Future.wait(workers);
        saved = savedKeys.length;
      }
    } finally {
      _isSavingAll = false;
      notifyListeners();
    }

    if (staleKeys.isNotEmpty) {
      for (final key in staleKeys) {
        closeSession(key);
      }
    }

    final result = SaveAllSessionsResult(
      attempted: attempted,
      saved: saved,
      failedSessions: failures,
      savedSessionKeys: List.unmodifiable(savedKeys),
    );
    _workoutFlowLog(
      'save_all_result attempted=${result.attempted} saved=${result.saved} failed=${result.failedSessions.length}',
    );

    final durationService = _sessionDurationService;
    final sessionCoordinator = _sessionCoordinator;
    if (sessionCoordinator != null) {
      try {
        await sessionCoordinator.setActiveContext(uid: userId, gymId: gymId);
      } catch (_) {
        // Ignore; finalization falls back to best-effort behavior.
      }
    }
    final resolvedFinalizeTime = finalizeEndTime ?? DateTime.now();
    final shouldFinalizeRunningSession =
        durationService != null &&
        (result.attempted > 0 ||
            durationService.isRunning ||
            (sessionCoordinator?.isRunning ?? false));
    _workoutFlowLog(
      'finalize_gate shouldFinalize=$shouldFinalizeRunningSession durationRunning=${durationService?.isRunning ?? false} coordinatorRunning=${sessionCoordinator?.isRunning ?? false}',
    );
    if (shouldFinalizeRunningSession) {
      if (result.saved > 0) {
        _workoutFlowLog(
          'finalize_with_saved_sessions reason=${finalizeReason.name} end=${resolvedFinalizeTime.toIso8601String()}',
        );
        try {
          await durationService.save(endTime: resolvedFinalizeTime);
        } catch (error) {
          _workoutFlowLog('finalize_duration_save_failed error=$error');
          // Ignore timer persistence failures; saving the workout is more important.
        }
        if (sessionCoordinator != null) {
          try {
            if (finalizeReason == WorkoutFinalizeReason.autoInactivity) {
              await sessionCoordinator.finishAutomaticallyAfterInactivity(
                lastSetCompletedAt: resolvedFinalizeTime,
              );
            } else {
              await sessionCoordinator.finishManuallyFromWorkoutSave(
                finalizedAt: resolvedFinalizeTime,
              );
            }
            _workoutFlowLog(
              'finalize_coordinator_done reason=${finalizeReason.name}',
            );
          } catch (error) {
            _workoutFlowLog('finalize_coordinator_failed error=$error');
            // Ignore coordinator persistence failures.
          }
        }
      } else {
        _workoutFlowLog('finalize_no_saved_sessions -> discard');
        if (sessionCoordinator != null) {
          try {
            await sessionCoordinator.finishDiscarded(
              reason: WorkoutFinalizeReason.discardNoSets,
            );
            _workoutFlowLog('finalize_discard_via_coordinator_done');
          } catch (error) {
            _workoutFlowLog(
              'finalize_discard_via_coordinator_failed error=$error',
            );
            // Ignore coordinator persistence failures.
          }
        } else {
          try {
            await durationService.discard();
            _workoutFlowLog('finalize_discard_via_duration_done');
          } catch (error) {
            _workoutFlowLog(
              'finalize_discard_via_duration_failed error=$error',
            );
            // Ignore timer discard failures.
          }
        }
      }
    } else {
      _workoutFlowLog('finalize_skipped reason=no_running_session');
    }

    return result;
  }

  Future<SaveAllSessionsResult> endDay({
    required String userId,
    required String gymId,
    required bool showInLeaderboard,
    String? userName,
    String? gender,
    double? bodyWeightKg,
    Map<String, int?> plannedRestSecondsBySession = const {},
    WorkoutFinalizeReason finalizeReason = WorkoutFinalizeReason.manualSave,
    DateTime? finalizeEndTime,
    DateTime? sessionAnchorStartTime,
    String? sessionAnchorDayKey,
  }) async {
    final result = await saveAllSessions(
      userId: userId,
      gymId: gymId,
      showInLeaderboard: showInLeaderboard,
      userName: userName,
      gender: gender,
      bodyWeightKg: bodyWeightKg,
      plannedRestSecondsBySession: plannedRestSecondsBySession,
      finalizeReason: finalizeReason,
      finalizeEndTime: finalizeEndTime,
    );
    applySavedSessionCleanup(
      result: result,
      userId: userId,
      gymId: gymId,
      sessionAnchorStartTime: sessionAnchorStartTime,
      sessionAnchorDayKey: sessionAnchorDayKey,
    );
    return result;
  }

  void applySavedSessionCleanup({
    required SaveAllSessionsResult result,
    required String userId,
    required String gymId,
    DateTime? sessionAnchorStartTime,
    String? sessionAnchorDayKey,
  }) {
    if (result.saved <= 0) {
      return;
    }

    // End-of-day cleanup: once at least one session is persisted, all open
    // sessions in this user/gym context must be closed to avoid stale
    // workout tabs and reactivation by leftover in-memory sessions.
    final closed = closeAllSessionsFor(userId: userId, gymId: gymId);
    _workoutFlowLog(
      'cleanup_close_all_sessions reason=saved_end_day user=$userId gym=$gymId closed=$closed',
    );

    final normalizedAnchorDayKey = sessionAnchorDayKey?.trim();
    final hasAnchorDay =
        (normalizedAnchorDayKey != null && normalizedAnchorDayKey.isNotEmpty) ||
        sessionAnchorStartTime != null;
    if (!hasAnchorDay) {
      _workoutFlowLog(
        'cleanup_skip_plan_context reason=missing_anchor_day gym=$gymId',
      );
      return;
    }
    clearPlanContextForDay(
      gymId: gymId,
      date: sessionAnchorStartTime,
      dayKey: normalizedAnchorDayKey,
    );
  }

  // --- Plan-Kontext ---------------------------------------------------------

  void _clearPlanContext() {
    _activePlanId = null;
    _activePlanName = null;
    _activePlanGymId = null;
    _activePlanDayKey = null;
  }

  void setPlanContext({
    required String gymId,
    required String planId,
    String? planName,
    DateTime? date,
    String? dayKey,
  }) {
    final resolvedDayKey = _resolvePlanDayKey(date: date, dayKey: dayKey);
    _activePlanId = planId;
    _activePlanName = planName;
    _activePlanGymId = gymId;
    _activePlanDayKey = resolvedDayKey;
  }

  /// Liefert den aktuellen Plan-Kontext für [gymId] und [date], falls vorhanden.
  (String planId, String? planName)? getPlanContext({
    required String gymId,
    DateTime? date,
    String? dayKey,
  }) {
    final resolvedDayKey = _resolvePlanDayKey(date: date, dayKey: dayKey);
    if (_activePlanId == null ||
        _activePlanGymId != gymId ||
        _activePlanDayKey != resolvedDayKey) {
      return null;
    }
    return (_activePlanId!, _activePlanName);
  }

  /// Bricht ein aktives Training für [userId]/[gymId] ab:
  /// alle offenen Sessions werden geschlossen und der Plan-Kontext
  /// für den aktuellen Tag zurückgesetzt.
  void cancelActivePlan({
    required String userId,
    required String gymId,
    DateTime? date,
    String? dayKey,
  }) {
    final entriesToClose = _sessions.values
        .where((e) => e.userId == userId && e.gymId == gymId)
        .toList();
    for (final entry in entriesToClose) {
      // Drafts explizit verwerfen, damit beim Abbruch eines Plans
      // kein alter Zwischenstand in neue Sessions übernommen wird.
      entry.provider.discardDraftForCancellation();
      closeSession(entry.key);
    }
    clearPlanContextForDay(gymId: gymId, date: date, dayKey: dayKey);
  }

  /// Löscht den Plan-Kontext für [gymId] am aktuellen Tag (ohne Sessions zu verändern).
  void clearPlanContextForDay({
    required String gymId,
    DateTime? date,
    String? dayKey,
  }) {
    final resolvedDayKey = _resolvePlanDayKey(date: date, dayKey: dayKey);
    if (_activePlanGymId == gymId && _activePlanDayKey == resolvedDayKey) {
      _clearPlanContext();
    }
  }

  String _resolvePlanDayKey({DateTime? date, String? dayKey}) {
    final normalizedDayKey = dayKey?.trim();
    if (normalizedDayKey != null && normalizedDayKey.isNotEmpty) {
      return normalizedDayKey;
    }
    return logicDayKey(date ?? DateTime.now());
  }

  @override
  void dispose() {
    for (final entry in _sessions.values) {
      entry.dispose();
    }
    _sessions.clear();
    _sessionOrder.clear();
    _focusedSessionKey = null;
    _isSavingAll = false;
    _activeUserId = null;
    disposeGymScopedRegistration();
    super.dispose();
  }

  void _attachServicesToProvider(DeviceProvider provider) {
    final xp = _xpProvider;
    final challenge = _challengeProvider;
    final duration = _sessionDurationService;
    final coordinator = _sessionCoordinator;
    if (xp != null &&
        challenge != null &&
        duration != null &&
        coordinator != null) {
      provider.attachExternalServices(
        xpProvider: xp,
        challengeProvider: challenge,
        sessionDurationService: duration,
        sessionCoordinator: coordinator,
      );
    }
  }

  void _onEntryChanged() {
    notifyListeners();
  }
}

class _SessionEntry {
  _SessionEntry({
    required this.key,
    required this.gymId,
    required this.deviceId,
    required this.exerciseId,
    required this.exerciseName,
    required this.userId,
    required this.provider,
  }) : snapshot = WorkoutDaySession(
         key: key,
         gymId: gymId,
         deviceId: deviceId,
         exerciseId: exerciseId,
         exerciseName: exerciseName,
         userId: userId,
         provider: provider,
         canSave: provider.hasActiveUnsavedSession,
         isSaving: provider.isSaving,
         isLoading: provider.isLoading,
         hasSessionToday: provider.hasSessionToday,
         error: provider.error,
       );

  final String key;
  final String gymId;
  final String deviceId;
  final String exerciseId;
  String? exerciseName;
  final String userId;
  final DeviceProvider provider;
  WorkoutDaySession snapshot;
  VoidCallback? _listener;

  void attachListener(VoidCallback onChanged) {
    _listener = () {
      if (refresh()) {
        onChanged();
      }
    };
    provider.addListener(_listener!);
  }

  bool refresh() {
    final next = WorkoutDaySession(
      key: key,
      gymId: gymId,
      deviceId: deviceId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      userId: userId,
      provider: provider,
      canSave: provider.hasActiveUnsavedSession,
      isSaving: provider.isSaving,
      isLoading: provider.isLoading,
      hasSessionToday: provider.hasSessionToday,
      error: provider.error,
    );
    if (snapshot == next) {
      return false;
    }
    snapshot = next;
    return true;
  }

  bool updateExerciseName(String? name) {
    if (name == null || name.isEmpty || name == exerciseName) {
      return false;
    }
    exerciseName = name;
    snapshot = snapshot.copyWith(exerciseName: name);
    return true;
  }

  void dispose() {
    if (_listener != null) {
      provider.removeListener(_listener!);
    }
    provider.dispose();
  }
}
