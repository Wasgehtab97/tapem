// lib/core/providers/device_provider.dart
// Fully instrumented provider with no-op guard and boolean 'done'.
// Fixes re-entrant rebuilds by avoiding notify on unchanged data.

import 'dart:async';
import 'package:flutter/foundation.dart'; // mapEquals

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tapem/features/device/data/repositories/device_repository_impl.dart';
import 'package:tapem/features/device/data/sources/firestore_device_source.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/models/device_session_snapshot.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:uuid/uuid.dart';
import 'package:tapem/features/rank/domain/models/level_info.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/xp_provider.dart';
import 'package:tapem/core/util/number_utils.dart';
import 'package:tapem/core/providers/challenge_provider.dart';
import 'package:tapem/features/xp/domain/device_xp_result.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:tapem/core/drafts/session_draft.dart';
import 'package:tapem/core/drafts/session_draft_repository.dart';
import 'package:tapem/core/drafts/session_draft_repository_impl.dart';
import 'package:tapem/core/config/feature_flags.dart';
import 'package:tapem/services/membership_service.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/logging/xp_trace.dart';
import 'package:tapem/core/time/logic_day.dart';
import 'package:tapem/core/recent_devices_store.dart';
import 'package:tapem/core/util/duration_utils.dart';
import 'package:tapem/core/config/remote_config.dart';

typedef LogFn = void Function(String message, [StackTrace? stack]);

void _defaultLog(String message, [StackTrace? stack]) {
  if (stack != null) {
    debugPrintStack(label: message, stackTrace: stack);
  } else {
    debugPrint(message);
  }
}

String _setsBrief(List<Map<String, dynamic>> sets) {
  return '[${sets.map((s) {
        if (s.containsKey('speed')) {
          return '{#${s['number']}:sp=${s['speed']},du=${s['duration']},d=${s['done']}}';
        }
        return '{#${s['number']}:w=${s['weight']},r=${s['reps']},dw=${s['dropWeight']},dr=${s['dropReps']},d=${s['done']}}';
      }).join(', ')}]';
}

String? resolveDeviceId(DeviceSessionSnapshot snap) {
  if (snap.deviceId.isNotEmpty) return snap.deviceId;
  return null;
}

class DeviceProvider extends ChangeNotifier {
  final GetDevicesForGym _getDevicesForGym;
  final FirebaseFirestore _firestore;
  final LogFn _log;
  final Uuid _uuid = const Uuid();
  final SessionDraftRepository _draftRepo;
  final DeviceRepository deviceRepository;
  final MembershipService _membership;

  List<Device> _devices = [];

  Device? _device;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  List<Map<String, dynamic>> _sets = [];
  String _note = '';

  List<Map<String, dynamic>> _lastSessionSets = [];
  DateTime? _lastSessionDate;
  String _lastSessionNote = '';
  String? _lastSessionId;
  int _xp = 0;
  int _level = 1;

  bool _isBodyweightMode = false;

  late String _currentExerciseId;
  String? _draftKey;
  int? _draftCreatedAt;
  Timer? _draftSaveTimer;

  // Snapshots (Historie zum Blättern)
  final List<DeviceSessionSnapshot> _sessionSnapshots = [];
  DocumentSnapshot? _lastSnapshotCursor;
  bool _snapshotsHasMore = true;
  bool _snapshotsLoading = false;
  Timer? _prefetchTimer;

  DeviceProvider({
    required FirebaseFirestore firestore,
    DeviceRepository? deviceRepository,
    GetDevicesForGym? getDevicesForGym,
    LogFn? log,
    SessionDraftRepository? draftRepo,
    required MembershipService membership,
  }) : _firestore = firestore,
       deviceRepository =
           deviceRepository ??
           DeviceRepositoryImpl(FirestoreDeviceSource(firestore: firestore)),
       _getDevicesForGym =
           getDevicesForGym ??
           GetDevicesForGym(
             deviceRepository ??
                 DeviceRepositoryImpl(
                   FirestoreDeviceSource(firestore: firestore),
                 ),
           ),
       _log = log ?? _defaultLog,
       _draftRepo = draftRepo ?? SessionDraftRepositoryImpl(),
       _membership = membership;

