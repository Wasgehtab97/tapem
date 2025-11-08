import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:tapem/core/drafts/session_draft_repository.dart';
import 'package:tapem/core/drafts/session_draft_repository_impl.dart';
import 'package:tapem/core/providers/challenge_provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/providers/xp_provider.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';
import 'package:tapem/features/community/data/community_stats_writer.dart';
import 'package:tapem/features/device/data/repositories/device_repository_impl.dart';
import 'package:tapem/features/device/data/sources/firestore_device_source.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:tapem/services/membership_service.dart';

@immutable
class WorkoutDaySession {
  const WorkoutDaySession({
    required this.key,
    required this.gymId,
    required this.deviceId,
    required this.exerciseId,
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
  final String userId;
  final DeviceProvider provider;
  final bool canSave;
  final bool isSaving;
  final bool isLoading;
  final bool hasSessionToday;
  final String? error;

  bool get canShowSaveAction => canSave && !hasSessionToday && !isSaving;

  bool get hasValidationWarning => hasSessionToday || error != null;

  @override
  int get hashCode => Object.hash(
        key,
        gymId,
        deviceId,
        exerciseId,
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

class WorkoutDayController extends ChangeNotifier {
  WorkoutDayController({
    required FirebaseFirestore firestore,
    required MembershipService membership,
    DeviceRepository? deviceRepository,
    GetDevicesForGym? getDevicesForGym,
    CommunityStatsWriter? communityStatsWriter,
    SessionDraftRepository Function()? createDraftRepository,
  })  : _firestore = firestore,
        _membership = membership,
        _communityStatsWriter =
            communityStatsWriter ?? CommunityStatsWriter(firestore: firestore),
        _createDraftRepository =
            createDraftRepository ?? (() => SessionDraftRepositoryImpl()) {
    _deviceRepository = deviceRepository ??
        DeviceRepositoryImpl(FirestoreDeviceSource(firestore: firestore));
    _getDevicesForGym =
        getDevicesForGym ?? GetDevicesForGym(_deviceRepository);
  }

  final FirebaseFirestore _firestore;
  MembershipService _membership;
  late final DeviceRepository _deviceRepository;
  late final GetDevicesForGym _getDevicesForGym;
  final CommunityStatsWriter _communityStatsWriter;
  final SessionDraftRepository Function() _createDraftRepository;

  XpProvider? _xpProvider;
  ChallengeProvider? _challengeProvider;
  WorkoutSessionDurationService? _sessionDurationService;

  final Map<String, _SessionEntry> _sessions = <String, _SessionEntry>{};
  String? _focusedSessionKey;
  bool _isSavingAll = false;

  void attachExternalServices({
    required XpProvider xpProvider,
    required ChallengeProvider challengeProvider,
    required WorkoutSessionDurationService sessionDurationService,
  }) {
    _xpProvider = xpProvider;
    _challengeProvider = challengeProvider;
    _sessionDurationService = sessionDurationService;
    for (final entry in _sessions.values) {
      entry.provider.attachExternalServices(
        xpProvider: xpProvider,
        challengeProvider: challengeProvider,
        sessionDurationService: sessionDurationService,
      );
    }
  }

  void updateMembership(MembershipService membership) {
    if (!identical(_membership, membership)) {
      _membership = membership;
    }
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
      getDevicesForGym: _getDevicesForGym,
      draftRepo: _createDraftRepository(),
      membership: _membership,
      communityStatsWriter: _communityStatsWriter,
    );
    final entry = _SessionEntry(
      key: key,
      gymId: gymId,
      deviceId: deviceId,
      exerciseId: exerciseId,
      userId: userId,
      provider: provider,
    );
    _attachServicesToProvider(provider);
    entry.attachListener(_onEntryChanged);
    _sessions[key] = entry;
    _focusedSessionKey = key;
    notifyListeners();
    return entry.snapshot;
  }

  List<WorkoutDaySession> activeSessions() {
    return List.unmodifiable(_sessions.values.map((entry) => entry.snapshot));
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
    final entry = _sessions.remove(key);
    if (entry == null) {
      return false;
    }
    entry.dispose();
    if (_focusedSessionKey == key) {
      _focusedSessionKey = _sessions.isEmpty ? null : _sessions.keys.last;
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

  Future<SaveAllSessionsResult> saveAllSessions({
    required String userId,
    required bool showInLeaderboard,
    String? userName,
    String? gender,
    double? bodyWeightKg,
    Map<String, int?> plannedRestSecondsBySession = const {},
  }) async {
    if (_isSavingAll) {
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

    _isSavingAll = true;
    notifyListeners();
    try {
      for (final entry in entries) {
        entry.refresh();
        final snapshot = entry.snapshot;
        if (!snapshot.canShowSaveAction) {
          continue;
        }
        attempted++;
        final provider = entry.provider;
        final ok = await provider.saveWorkoutSession(
          gymId: entry.gymId,
          userId: userId,
          showInLeaderboard: showInLeaderboard,
          userName: userName,
          gender: gender,
          bodyWeightKg: bodyWeightKg,
          plannedRestSeconds: plannedRestSecondsBySession[entry.key],
        );
        if (ok) {
          saved++;
          savedKeys.add(entry.key);
        } else {
          failures[entry.key] = provider.error;
        }
      }
    } finally {
      _isSavingAll = false;
      notifyListeners();
    }

    final result = SaveAllSessionsResult(
      attempted: attempted,
      saved: saved,
      failedSessions: failures,
      savedSessionKeys: List.unmodifiable(savedKeys),
    );

    final durationService = _sessionDurationService;
    if (durationService != null && result.attempted > 0) {
      try {
        if (result.saved > 0) {
          await durationService.save();
        } else {
          await durationService.discard();
        }
      } catch (_) {
        // Ignore timer persistence failures; saving the workout is more important.
      }
    }

    return result;
  }

  @override
  void dispose() {
    for (final entry in _sessions.values) {
      entry.dispose();
    }
    _sessions.clear();
    super.dispose();
  }

  void _attachServicesToProvider(DeviceProvider provider) {
    final xp = _xpProvider;
    final challenge = _challengeProvider;
    final duration = _sessionDurationService;
    if (xp != null && challenge != null && duration != null) {
      provider.attachExternalServices(
        xpProvider: xp,
        challengeProvider: challenge,
        sessionDurationService: duration,
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
    required this.userId,
    required this.provider,
  }) : snapshot = WorkoutDaySession(
          key: key,
          gymId: gymId,
          deviceId: deviceId,
          exerciseId: exerciseId,
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

  void dispose() {
    if (_listener != null) {
      provider.removeListener(_listener!);
    }
    provider.dispose();
  }
}