  // Public getters
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  Device? get device => _device;
  List<Device> get devices => List.unmodifiable(_devices);
  List<Map<String, dynamic>> get sets => List.unmodifiable(_sets);
  String get note => _note;
  List<Map<String, dynamic>> get lastSessionSets =>
      List.unmodifiable(_lastSessionSets);
  DateTime? get lastSessionDate => _lastSessionDate;
  String get lastSessionNote => _lastSessionNote;
  String? get lastSessionId => _lastSessionId;
  bool get hasSessionToday {
    if (_lastSessionDate == null) return false;
    final now = DateTime.now();
    final lastDay = DateTime(
      _lastSessionDate!.year,
      _lastSessionDate!.month,
      _lastSessionDate!.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    return lastDay == today;
  }

  int get xp => _xp;
  int get level => _level;
  bool get isBodyweightMode => _isBodyweightMode;

  List<DeviceSessionSnapshot> get sessionSnapshots =>
      List.unmodifiable(_sessionSnapshots);
  bool get hasMoreSnapshots => _snapshotsHasMore;
  bool get isLoadingSnapshots => _snapshotsLoading;

  Future<void> loadDevices(String gymId, String uid) async {
    await _membership.ensureMembership(gymId, uid);
    try {
      _devices = await _getDevicesForGym.execute(gymId);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _log('RULES_DENIED path=gyms/$gymId/devices op=read');
        await _membership.ensureMembership(gymId, uid);
        _log('RETRY_AFTER_ENSURE_MEMBERSHIP path=gyms/$gymId/devices op=read');
        _devices = await _getDevicesForGym.execute(gymId);
      } else {
        rethrow;
      }
    }
    notifyListeners();
  }

  Future<void> loadMoreSnapshots({
    required String gymId,
    required String deviceId,
    required String userId,
    int pageSize = 10,
  }) async {
    if (_snapshotsLoading || !_snapshotsHasMore) return;
    _snapshotsLoading = true;
    notifyListeners();
    await _membership.ensureMembership(gymId, userId);
    List<DeviceSessionSnapshot> page;
    try {
      page = await deviceRepository.fetchSessionSnapshotsPaginated(
        gymId: gymId,
        deviceId: deviceId,
        userId: userId,
        limit: pageSize,
        exerciseId: (_device?.isMulti ?? false) ? _currentExerciseId : null,
        startAfter: _lastSnapshotCursor,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _log(
          'RULES_DENIED path=gyms/$gymId/devices/$deviceId/sessions op=read',
        );
        await _membership.ensureMembership(gymId, userId);
        _log(
          'RETRY_AFTER_ENSURE_MEMBERSHIP path=gyms/$gymId/devices/$deviceId/sessions op=read',
        );
        page = await deviceRepository.fetchSessionSnapshotsPaginated(
          gymId: gymId,
          deviceId: deviceId,
          userId: userId,
          limit: pageSize,
          exerciseId: (_device?.isMulti ?? false) ? _currentExerciseId : null,
          startAfter: _lastSnapshotCursor,
        );
      } else {
        rethrow;
      }
    }

    if (page.isNotEmpty) {
      _sessionSnapshots.addAll(page);
      _lastSnapshotCursor = deviceRepository.lastSnapshotCursor;
    }
    _snapshotsHasMore = page.length == pageSize;
    _snapshotsLoading = false;
    _log('SNAPSHOT_PAGE_LOAD(${page.length}, $_snapshotsHasMore)');
    notifyListeners();
  }

  void patchDeviceGroups(
    String deviceId,
    List<String> primaryGroups,
    List<String> secondaryGroups,
  ) {
    final i = _devices.indexWhere((d) => d.uid == deviceId);
    if (i == -1) return;
    _devices[i] = _devices[i].copyWith(
      primaryMuscleGroups: primaryGroups,
      secondaryMuscleGroups: secondaryGroups,
    );
    notifyListeners();
  }

  void applyMuscleAssignments(
    String deviceId,
    List<String> primaryGroups,
    List<String> secondaryGroups,
  ) {
    patchDeviceGroups(deviceId, primaryGroups, secondaryGroups);
  }

  Future<void> loadDevice({
    required String gymId,
    required String deviceId,
    required String exerciseId,
    required String userId,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      await _membership.ensureMembership(gymId, userId);
      List<Device> devices;
      try {
        devices = await _getDevicesForGym.execute(gymId);
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          _log('RULES_DENIED path=gyms/$gymId/devices op=read');
          await _membership.ensureMembership(gymId, userId);
          _log(
            'RETRY_AFTER_ENSURE_MEMBERSHIP path=gyms/$gymId/devices op=read',
          );
          devices = await _getDevicesForGym.execute(gymId);
        } else {
          rethrow;
        }
      }
      _device = devices.firstWhere(
        (d) => d.uid == deviceId,
        orElse: () => throw Exception('Device not found'),
      );
      _currentExerciseId = exerciseId;

      final newKey = buildDraftKey(
        gymId: gymId,
        userId: userId,
        deviceId: deviceId,
        exerciseId: exerciseId,
        isMulti: _device!.isMulti,
      );
      if (_draftKey != null && _draftKey != newKey) {
        await _draftRepo.delete(_draftKey!);
      }
      _draftKey = newKey;
      await _draftRepo.deleteExpired(DateTime.now().millisecondsSinceEpoch);

      _xp = 0;
      _level = 1;

      _sets = [
        _device!.isCardio
            ? {
                'number': '1',
                'speed': '',
                'duration': '',
                'done': false,
              }
            : {
                'number': '1',
                'weight': '',
                'reps': '',
                'dropWeight': '',
                'dropReps': '',
                'done': false, // bool statt String
                'isBodyweight': false,
              },
      ];
      _lastSessionSets = [];
      _lastSessionDate = null;
      _lastSessionNote = '';
      _lastSessionId = null;
      _log(
        '🧩 [Provider] loadDevice initialized sets=${_sets.length} ${_setsBrief(_sets)}',
      );
      _sessionSnapshots.clear();
      _lastSnapshotCursor = null;
      _snapshotsHasMore = true;
      _snapshotsLoading = false;
      notifyListeners();

      await loadMoreSnapshots(gymId: gymId, deviceId: deviceId, userId: userId);

      if (FF.showLastSessionOnDevicePage ||
          FF.runtimeShowLastSessionOnDevicePage) {
        await _loadLastSession(gymId, deviceId, exerciseId, userId);
      }
      await _loadUserNote(gymId, deviceId, userId);
      await _loadUserXp(gymId, deviceId, userId);
      await _restoreDraft();
      _log(
        '✅ [Provider] loadDevice done device=${_device!.name} exerciseId=$exerciseId',
      );
    } catch (e, st) {
      _error = e.toString();
      _log('❌ [Provider] loadDevice error: $e', st);
    } finally {
      _setLoading(false);
    }
  }

  void addSet() {
    _sets.add(
      _device?.isCardio == true
          ? {
              'number': '${_sets.length + 1}',
              'speed': '',
              'duration': '',
              'done': false,
            }
          : {
              'number': '${_sets.length + 1}',
              'weight': '',
              'reps': '',
              'dropWeight': '',
              'dropReps': '',
              'done': false,
              'isBodyweight': _isBodyweightMode,
            },
    );
    _log('➕ [Provider] addSet → count=${_sets.length} ${_setsBrief(_sets)}');
    notifyListeners();
    _scheduleDraftSave();
  }

  void insertSetAt(int index, Map<String, dynamic> set) {
    final s = Map<String, dynamic>.from(set);
    if (_device?.isCardio != true) {
      s.putIfAbsent('isBodyweight', () => _isBodyweightMode);
    }
    _sets.insert(index, s);
    for (var i = 0; i < _sets.length; i++) {
      _sets[i]['number'] = '${i + 1}';
    }
    _log(
      '↩️ [Provider] insertSetAt($index) → count=${_sets.length} ${_setsBrief(_sets)}',
    );
    notifyListeners();
    _scheduleDraftSave();
  }

  void updateSet(
    int index, {
    String? weight,
    String? reps,
    String? dropWeight,
    String? dropReps,
    bool? isBodyweight,
    String? speed,
    String? duration,
  }) {
    final before = Map<String, dynamic>.from(_sets[index]);
    final after = Map<String, dynamic>.from(before);

    if (weight != null) after['weight'] = weight;
    if (reps != null) after['reps'] = reps;
    if (dropWeight != null) after['dropWeight'] = dropWeight;
    if (dropReps != null) after['dropReps'] = dropReps;
    if (isBodyweight != null) after['isBodyweight'] = isBodyweight;
    if (speed != null) after['speed'] = speed;
    if (duration != null) after['duration'] = duration;

    final dw = (after['dropWeight'] ?? '').toString().trim();
    final dr = (after['dropReps'] ?? '').toString().trim();
    if (dw.isEmpty || dr.isEmpty) {
      after['dropWeight'] = '';
      after['dropReps'] = '';
    }

    after['number'] = '${index + 1}';
    after['done'] = (after['done'] == true || after['done'] == 'true');

    if (mapEquals(before, after)) {
      // No-op → kein notify
      return;
    }
    _sets[index] = after;
    _log('✏️ [Provider] updateSet($index) $before → $after');
    notifyListeners();
    _scheduleDraftSave();
  }

  void removeSet(int index) {
    final removed = _sets[index];
    _sets.removeAt(index);
    for (var i = 0; i < _sets.length; i++) {
      _sets[i]['number'] = '${i + 1}';
    }
    _log(
      '🗑️ [Provider] removeSet($index) removed=$removed → count=${_sets.length} ${_setsBrief(_sets)}',
    );
    notifyListeners();
    _scheduleDraftSave();
  }

  bool _isFilled(Map<String, dynamic> s) {
    if (_device?.isCardio == true) {
      final sp = (s['speed'] ?? '').toString().trim();
      final dur = (s['duration'] ?? '').toString().trim();
      final speedVal = parseLenientDouble(sp);
      final durSec = parseHms(dur);
      final speedValid = speedVal != null &&
          speedVal > 0 &&
          speedVal <= RC.cardioMaxSpeedKmH;
      if (sp.isNotEmpty && !speedValid) {
        elogUi('cardio_speed_invalid', {'input': sp});
      }
      if (dur.isEmpty) return speedValid;
      final durValid = durSec > 0 && durSec <= RC.cardioMaxDurationSec;
      return speedValid && durValid;
    }
    final w = (s['weight'] ?? '').toString().trim();
    final r = (s['reps'] ?? '').toString().trim();
    final isBw = s['isBodyweight'] == true;
    final weightValid = isBw
        ? (w.isEmpty || double.tryParse(w.replaceAll(',', '.')) != null)
        : (w.isNotEmpty && double.tryParse(w.replaceAll(',', '.')) != null);
    return weightValid && r.isNotEmpty && int.tryParse(r) != null;
  }

  int? _focusedIndex;
  int? get focusedIndex => _focusedIndex;
  void setFocusedIndex(int? i) => _focusedIndex = i;

  bool toggleSetDone(int index) {
    final s = _sets[index];
    if (!_isFilled(s)) {
      _log(
        '⚠️ [Provider] toggleSetDone($index) blocked: invalid',
      );
      return false;
    }

    _error = null;
    final before = Map<String, dynamic>.from(s);
    final current = (s['done'] == true || s['done'] == 'true');
    s['done'] = !current;
    _sets[index] = Map<String, dynamic>.from(s);
    _log('☑️ [Provider] toggleSetDone($index) $before → ${_sets[index]}');
    notifyListeners();
    _scheduleDraftSave();
    return true;
  }

  int? nextFilledNotDoneIndex() {
    for (var i = 0; i < _sets.length; i++) {
      final s = _sets[i];
      if (s['done'] == true || s['done'] == 'true') continue;
      if (_isFilled(s)) return i;
    }
    return null;
  }

  int? completeNextFilledSet() {
    final idx = nextFilledNotDoneIndex();
    if (idx == null) return null;
    final s = Map<String, dynamic>.from(_sets[idx]);
    s['done'] = true;
    _sets[idx] = s;
    _log('☑️ [Provider] completeNextFilledSet($idx)');
    notifyListeners();
    _scheduleDraftSave();
    return idx;
  }

  int completeAllFilledNotDone() {
    var count = 0;
    for (var i = 0; i < _sets.length; i++) {
      final s = _sets[i];
      if (s['done'] == true || s['done'] == 'true') continue;
      if (!_isFilled(s)) continue;
      final after = Map<String, dynamic>.from(s);
      after['done'] = true;
      _sets[i] = after;
      count++;
    }
    if (count > 0) {
      _log('☑️ [Provider] completeAllFilledNotDone count=$count');
      notifyListeners();
      _scheduleDraftSave();
    }
    return count;
  }

  ({int done, int filledNotDone, int emptyOrIncomplete}) getSetCounts() {
    var done = 0;
    var filledNotDone = 0;
    var emptyOrIncomplete = 0;
    for (final s in _sets) {
      final filled = _isFilled(s);
      final d = s['done'] == true || s['done'] == 'true';
      if (d && filled) {
        done++;
      } else if (filled) {
        filledNotDone++;
      } else {
        emptyOrIncomplete++;
      }
    }
    return (
      done: done,
      filledNotDone: filledNotDone,
      emptyOrIncomplete: emptyOrIncomplete,
    );
  }

  int get completedCount =>
      _sets.where((s) => (s['done'] == true || s['done'] == 'true')).length;

  void setNote(String text) {
    _note = text;
    _log('📝 [Provider] setNote "$text"');
    notifyListeners();
    _scheduleDraftSave();
  }

  bool _isDraftEmpty() {
    if (_note.trim().isNotEmpty) return false;
    for (final s in _sets) {
      if (_device?.isCardio == true) {
        final sp = (s['speed'] ?? '').toString().trim();
        final dur = (s['duration'] ?? '').toString().trim();
        final d = s['done'] == true || s['done'] == 'true';
        if (sp.isNotEmpty || dur.isNotEmpty || d) return false;
      } else {
        final w = (s['weight'] ?? '').toString().trim();
        final r = (s['reps'] ?? '').toString().trim();
        final dw = (s['dropWeight'] ?? '').toString().trim();
        final dr = (s['dropReps'] ?? '').toString().trim();
        final d = s['done'] == true || s['done'] == 'true';
        if (w.isNotEmpty ||
            r.isNotEmpty ||
            dw.isNotEmpty ||
            dr.isNotEmpty ||
            d) {
          return false;
        }
      }
    }
    return true;
  }

  void _scheduleDraftSave() {
    final key = _draftKey;
    if (key == null) return;
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(
      const Duration(milliseconds: kDeviceDraftDebounceMs),
      _saveDraftNow,
    );
  }

  Future<void> _saveDraftNow() async {
    final key = _draftKey;
    if (key == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_isDraftEmpty()) {
      await _draftRepo.delete(key);
      return;
    }
    final draft = SessionDraft(
      deviceId: _device!.uid,
      exerciseId: _device!.isMulti ? _currentExerciseId : null,
      createdAt: _draftCreatedAt ?? now,
      updatedAt: now,
      note: _note,
      sets: [
        for (var i = 0; i < _sets.length; i++)
          SetDraft(
            index: i + 1,
            weight: _device?.isCardio == true
                ? ''
                : (_sets[i]['weight'] ?? '').toString(),
            reps: _device?.isCardio == true
                ? ''
                : (_sets[i]['reps'] ?? '').toString(),
            speed: _device?.isCardio == true
                ? (_sets[i]['speed'] ?? '').toString()
                : '',
            duration: _device?.isCardio == true
                ? (_sets[i]['duration'] ?? '').toString()
                : '',
            dropWeight: _device?.isCardio == true
                ? null
                : (_sets[i]['dropWeight'] ?? '').toString().isEmpty
                    ? null
                    : (_sets[i]['dropWeight']).toString(),
            dropReps: _device?.isCardio == true
                ? null
                : (_sets[i]['dropReps'] ?? '').toString().isEmpty
                    ? null
                    : (_sets[i]['dropReps']).toString(),
            done: _sets[i]['done'] == true || _sets[i]['done'] == 'true',
            isBodyweight:
                _device?.isCardio == true ? false : _sets[i]['isBodyweight'] == true,
          ),
      ],
    );
    await _draftRepo.put(key, draft);
    _draftCreatedAt = draft.createdAt;
  }

  Future<void> _restoreDraft() async {
    final key = _draftKey;
    if (key == null) return;
    final draft = await _draftRepo.get(key);
    if (draft == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - draft.updatedAt > draft.ttlMs) {
      await _draftRepo.delete(key);
      return;
    }
    _draftCreatedAt = draft.createdAt;
    _note = draft.note;
    _sets = [
      for (var i = 0; i < draft.sets.length; i++)
        _device?.isCardio == true
            ? {
                'number': '${i + 1}',
                'speed': draft.sets[i].speed,
                'duration': draft.sets[i].duration,
                'done': draft.sets[i].done,
              }
            : {
                'number': '${i + 1}',
                'weight': draft.sets[i].weight,
                'reps': draft.sets[i].reps,
                'dropWeight': draft.sets[i].dropWeight ?? '',
                'dropReps': draft.sets[i].dropReps ?? '',
                'done': draft.sets[i].done,
                'isBodyweight': draft.sets[i].isBodyweight,
              },
    ];
    notifyListeners();
  }

  void prefetchSnapshots({
    required String gymId,
    required String deviceId,
    required String userId,
    int target = 20,
  }) {
    if (_prefetchTimer?.isActive ?? false) return;
    if (!_snapshotsHasMore || _snapshotsLoading) return;
    if (_sessionSnapshots.length >= target) return;
    _prefetchTimer = Timer(const Duration(milliseconds: 800), () {
      loadMoreSnapshots(gymId: gymId, deviceId: deviceId, userId: userId);
      _log('SNAPSHOT_PREFETCH(triggered: true)');
    });
  }

  Future<bool> saveWorkoutSession({
    required BuildContext context,
    required String gymId,
    required String userId,
    required bool showInLeaderboard,
  }) async {
    final dayKey = logicDayKey(DateTime.now().toUtc());
    if (_device == null) {
      final traceId = XpTrace.buildTraceId(
        dayKey: dayKey,
        uid: userId,
        deviceId: '',
        sessionId: '',
      );
      XpTrace.log('SKIP', {'reason': 'noDevice', 'traceId': traceId});
      return false;
    }

    final sessionId = _uuid.v4();
    String? resolvedDeviceId = _device!.uid;
    final traceId = XpTrace.buildTraceId(
      dayKey: dayKey,
      uid: userId,
      deviceId: resolvedDeviceId,
      sessionId: sessionId,
    );

    _error = null;
    _isSaving = true;
    _log('💾 [Provider] saveWorkoutSession start sets=${_setsBrief(_sets)}');
    notifyListeners();

    try {
      final savedSets = _sets
          .where((s) => (s['done'] == true || s['done'] == 'true'))
          .toList();
      if (savedSets.isEmpty) {
        _error = 'Keine abgeschlossenen Sätze.';
        _log('⚠️ [Provider] save aborted: no completed sets');
        XpTrace.log('SKIP', {'reason': 'noCompletedSets', 'traceId': traceId});
        return false;
      }

      double avgSpeedKmH = 0;
      int totalDurationSec = 0;
      final speeds = <double>[];
      final durations = <int>[];
      if (_device!.isCardio) {
        for (final s in savedSets) {
          final sp = parseLenientDouble(s['speed']?.toString() ?? '') ?? 0;
          final du = parseHms(s['duration'] ?? '');
          speeds.add(sp);
          durations.add(du);
          totalDurationSec += du;
        }
        if (speeds.isNotEmpty) {
          avgSpeedKmH = speeds.reduce((a, b) => a + b) / speeds.length;
        }
      }

      XpTrace.log('SAVE_START', {
        'gymId': gymId,
        'uid': userId,
        'deviceId': _device!.uid,
        'resolvedDeviceId': resolvedDeviceId,
        'isMulti': _device!.isMulti,
        'exerciseId': _currentExerciseId,
        'showInLeaderboard': showInLeaderboard,
        'restricted': false,
        'isCardio': _device!.isCardio,
        if (_device!.isCardio) 'avgSpeedKmH': avgSpeedKmH,
        if (_device!.isCardio) 'totalDurationSec': totalDurationSec,
        if (_device!.isCardio) 'speedKmH': speeds,
        if (_device!.isCardio) 'durationSec': durations,
        'traceId': traceId,
      });

      elogUi('SESSION_SAVE_SET_ORDER', {
        'setsInputOrder':
            savedSets.map((s) => int.parse(s['number'])).toList(),
        if (_device!.isCardio) ...{
          'speedKmH': speeds,
          'durationSec': durations,
        } else ...{
          'reps':
              savedSets.map((s) => int.tryParse(s['reps'] ?? '0') ?? 0).toList(),
          'weights': savedSets
              .map((s) => double.tryParse(
                    s['weight']?.replaceAll(',', '.') ?? '0',
                  ) ??
                  0)
              .toList(),
        }
      });

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final logsCol = _firestore
          .collection('gyms')
          .doc(gymId)
          .collection('devices')
          .doc(_device!.uid)
          .collection('logs');

      final existingToday = await logsCol
          .where('userId', isEqualTo: userId)
          .where('exerciseId', isEqualTo: _currentExerciseId)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (existingToday.docs.isNotEmpty) {
        _error = 'Heute bereits gespeichert.';
        _log('⚠️ [Provider] save aborted: already saved today');
        XpTrace.log('SKIP', {'reason': 'alreadyToday', 'traceId': traceId});
        return false;
      }
      final ts = Timestamp.now();
      String tz;
      try {
        tz = await FlutterTimezone.getLocalTimezone();
      } catch (_) {
        tz = DateTime.now().timeZoneName;
      }
      final batch = _firestore.batch();

      for (final set in savedSets) {
        final ref = logsCol.doc();
        final data = <String, dynamic>{
          'deviceId': _device!.uid,
          'userId': userId,
          'exerciseId': _currentExerciseId,
          'sessionId': sessionId,
          'timestamp': ts,
          'setNumber': int.parse(set['number']),
          'note': _note,
          'tz': tz,
        };
        if (_device!.isCardio) {
          final speed = parseLenientDouble(set['speed']?.toString() ?? '') ?? 0;
          final duration = parseHms(set['duration'] ?? '');
          data['speedKmH'] = speed;
          if (duration > 0) data['durationSec'] = duration;
        } else {
          final weightStr = (set['weight'] ?? '').toString().replaceAll(',', '.');
          final weight = double.tryParse(weightStr) ?? 0;
          final isBw = set['isBodyweight'] == true;
          data['weight'] = weight;
          data['reps'] = int.parse(set['reps']!);
          if (isBw) data['isBodyweight'] = true;
          if ((set['dropWeight'] ?? '').toString().isNotEmpty &&
              (set['dropReps'] ?? '').toString().isNotEmpty) {
            data['dropWeightKg'] = double.parse(
              set['dropWeight']!.replaceAll(',', '.'),
            );
            data['dropReps'] = int.parse(set['dropReps']!);
          }
        }
        batch.set(ref, data);
      }

      final noteRef = _firestore
          .collection('gyms')
          .doc(gymId)
          .collection('devices')
          .doc(_device!.uid)
          .collection('userNotes')
          .doc(userId);
      batch.set(noteRef, {'note': _note, 'updatedAt': ts});

      final snapshot = _buildSnapshot(
        sessionId: sessionId,
        device: _device!,
        exerciseId: _currentExerciseId,
        userId: userId,
      );

      await batch.commit();
      _log('📚 [Provider] logs stored session=$sessionId');
      XpTrace.log('LOGS_STORED', {
        'sessionId': sessionId,
        'sets': savedSets.length,
        'isCardio': _device!.isCardio,
        if (_device!.isCardio) 'avgSpeedKmH': avgSpeedKmH,
        if (_device!.isCardio) 'totalDurationSec': totalDurationSec,
        if (_device!.isCardio) 'speedKmH': speeds,
        if (_device!.isCardio) 'durationSec': durations,
        'traceId': traceId,
      });

      await deviceRepository.writeSessionSnapshot(gymId, snapshot);
      _log('SNAPSHOT_WRITE($sessionId, ${snapshot.sets.length})');
      final dayKey = logicDayKey(DateTime.now().toUtc());
      elogUi('SAVE_PERSIST_OK', {
        'uid': userId,
        'gymId': gymId,
        'deviceId': _device!.uid,
        'sessionId': sessionId,
        'isMulti': _device!.isMulti,
        'dayKey': dayKey,
        'screen': 'DeviceScreen',
        'isCardio': _device!.isCardio,
        if (_device!.isCardio) 'avgSpeedKmH': avgSpeedKmH,
        if (_device!.isCardio) 'totalDurationSec': totalDurationSec,
        if (_device!.isCardio) 'speedKmH': speeds,
        if (_device!.isCardio) 'durationSec': durations,
      });

      resolvedDeviceId = resolveDeviceId(snapshot);
      if (resolvedDeviceId == null || resolvedDeviceId.isEmpty) {
        XpTrace.log('SKIP', {'reason': 'missingDeviceId', 'traceId': traceId});
        elogDeviceXp('SKIP_NO_DEVICE', {
          'sessionId': sessionId,
          'exerciseId': _currentExerciseId,
          'isMulti': _device!.isMulti,
          'gymId': gymId,
          'uid': userId,
        });
      } else {
        elogDeviceXp('PROVIDER_SAVE_OK_FORWARD_XP', {
          'uid': userId,
          'gymId': gymId,
          'sessionId': sessionId,
          'deviceId': resolvedDeviceId,
          'isMulti': _device!.isMulti,
          'showInLeaderboard': showInLeaderboard,
        });
        XpTrace.log('CALL_ADD_SESSION_XP', {
          'intent': 'credit',
          'traceId': traceId,
          'isCardio': _device!.isCardio,
        });
        try {
          final xpResult = await Provider.of<XpProvider>(context, listen: false)
              .addSessionXp(
            gymId: gymId,
            userId: userId,
            deviceId: resolvedDeviceId,
            sessionId: sessionId,
            showInLeaderboard: showInLeaderboard,
            isMulti: _device!.isMulti,
            exerciseId: _currentExerciseId,
            traceId: traceId,
          );
          XpTrace.log('CALL_RESULT', {
            'result': xpResult.name,
            'deltaXp': xpResult == DeviceXpResult.okAdded ? 50 : 0,
            'traceId': traceId,
            'isCardio': _device!.isCardio,
          });
          if (xpResult == DeviceXpResult.okAdded) {
            final info = LevelService()
                .addXp(LevelInfo(level: _level, xp: _xp), LevelService.xpPerSession);
            _level = info.level;
            _xp = info.xp;
            notifyListeners();
          }
          await Provider.of<ChallengeProvider>(
            context,
            listen: false,
          ).checkChallenges(gymId, userId, resolvedDeviceId);
        } catch (e, st) {
          XpTrace.log('CALL_RESULT', {
            'result': 'error',
            'traceId': traceId,
            'error': e.toString(),
            'isCardio': _device!.isCardio,
          });
          _log('⚠️ [Provider] XP/Challenges error: $e', st);
        }
      }

      _lastSessionSets = [
        for (final s in savedSets)
          _device!.isCardio
              ? {
                  'number': s['number'].toString(),
                  'speed': s['speed'].toString(),
                  'duration': s['duration'].toString(),
                }
              : {
                  'number': s['number'].toString(),
                  'weight': s['weight'].toString(),
                  'reps': s['reps'].toString(),
                  'dropWeight': (s['dropWeight'] ?? '').toString(),
                  'dropReps': (s['dropReps'] ?? '').toString(),
                  'isBodyweight': s['isBodyweight'] == true,
                },
      ];
      _lastSessionDate = ts.toDate();
      _lastSessionNote = _note;
      _lastSessionId = sessionId;

      _sets.removeWhere((s) => (s['done'] == true || s['done'] == 'true'));
      if (_sets.isEmpty) {
        _sets = [
          {
            'number': '1',
            'weight': '',
            'reps': '',
            'done': false,
            'dropWeight': '',
            'dropReps': '',
            'isBodyweight': _isBodyweightMode,
          },
        ];
      }
      for (var i = 0; i < _sets.length; i++) {
        _sets[i]['number'] = '${i + 1}';
      }

      _log(
        '✅ [Provider] save done. remainingSets=${_setsBrief(_sets)} lastSessionId=$sessionId',
      );
      await RecentDevicesStore.record(gymId, _device!.uid);
      if (_draftKey != null) {
        await _draftRepo.delete(_draftKey!);
      }
      _draftCreatedAt = null;
      notifyListeners();
      return true;
    } catch (e, st) {
      _error = e.toString();
      _log('❌ [Provider] saveWorkoutSession error: $e', st);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Saves a simple cardio session with only total duration.
  Future<bool> saveCardioTimedSession({
    required BuildContext context,
    required String gymId,
    required String userId,
    required int durationSec,
  }) async {
    if (_device == null) return false;

    final sessionId = _uuid.v4();
    final ts = Timestamp.now();
    String tz;
    try {
      tz = await FlutterTimezone.getLocalTimezone();
    } catch (_) {
      tz = DateTime.now().timeZoneName;
    }

    final logsCol = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(_device!.uid)
        .collection('logs');
    await logsCol.add({
      'deviceId': _device!.uid,
      'userId': userId,
      'exerciseId': _currentExerciseId,
      'sessionId': sessionId,
      'timestamp': ts,
      'setNumber': 1,
      'note': _note,
      'tz': tz,
      'durationSec': durationSec,
    });

    final snap = DeviceSessionSnapshot(
      sessionId: sessionId,
      deviceId: _device!.uid,
      exerciseId: _currentExerciseId,
      createdAt: ts.toDate(),
      userId: userId,
      note: _note,
      sets: const [],
      isCardio: true,
      mode: 'timed',
      durationSec: durationSec,
    );
    await deviceRepository.writeSessionSnapshot(gymId, snap);
    elogUi('cardio_session_saved', {
      'mode': 'timed',
      'durationSec': durationSec,
    });
    return true;
  }

  DeviceSessionSnapshot _buildSnapshot({
    required String sessionId,
    required Device device,
    String? exerciseId,
    required String userId,
  }) {
    return DeviceSessionSnapshot(
      sessionId: sessionId,
      deviceId: device.uid,
      exerciseId: exerciseId,
      createdAt: DateTime.now(),
      userId: userId,
      note: _note,
      sets: _sets
          .map((s) {
            if (device.isCardio) {
              return SetEntry(
                speedKmH: parseLenientDouble(
                  s['speed']?.toString() ?? '',
                ),
                durationSec: () {
                  final d = parseHms(s['duration']?.toString() ?? '');
                  return d > 0 ? d : null;
                }(),
                done: s['done'] == true || s['done'] == 'true',
              );
            }
            return SetEntry(
              kg: num.tryParse(
                    s['weight']?.toString().replaceAll(',', '.') ?? '0',
                  ) ??
                  0,
              reps: int.tryParse(s['reps']?.toString() ?? '0') ?? 0,
              done: s['done'] == true || s['done'] == 'true',
              drops: (s['dropWeight']?.toString().isNotEmpty == true &&
                      s['dropReps']?.toString().isNotEmpty == true)
                  ? [
                      DropEntry(
                        kg: num.tryParse(
                              s['dropWeight']!.toString().replaceAll(',', '.'),
                            ) ??
                            0,
                        reps: int.tryParse(s['dropReps']!.toString()) ?? 0,
                      ),
                    ]
                  : const [],
              isBodyweight: s['isBodyweight'] == true,
            );
          })
          .toList(),
      renderVersion: 1,
      uiHints: {'plannedTableCollapsed': false},
      isCardio: device.isCardio,
    );
  }

  Future<void> _loadLastSession(
    String gymId,
    String deviceId,
    String exerciseId,
    String userId,
  ) async {
    final logsCol = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('logs');

    final lastSnap = await logsCol
        .where('userId', isEqualTo: userId)
        .where('exerciseId', isEqualTo: exerciseId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (lastSnap.docs.isEmpty) return;

    final data = lastSnap.docs.first.data();
    final sid = data['sessionId'] as String;
    final ts = (data['timestamp'] as Timestamp).toDate();
    final note = data['note'] as String? ?? '';

    final sessionDocs = await logsCol
        .where('userId', isEqualTo: userId)
        .where('exerciseId', isEqualTo: exerciseId)
        .where('sessionId', isEqualTo: sid)
        .orderBy('timestamp')
        .get();

    _lastSessionSets = [
      for (var entry in sessionDocs.docs.asMap().entries)
        _device?.isCardio == true
            ? {
                'number': '${entry.key + 1}',
                'speed': '${entry.value.data()['speedKmH'] ?? ''}',
                'duration': () {
                  final dur =
                      (entry.value.data()['durationSec'] as num?)?.toInt() ?? 0;
                  return dur > 0 ? formatHms(dur) : '';
                }(),
              }
            : {
                'number': '${entry.key + 1}',
                'weight': '${entry.value.data()['weight']}',
                'reps': '${entry.value.data()['reps']}',
                'dropWeight': '${entry.value.data()['dropWeightKg'] ?? ''}',
                'dropReps': '${entry.value.data()['dropReps'] ?? ''}',
                'isBodyweight': entry.value.data()['isBodyweight'] ?? false,
              },
    ];
    _lastSessionDate = ts;
    _lastSessionNote = note;
    _lastSessionId = sid;
    _log(
      '📜 [Provider] loaded last session id=$sid sets=${_lastSessionSets.length}',
    );
    notifyListeners();
  }

  Future<void> _loadUserNote(
    String gymId,
    String deviceId,
    String userId,
  ) async {
    final snap = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('userNotes')
        .doc(userId)
        .get();
    if (snap.exists) {
      final data = snap.data()!;
      _note = data['note'] as String? ?? '';
      _log('📝 [Provider] loaded user note "${_note.replaceAll('\n', '\\n')}"');
      notifyListeners();
    }
  }

  Future<void> _loadUserXp(String gymId, String deviceId, String userId) async {
    final xpDoc = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('leaderboard')
        .doc(userId)
        .get();
    if (xpDoc.exists) {
      final data = xpDoc.data()!;
      _xp = data['xp'] as int? ?? 0;
      _level = data['level'] as int? ?? 1;
    } else {
      _xp = 0;
      _level = 1;
    }
    _log('⭐ [Provider] load XP level=$_level xp=$_xp');
    notifyListeners();
  }

  void toggleBodyweightMode() {
    _isBodyweightMode = !_isBodyweightMode;
    _log('🏋️ [Provider] bodyweightMode=$_isBodyweightMode');
    notifyListeners();
  }

  @override
  void dispose() {
    _draftSaveTimer?.cancel();
    unawaited(_saveDraftNow());
    super.dispose();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _log('⏳ [Provider] isLoading=$value');
    notifyListeners();
  }
}
