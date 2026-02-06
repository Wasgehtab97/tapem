import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:google_fonts/google_fonts.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/device/presentation/models/workout_device_selection.dart';
import 'package:tapem/features/device/presentation/models/session_set_vm.dart';
import 'package:tapem/features/device/presentation/widgets/machine_leaderboard_sheet.dart';
import 'package:tapem/features/device/presentation/widgets/session_rest_timer.dart';
import 'package:tapem/features/device/providers/exercise_provider.dart';
import 'package:tapem/features/device/providers/workout_day_controller_provider.dart';
import 'package:tapem/features/gym/presentation/screens/gym_screen.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/widgets/brand_outline.dart';
import 'package:tapem/features/feedback/presentation/widgets/feedback_button.dart'
    show showFeedbackDialog;
import 'package:tapem/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Fixed dark palette for workout table cards (theme-independent)
const _cardSurface = Color(0xFF07080D); // near‑black with slight blue hue
const _cardPanelTop = Color(0xFF0A0C13);
const _cardPanelBottom = Color(0xFF06070C);
const _rowBgStart = Color(0xFF0C0E16);
const _rowBgEnd = Color(0xFF090B12);
const _strokeLight = Color(0x10FFFFFF); // ~6% white tint
const _strokeStrong = Color(0x1AFFFFFF); // ~10% white tint

enum _SessionOptionAction {
  remove,
  replace,
}

/// Builder function used by [WorkoutDayScreen.sessionBuilder] to render
/// sessions with the new table-style UI that mirrors the marketing website.
Widget buildWorkoutDayTableSessionCard(
  BuildContext context,
  WorkoutDaySession session,
  int displayIndex,
) {
  return WorkoutDayTableCard(
    session: session,
    displayIndex: displayIndex,
  );
}

/// Workout-day specific session card with a compact, table-like layout.
///
/// This widget intentionally keeps all business logic in [DeviceProvider],
/// [WorkoutDayController] and the global [OverlayNumericKeypadController].
/// It focuses purely on:
///  - loading the device once,
///  - wiring taps to the numeric keypad + provider,
///  - rendering the premium table layout used on the marketing website.
class WorkoutDayTableCard extends riverpod.ConsumerStatefulWidget {
  const WorkoutDayTableCard({
    super.key,
    required this.session,
    required this.displayIndex,
  });

  final WorkoutDaySession session;
  final int displayIndex;

  @override
  riverpod.ConsumerState<WorkoutDayTableCard> createState() =>
      _WorkoutDayTableCardState();
}

class _WorkoutDayTableCardState
    extends riverpod.ConsumerState<WorkoutDayTableCard> {
  bool _didLoad = false;
  final List<TextEditingController> _weightCtrls = [];
  final List<TextEditingController> _repsCtrls = [];
  final List<FocusNode> _weightFocusNodes = [];
  final List<FocusNode> _repsFocusNodes = [];
  final List<List<TextEditingController>> _dropWeightCtrls = [];
  final List<List<TextEditingController>> _dropRepsCtrls = [];
  final List<List<FocusNode>> _dropWeightFocusNodes = [];
  final List<List<FocusNode>> _dropRepsFocusNodes = [];
  final List<GlobalKey> _rowKeys = [];
  bool _muteCtrls = false;
  int _lastFocusRequestId = -1;
  final Set<int> _expandedDropRows = <int>{};
  int? _restSeconds;
  final GlobalKey<SessionRestTimerState> _rowRestTimerKey =
      GlobalKey<SessionRestTimerState>();

  DeviceProvider get _provider => widget.session.provider;

  @override
  void initState() {
    super.initState();
    _provider.addListener(_handleProviderChanged);
    _syncControllersFromProvider();
    _loadPersistedRestSeconds();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureSessionLoaded();
  }

  @override
  void dispose() {
    for (final c in _weightCtrls) {
      c.dispose();
    }
    for (final c in _repsCtrls) {
      c.dispose();
    }
    for (final f in _weightFocusNodes) {
      f.dispose();
    }
    for (final f in _repsFocusNodes) {
      f.dispose();
    }
    for (final row in _dropWeightCtrls) {
      for (final c in row) {
        c.dispose();
      }
    }
    for (final row in _dropRepsCtrls) {
      for (final c in row) {
        c.dispose();
      }
    }
    for (final row in _dropWeightFocusNodes) {
      for (final f in row) {
        f.dispose();
      }
    }
    for (final row in _dropRepsFocusNodes) {
      for (final f in row) {
        f.dispose();
      }
    }
    _provider.removeListener(_handleProviderChanged);
    super.dispose();
  }

  Future<void> _showSessionOptions() async {
    FocusManager.instance.primaryFocus?.unfocus();
    ref.read(overlayNumericKeypadControllerProvider).close();

    if (!mounted) return;
    final action = await showModalBottomSheet<_SessionOptionAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.swap_horiz_rounded),
                  title: const Text('Übung austauschen'),
                  onTap: () => Navigator.of(context)
                      .pop(_SessionOptionAction.replace),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('Übung entfernen'),
                  onTap: () =>
                      Navigator.of(context).pop(_SessionOptionAction.remove),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;
    switch (action) {
      case _SessionOptionAction.remove:
        _removeSession();
        break;
      case _SessionOptionAction.replace:
        await _replaceSession();
        break;
    }
  }

  void _removeSession() {
    final controller = ref.read(workoutDayControllerProvider);
    final closed = controller.closeSession(widget.session.key);
    if (!closed) return;
    final auth = ref.read(authControllerProvider);
    final userId = auth.userId;
    if (userId == null) return;
    final activeGymId = auth.gymCode ?? widget.session.gymId;
    final remaining = controller.sessionsFor(
      userId: userId,
      gymId: activeGymId,
    );
    if (remaining.isEmpty && mounted) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _replaceSession() async {
    final selection =
        await Navigator.of(context).push<WorkoutDeviceSelection>(
      MaterialPageRoute(
        builder: (ctx) => GymScreen(
          onSelect: (result) => Navigator.of(ctx).pop(result),
        ),
      ),
    );
    if (!mounted || selection == null) return;
    final auth = ref.read(authControllerProvider);
    final userId = auth.userId;
    if (userId == null) return;
    final controller = ref.read(workoutDayControllerProvider);
    controller.replaceSession(
      oldKey: widget.session.key,
      gymId: selection.gymId,
      deviceId: selection.deviceId,
      exerciseId: selection.exerciseId,
      exerciseName: selection.exerciseName ?? selection.exerciseId,
      userId: userId,
    );
  }

  void _handleProviderChanged() {
    if (!mounted) return;
    _syncControllersFromProvider();
    setState(() {});
  }

  void _syncControllersFromProvider() {
    final sets = _provider.sets;

    // Ensure controller lists match set count.
    while (_weightCtrls.length < sets.length) {
      final weightCtrl = TextEditingController();
      final repsCtrl = TextEditingController();
      final weightFocus = FocusNode();
      final repsFocus = FocusNode();
      _weightCtrls.add(weightCtrl);
      _repsCtrls.add(repsCtrl);
      _weightFocusNodes.add(weightFocus);
      _repsFocusNodes.add(repsFocus);
      weightCtrl.addListener(() => _handleWeightChanged(weightCtrl));
      repsCtrl.addListener(() => _handleRepsChanged(repsCtrl));
      _dropWeightCtrls.add(<TextEditingController>[]);
      _dropRepsCtrls.add(<TextEditingController>[]);
      _dropWeightFocusNodes.add(<FocusNode>[]);
      _dropRepsFocusNodes.add(<FocusNode>[]);
    }
    while (_weightCtrls.length > sets.length) {
      final wc = _weightCtrls.removeLast();
      final rc = _repsCtrls.removeLast();
      final wf = _weightFocusNodes.removeLast();
      final rf = _repsFocusNodes.removeLast();
      final dropWeights = _dropWeightCtrls.removeLast();
      final dropReps = _dropRepsCtrls.removeLast();
      final dropWeightFocus = _dropWeightFocusNodes.removeLast();
      final dropRepsFocus = _dropRepsFocusNodes.removeLast();
      if (_rowKeys.isNotEmpty) _rowKeys.removeLast();
      wc.dispose();
      rc.dispose();
      wf.dispose();
      rf.dispose();
      for (final c in dropWeights) {
        c.dispose();
      }
      for (final c in dropReps) {
        c.dispose();
      }
      for (final f in dropWeightFocus) {
        f.dispose();
      }
      for (final f in dropRepsFocus) {
        f.dispose();
      }
    }

    // Sync texts without triggering listeners.
    _muteCtrls = true;
    for (var i = 0; i < sets.length; i++) {
      final set = sets[i];
      final weight = (set['weight'] ?? '').toString();
      final reps = (set['reps'] ?? '').toString();
      final drops = _dropsFromSet(set);
      if (_weightCtrls[i].text != weight) {
        _weightCtrls[i].text = weight;
        _weightCtrls[i].selection =
            TextSelection.collapsed(offset: _weightCtrls[i].text.length);
      }
      if (_repsCtrls[i].text != reps) {
        _repsCtrls[i].text = reps;
        _repsCtrls[i].selection =
            TextSelection.collapsed(offset: _repsCtrls[i].text.length);
      }

      final dropWeightRow = _dropWeightCtrls[i];
      final dropRepsRow = _dropRepsCtrls[i];
      final dropWeightFocusRow = _dropWeightFocusNodes[i];
      final dropRepsFocusRow = _dropRepsFocusNodes[i];
      while (dropWeightRow.length < drops.length) {
        final c = TextEditingController();
        final f = FocusNode();
        dropWeightRow.add(c);
        dropWeightFocusRow.add(f);
        c.addListener(() => _handleDropWeightChanged(c));
      }
      while (dropRepsRow.length < drops.length) {
        final c = TextEditingController();
        final f = FocusNode();
        dropRepsRow.add(c);
        dropRepsFocusRow.add(f);
        c.addListener(() => _handleDropRepsChanged(c));
      }
      while (dropWeightRow.length > drops.length) {
        dropWeightRow.removeLast().dispose();
        dropWeightFocusRow.removeLast().dispose();
      }
      while (dropRepsRow.length > drops.length) {
        dropRepsRow.removeLast().dispose();
        dropRepsFocusRow.removeLast().dispose();
      }

      while (_rowKeys.length < sets.length) {
        _rowKeys.add(GlobalKey());
      }

      for (var d = 0; d < drops.length; d++) {
        final dropWeight = drops[d]['weight'] ?? '';
        final dropReps = drops[d]['reps'] ?? '';
        if (dropWeightRow[d].text != dropWeight) {
          dropWeightRow[d].text = dropWeight;
          dropWeightRow[d].selection =
              TextSelection.collapsed(offset: dropWeightRow[d].text.length);
        }
        if (dropRepsRow[d].text != dropReps) {
          dropRepsRow[d].text = dropReps;
          dropRepsRow[d].selection =
              TextSelection.collapsed(offset: dropRepsRow[d].text.length);
        }
      }
    }
    while (_rowKeys.length < sets.length) {
      _rowKeys.add(GlobalKey());
    }
    _muteCtrls = false;
  }

  void _handleWeightChanged(TextEditingController controller) {
    if (_muteCtrls) return;
    final index = _weightCtrls.indexOf(controller);
    if (index == -1) return;
    if (index >= _provider.sets.length) return;
    final set = _provider.sets[index];
    final isBw = set['isBodyweight'] == true;
    _provider.updateSet(
      index,
      weight: controller.text,
      isBodyweight: isBw,
    );
  }

  void _handleRepsChanged(TextEditingController controller) {
    if (_muteCtrls) return;
    final index = _repsCtrls.indexOf(controller);
    if (index == -1) return;
    if (index >= _provider.sets.length) return;
    _provider.updateSet(index, reps: controller.text);
  }

  void _handleDropWeightChanged(TextEditingController controller) {
    if (_muteCtrls) return;
    final indices = _findDropIndices(_dropWeightCtrls, controller);
    if (indices == null) return;
    final index = indices.$1;
    final dropIndex = indices.$2;
    if (index >= _provider.sets.length) return;
    _provider.updateDrop(
      index,
      dropIndex,
      weight: controller.text,
    );
  }

  void _handleDropRepsChanged(TextEditingController controller) {
    if (_muteCtrls) return;
    final indices = _findDropIndices(_dropRepsCtrls, controller);
    if (indices == null) return;
    final index = indices.$1;
    final dropIndex = indices.$2;
    if (index >= _provider.sets.length) return;
    _provider.updateDrop(
      index,
      dropIndex,
      reps: controller.text,
    );
  }

  Future<void> _ensureSessionLoaded() async {
    if (_didLoad) return;
    _didLoad = true;

    final container =
        riverpod.ProviderScope.containerOf(context, listen: false);
    final auth = container.read(authControllerProvider);
    final settings = container.read(settingsProvider);

    await settings.load(auth.userId!);

    await _provider.loadDevice(
      gymId: widget.session.gymId,
      deviceId: widget.session.deviceId,
      exerciseId: widget.session.exerciseId,
      userId: widget.session.userId,
    );

    if (!mounted) return;
    setState(() {});
  }

  void _focusSession() {
    final controller =
        riverpod.ProviderScope.containerOf(context, listen: false)
            .read(workoutDayControllerProvider);
    controller.focusSession(widget.session.key);
  }

  List<Map<String, String>> _dropsFromSet(Map<String, dynamic> set) {
    final raw = set['drops'];
    final drops = <Map<String, String>>[];
    if (raw is List) {
      for (final entry in raw) {
        if (entry is Map) {
          final map = Map<String, dynamic>.from(entry);
          drops.add({
            'weight': (map['weight'] ?? map['kg'] ?? '').toString(),
            'reps': (map['reps'] ?? map['wdh'] ?? '').toString(),
          });
        }
      }
    }
    if (drops.isEmpty) {
      final legacyWeight = (set['dropWeight'] ?? '').toString();
      final legacyReps = (set['dropReps'] ?? '').toString();
      if (legacyWeight.isNotEmpty || legacyReps.isNotEmpty) {
        drops.add({'weight': legacyWeight, 'reps': legacyReps});
      }
    }
    return drops;
  }

  (int, int)? _findDropIndices(
    List<List<TextEditingController>> controllerSets,
    TextEditingController controller,
  ) {
    for (var i = 0; i < controllerSets.length; i++) {
      final row = controllerSets[i];
      for (var d = 0; d < row.length; d++) {
        if (row[d] == controller) {
          return (i, d);
        }
      }
    }
    return null;
  }

  void _openKeypadForField({
    required int setIndex,
    required DeviceSetFieldFocus field,
    int dropIndex = 0,
  }) {
    _ensureRowVisible(setIndex);
    _focusSession();

    final container =
        riverpod.ProviderScope.containerOf(context, listen: false);
    final dayController = container.read(workoutDayControllerProvider);
    final prov = dayController.providerForKey(widget.session.key);
    if (prov == null) return;

    // Clear focus on all other sessions to avoid multiple highlighted fields.
    for (final other in dayController.activeSessions()) {
      if (!identical(other.provider, prov)) {
        other.provider.clearFocus();
      }
    }

    TextEditingController controller;
    FocusNode focusNode;
    switch (field) {
      case DeviceSetFieldFocus.weight:
        if (setIndex < 0 || setIndex >= _weightCtrls.length) return;
        controller = _weightCtrls[setIndex];
        focusNode = _weightFocusNodes[setIndex];
        break;
      case DeviceSetFieldFocus.reps:
        if (setIndex < 0 || setIndex >= _repsCtrls.length) return;
        controller = _repsCtrls[setIndex];
        focusNode = _repsFocusNodes[setIndex];
        break;
      case DeviceSetFieldFocus.dropWeight:
        if (setIndex < 0 || setIndex >= _dropWeightCtrls.length) return;
        if (dropIndex < 0 ||
            dropIndex >= _dropWeightCtrls[setIndex].length) {
          return;
        }
        controller = _dropWeightCtrls[setIndex][dropIndex];
        focusNode = _dropWeightFocusNodes[setIndex][dropIndex];
        break;
      case DeviceSetFieldFocus.dropReps:
        if (setIndex < 0 || setIndex >= _dropRepsCtrls.length) return;
        if (dropIndex < 0 || dropIndex >= _dropRepsCtrls[setIndex].length) {
          return;
        }
        controller = _dropRepsCtrls[setIndex][dropIndex];
        focusNode = _dropRepsFocusNodes[setIndex][dropIndex];
        break;
    }

    _lastFocusRequestId = prov.requestFocus(
      index: setIndex,
      field: field,
      dropIndex: field == DeviceSetFieldFocus.dropWeight ||
              field == DeviceSetFieldFocus.dropReps
          ? dropIndex
          : null,
    );

    if (focusNode.canRequestFocus) {
      focusNode.requestFocus();
    }

    final keypad =
        container.read(overlayNumericKeypadControllerProvider);
    keypad.openFor(controller, allowDecimal: true);
  }

  void _toggleDone(int index) {
    _focusSession();
    final container =
        riverpod.ProviderScope.containerOf(context, listen: false);
    final dayController = container.read(workoutDayControllerProvider);
    final prov = dayController.providerForKey(widget.session.key);
    if (prov == null) return;

    final ok = prov.toggleSetDone(index);
    if (!ok) {
      return;
    }

    prov.clearFocus();
    container.read(overlayNumericKeypadControllerProvider).close();
  }

  void _openDropEditor(int index) {
    _focusSession();
    final container =
        riverpod.ProviderScope.containerOf(context, listen: false);
    final dayController = container.read(workoutDayControllerProvider);
    final prov = dayController.providerForKey(widget.session.key);
    if (prov == null) return;

    // Ensure there's at least one drop slot so edits map to a concrete drop.
    prov.ensureDropSlot(index);

    setState(() {
      if (_expandedDropRows.contains(index)) {
        _expandedDropRows.remove(index);
      } else {
        _expandedDropRows.add(index);
      }
    });

    // Focus the drop weight field when opening the editor.
    _openKeypadForField(
      setIndex: index,
      field: DeviceSetFieldFocus.dropWeight,
      dropIndex: 0,
    );
  }

  void _ensureRowVisible(int index) {
    if (index < 0 || index >= _rowKeys.length) return;
    final ctx = _rowKeys[index].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.35,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _openLeaderboard(DeviceProvider prov, String? headerTitle) {
    _focusSession();
    final device = prov.device;
    if (device == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MachineLeaderboardSheet(
        gymId: widget.session.gymId,
        machineId: device.uid,
        isMulti: device.isMulti,
        title: headerTitle ?? device.name,
      ),
    );
  }

  void _openHistory(DeviceProvider prov) {
    _focusSession();
    final deviceProv = prov;

    String? exerciseName = widget.session.exerciseName;
    if (exerciseName == null && (deviceProv.device?.isMulti ?? false)) {
      final exProv =
          riverpod.ProviderScope.containerOf(context, listen: false)
              .read(exerciseProvider);
      exerciseName = exProv.exercises
          .firstWhere(
            (e) => e.id == widget.session.exerciseId,
            orElse: () => Exercise(id: '', name: 'Unknown', userId: ''),
          )
          .name;
    }

    Navigator.of(context).pushNamed(
      AppRouter.history,
      arguments: {
        'deviceId': widget.session.deviceId,
        'deviceName': deviceProv.device?.name ?? widget.session.deviceId,
        'deviceDescription': deviceProv.device?.description,
        'isMulti': deviceProv.device?.isMulti ?? false,
        if (deviceProv.device?.isMulti ?? false)
          'exerciseId': widget.session.exerciseId,
        if (deviceProv.device?.isMulti ?? false) 'exerciseName': exerciseName,
      },
    );
  }

  void _toggleBodyweight(DeviceProvider prov) {
    _focusSession();
    prov.toggleBodyweightMode();
  }

  void _handleFeedback() {
    _focusSession();
    // Use the same feedback dialog as on the device page.
    showFeedbackDialog(
      context,
      ref,
      gymId: widget.session.gymId,
      deviceId: widget.session.deviceId,
    );
  }

  void _handleRestTimerInteraction() {
    _focusSession();
    final keypad =
        riverpod.ProviderScope.containerOf(context, listen: false)
            .read(overlayNumericKeypadControllerProvider);
    if (keypad.isOpen) {
      keypad.close();
    }
  }

  Widget _buildRestTimerChip({bool inline = false}) {
    return SessionRestTimer(
      key: _rowRestTimerKey,
      initialSeconds: _restSeconds,
      onInteraction: _handleRestTimerInteraction,
      onDurationChanged: (secs) => _persistRestSeconds(secs),
      compact: true,
      inline: inline,
      showLabel: true,
    );
  }

  void _openNote(DeviceProvider prov) {
    _focusSession();
    final loc = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final textController = TextEditingController(text: prov.note);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                loc.noteModalTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: textController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: loc.noteModalHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: loc.noteDeleteTooltip,
                    onPressed: () {
                      prov.setNote('');
                      Navigator.of(ctx).pop();
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      prov.setNote(textController.text.trim());
                      Navigator.of(ctx).pop();
                    },
                    child: Text(loc.noteSaveButton),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _resolveExerciseTitle(
    DeviceProvider prov,
    AppLocalizations loc,
  ) {
    final device = prov.device;
    if (device == null) {
      return loc.newSessionTitle;
    }
    if (!device.isMulti) {
      return device.name;
    }
    if (widget.session.exerciseName != null &&
        widget.session.exerciseName!.isNotEmpty) {
      return widget.session.exerciseName!;
    }
    final availableExercises =
        riverpod.ProviderScope.containerOf(context, listen: false)
            .read(exerciseProvider)
            .exercises;
    final match =
        availableExercises.where((e) => e.id == widget.session.exerciseId);
    if (match.isNotEmpty) {
      return match.first.name;
    }
    return device.name;
  }

  String _restPrefKey() {
    final exerciseKey = widget.session.exerciseId.isNotEmpty
        ? widget.session.exerciseId
        : widget.session.deviceId;
    return 'restTimer/${widget.session.userId}/$exerciseKey';
  }

  Future<void> _loadPersistedRestSeconds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt(_restPrefKey());
      if (!mounted) return;
      setState(() => _restSeconds = stored);
      if (stored != null) {
        _rowRestTimerKey.currentState?.applyInitialSeconds(stored);
      }
    } catch (_) {
      // fail silently; timer just falls back to default
    }
  }

  Future<void> _persistRestSeconds(int seconds) async {
    setState(() => _restSeconds = seconds);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_restPrefKey(), seconds);
    } catch (_) {
      // ignore persistence failure
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final prov = _provider;
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.primary;

    if (prov.isLoading || prov.device == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 96),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final title = _resolveExerciseTitle(prov, loc);
    final deviceDescription = prov.device?.description;

    final snapshot =
        prov.sessionSnapshots.isNotEmpty ? prov.sessionSnapshots.first : null;
    late final List<SessionSetVM> lastSets;
    if (snapshot != null && snapshot.sets.isNotEmpty) {
      lastSets = mapSnapshotToVM(snapshot);
    } else {
      lastSets = mapLegacySetsToVM(prov.lastSessionSets);
    }

    // Sicherstellen, dass Controller-Liste und Provider synchron sind.
    _syncControllersFromProvider();

    // Auf Fokus-Änderungen (Navigation über das Keypad) reagieren und den
    // Keypad-Target-Controller passend umhängen.
    final focusField = prov.focusedField;
    final focusIndex = prov.focusedIndex;
    final focusRequestId = prov.focusRequestId;
    if (focusField != null &&
        focusIndex != null &&
        focusIndex >= 0 &&
        focusIndex < prov.sets.length &&
        focusRequestId != _lastFocusRequestId) {
      _lastFocusRequestId = focusRequestId;
      _ensureRowVisible(focusIndex);
      TextEditingController? controller;
      FocusNode? focusNode;
      switch (focusField) {
        case DeviceSetFieldFocus.weight:
          if (focusIndex < _weightCtrls.length) {
            controller = _weightCtrls[focusIndex];
            focusNode = _weightFocusNodes[focusIndex];
          }
          break;
        case DeviceSetFieldFocus.reps:
          if (focusIndex < _repsCtrls.length) {
            controller = _repsCtrls[focusIndex];
            focusNode = _repsFocusNodes[focusIndex];
          }
          break;
        case DeviceSetFieldFocus.dropWeight:
          final dropIndex = prov.focusedDropIndex ?? 0;
          if (focusIndex < _dropWeightCtrls.length &&
              dropIndex >= 0 &&
              dropIndex < _dropWeightCtrls[focusIndex].length) {
            controller = _dropWeightCtrls[focusIndex][dropIndex];
            focusNode = _dropWeightFocusNodes[focusIndex][dropIndex];
          }
          break;
        case DeviceSetFieldFocus.dropReps:
          final dropIndex = prov.focusedDropIndex ?? 0;
          if (focusIndex < _dropRepsCtrls.length &&
              dropIndex >= 0 &&
              dropIndex < _dropRepsCtrls[focusIndex].length) {
            controller = _dropRepsCtrls[focusIndex][dropIndex];
            focusNode = _dropRepsFocusNodes[focusIndex][dropIndex];
          }
          break;
      }
      if (controller != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (focusNode != null && focusNode.canRequestFocus) {
            focusNode.requestFocus();
          }
          final keypad = riverpod.ProviderScope.containerOf(
            context,
            listen: false,
          ).read(overlayNumericKeypadControllerProvider);
          final allowDecimal = focusField == DeviceSetFieldFocus.weight ||
              focusField == DeviceSetFieldFocus.dropWeight;
          keypad.openFor(controller!, allowDecimal: allowDecimal);
        });
      }
    }

    final cardRadius = BorderRadius.circular(28);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: cardRadius,
        border: Border.all(color: _strokeLight, width: 0.75),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header – liegt jetzt direkt auf dem Seiten-Hintergrund
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      brandColor,
                      brandColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: brandColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.displayIndex.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.05,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildRestTimerChip(inline: true),
                      ],
                    ),
                    if (deviceDescription != null &&
                        deviceDescription.trim().isNotEmpty)
                      Text(
                        deviceDescription,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: 26,
                width: 26,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  splashRadius: 16,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: Colors.white.withOpacity(0.65),
                  ),
                  onPressed: _showSessionOptions,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Swipeable content: table + actions
          _WorkoutSwipeableSessionContent(
            setsPage: _buildTableSection(
              context: context,
              loc: loc,
              prov: prov,
              lastSets: lastSets,
            ),
            actionsPage: _WorkoutActionsGrid(
              prov: prov,
              onOpenLeaderboard: prov.device == null
                  ? null
                  : () => _openLeaderboard(prov, title),
              onOpenHistory:
                  prov.device == null ? null : () => _openHistory(prov),
              onToggleBodyweight: () => _toggleBodyweight(prov),
              onFeedback: _handleFeedback,
              onOpenNote: () => _openNote(prov),
            ),
            visibleRowCount: prov.sets.length +
                prov.sets.asMap().entries.fold<int>(0, (count, entry) {
                  final idx = entry.key;
                  final drops = _dropsFromSet(entry.value);
                  if (_expandedDropRows.contains(idx) || drops.isNotEmpty) {
                    return count + (drops.isEmpty ? 1 : drops.length);
                  }
                  return count;
                }),
            trailing: null,
          ),
          const SizedBox(height: 4),
          Center(
            child: GestureDetector(
              onTap: () {
                _focusSession();
                final prov =
                    ref.read(workoutDayControllerProvider).providerForKey(
                          widget.session.key,
                        );
                if (prov == null) return;
                prov.addSet();
              },
              child: Text(
                '+ ${loc.addSetButton}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: brandColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableSection({
    required BuildContext context,
    required AppLocalizations loc,
    required DeviceProvider prov,
    required List<SessionSetVM> lastSets,
  }) {
    final sets = prov.sets;
    final theme = Theme.of(context);

    if (sets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: _cardPanelTop,
          border: Border.all(color: _strokeLight),
        ),
        child: Text(
          'Noch keine Sätze angelegt.',
          style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.72),
              ),
        ),
      );
    }

    final headerStyle = GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: Colors.white.withOpacity(0.62),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_cardPanelTop, _cardPanelBottom],
          ),
          border: Border.all(color: _strokeStrong, width: 0.9),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 16,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      'Satz',
                      style: headerStyle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Vorher',
                        style: headerStyle,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'kg',
                        style: headerStyle,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        loc.tableHeaderReps,
                        style: headerStyle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 52),
                ],
              ),
            ),
            const SizedBox(height: 2),
            for (var i = 0; i < sets.length; i++)
              () {
                final dropsForSet = _dropsFromSet(sets[i]);
                final dropExpanded = _expandedDropRows.contains(i) ||
                    dropsForSet.isNotEmpty;
                final dropRows = <_DropRowView>[
                  for (var d = 0; d < dropsForSet.length; d++)
                    _DropRowView(
                      dropIndex: d,
                      weightController: _dropWeightCtrls[i][d],
                      repsController: _dropRepsCtrls[i][d],
                      weightFocusNode: _dropWeightFocusNodes[i][d],
                      repsFocusNode: _dropRepsFocusNodes[i][d],
                      isWeightFocused:
                          prov.focusedField == DeviceSetFieldFocus.dropWeight &&
                              prov.focusedIndex == i &&
                              (prov.focusedDropIndex ?? 0) == d,
                      isRepsFocused:
                          prov.focusedField == DeviceSetFieldFocus.dropReps &&
                              prov.focusedIndex == i &&
                              (prov.focusedDropIndex ?? 0) == d,
                      onTapWeight: () {
                        _openKeypadForField(
                          setIndex: i,
                          field: DeviceSetFieldFocus.dropWeight,
                          dropIndex: d,
                        );
                      },
                      onTapReps: () {
                        _openKeypadForField(
                          setIndex: i,
                          field: DeviceSetFieldFocus.dropReps,
                          dropIndex: d,
                        );
                      },
                      onRemove: () {
                        prov.removeDropFromSet(i, d);
                        setState(() {
                          final remaining = _dropsFromSet(prov.sets[i]);
                          if (remaining.isEmpty) {
                            _expandedDropRows.remove(i);
                          }
                        });
                      },
                      showAddButton: d == dropsForSet.length - 1,
                      onAdd: () {
                        final newIndex = prov.addDropToSet(i);
                        setState(() {});
                        _openKeypadForField(
                          setIndex: i,
                          field: DeviceSetFieldFocus.dropWeight,
                          dropIndex: newIndex,
                        );
                      },
                    ),
                ];

                return Dismissible(
                  key: ValueKey(sets[i]['id'] ?? 'set-$i'),
                  direction: DismissDirection.endToStart,
                  background: const SizedBox.shrink(),
                  secondaryBackground: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    color: Colors.red.withOpacity(0.18),
                    child: const Icon(
                      Icons.delete,
                      semanticLabel: 'Löschen',
                    ),
                  ),
                  onDismissed: (_) {
                    final removed = Map<String, dynamic>.from(sets[i]);
                    setState(() {
                      final updated = <int>{};
                      for (final idx in _expandedDropRows) {
                        if (idx < i) {
                          updated.add(idx);
                        } else if (idx > i) {
                          updated.add(idx - 1);
                        }
                      }
                      _expandedDropRows
                        ..clear()
                        ..addAll(updated);
                    });
                    prov.removeSet(i);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(loc.setRemoved),
                        action: SnackBarAction(
                          label: loc.undo,
                          onPressed: () {
                            prov.insertSetAt(i, removed);
                          },
                        ),
                      ),
                    );
                  },
                  child: _WorkoutTableRow(
                    index: i,
                    set: sets[i],
                    previous: i < lastSets.length ? lastSets[i] : null,
                    isWeightFocused:
                        prov.focusedField == DeviceSetFieldFocus.weight &&
                            prov.focusedIndex == i,
                    isRepsFocused:
                        prov.focusedField == DeviceSetFieldFocus.reps &&
                            prov.focusedIndex == i,
                    dropExpanded: dropExpanded,
                    onTapWeight: () {
                      _openKeypadForField(
                        setIndex: i,
                        field: DeviceSetFieldFocus.weight,
                      );
                    },
                    onTapReps: () {
                      _openKeypadForField(
                        setIndex: i,
                        field: DeviceSetFieldFocus.reps,
                  );
                },
                onToggleDone: () => _toggleDone(i),
                onOpenDrop: () => _openDropEditor(i),
                weightController: _weightCtrls[i],
                repsController: _repsCtrls[i],
                weightFocusNode: _weightFocusNodes[i],
                repsFocusNode: _repsFocusNodes[i],
                dropRows: dropRows,
                rowKey: _rowKeys[i],
              ),
            );
          }(),
          ],
        ),
      ),
    );
  }
}

class _TableInputCell extends StatefulWidget {
  const _TableInputCell({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.placeholder,
    required this.textStyle,
    required this.onTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final String placeholder;
  final TextStyle textStyle;
  final VoidCallback onTap;

  @override
  State<_TableInputCell> createState() => _TableInputCellState();
}

class _TableInputCellState extends State<_TableInputCell> {
  bool _cursorOn = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.isFocused) {
      _startBlink();
    }
  }

  @override
  void didUpdateWidget(covariant _TableInputCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFocused != widget.isFocused) {
      if (widget.isFocused) {
        _startBlink();
      } else {
        _stopBlink();
      }
    }
  }

  @override
  void dispose() {
    _stopBlink();
    super.dispose();
  }

  void _startBlink() {
    _stopBlink();
    _cursorOn = true;
    _timer = Timer.periodic(const Duration(milliseconds: 550), (_) {
      if (!mounted) return;
      setState(() {
        _cursorOn = !_cursorOn;
      });
    });
  }

  void _stopBlink() {
    _timer?.cancel();
    _timer = null;
    _cursorOn = true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = widget.controller;
    final display =
        controller.text.trim().isEmpty ? widget.placeholder : controller.text.trim();
    final brandColor =
        theme.extension<AppBrandTheme>()?.outline ??
        theme.colorScheme.primary;
    final borderColor = widget.isFocused
        ? brandColor.withOpacity(0.7)
        : Colors.white.withOpacity(0.08);
    final fillColor = widget.isFocused
        ? brandColor.withOpacity(0.08)
        : Colors.white.withOpacity(0.02);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            bottom: BorderSide(
              color: borderColor,
              width: widget.isFocused ? 1.4 : 1.0,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (display.isNotEmpty)
              Flexible(
                child: Text(
                  display,
                  style: widget.textStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (widget.isFocused && _cursorOn)
              Padding(
                padding: const EdgeInsets.only(left: 1.5),
                child: Container(
                  width: 2.0,
                  height: (widget.textStyle.fontSize ?? 13) * 1.25,
                  decoration: BoxDecoration(
                    color: brandColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutTableRow extends StatelessWidget {
  const _WorkoutTableRow({
    required this.index,
    required this.set,
    required this.previous,
    required this.isWeightFocused,
    required this.isRepsFocused,
    required this.dropExpanded,
    required this.onTapWeight,
    required this.onTapReps,
    required this.onToggleDone,
    required this.onOpenDrop,
    required this.weightController,
    required this.repsController,
    required this.weightFocusNode,
    required this.repsFocusNode,
    required this.dropRows,
    required this.rowKey,
  });

  final int index;
  final Map<String, dynamic> set;
  final SessionSetVM? previous;
  final bool isWeightFocused;
  final bool isRepsFocused;
  final bool dropExpanded;
  final VoidCallback onTapWeight;
  final VoidCallback onTapReps;
  final VoidCallback onToggleDone;
  final VoidCallback onOpenDrop;
  final TextEditingController weightController;
  final TextEditingController repsController;
  final FocusNode weightFocusNode;
  final FocusNode repsFocusNode;
  final List<_DropRowView> dropRows;
  final GlobalKey rowKey;

  String _formatPrevious(SessionSetVM? prev) {
    if (prev == null) return '-';
    String formatNumber(num value) {
      final formatter = NumberFormat('0.##');
      return formatter.format(value);
    }

    final weightStr = prev.isBodyweight
        ? (prev.kg == 0 ? 'BW' : 'BW+${formatNumber(prev.kg)}')
        : formatNumber(prev.kg);
    return '$weightStr×${prev.reps}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColor =
        theme.extension<AppBrandTheme>()?.outline ??
        theme.colorScheme.primary;

    final doneVal = set['done'];
    final done = doneVal == true || doneVal == 'true';

    final textStyle = GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Colors.white.withOpacity(0.9),
    );

    final secondaryStyle = textStyle.copyWith(
      color: Colors.white.withOpacity(0.65),
    );

    final rowBg = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [_rowBgStart, _rowBgEnd],
    );

    return Container(
      key: rowKey,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 0.5),
      decoration: BoxDecoration(
        gradient: rowBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _strokeLight, width: 0.6),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '${index + 1}',
                  style: secondaryStyle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: Text(
                  _formatPrevious(previous),
                  style: secondaryStyle,
                ),
              ),
              Expanded(
                flex: 2,
                child: _TableInputCell(
                  controller: weightController,
                  focusNode: weightFocusNode,
                  isFocused: isWeightFocused,
                  // Keine horizontale Linie im Eingabefeld – leer lassen.
                  placeholder: '',
                  textStyle: textStyle,
                  onTap: onTapWeight,
                ),
              ),
              Expanded(
                flex: 2,
                child: _TableInputCell(
                  controller: repsController,
                  focusNode: repsFocusNode,
                  isFocused: isRepsFocused,
                  placeholder: '',
                  textStyle: textStyle,
                  onTap: onTapReps,
                ),
              ),
              const SizedBox(width: 6),
              _WorkoutRoundButton(
                icon: dropExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                semantics: 'Dropsätze',
                filled: false,
                color: brandColor,
                onTap: onOpenDrop,
              ),
              const SizedBox(width: 6),
              _WorkoutRoundButton(
                icon: Icons.check_rounded,
                semantics: 'Satz erledigt',
                filled: done,
                color: brandColor,
                onTap: onToggleDone,
              ),
            ],
          ),
          if (dropExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                children: [
                  for (var i = 0; i < dropRows.length; i++) ...[
                    if (i > 0) const SizedBox(height: 4),
                    _buildDropRow(
                      dropRows[i],
                      index,
                      secondaryStyle,
                      textStyle,
                      brandColor,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropRow(
    _DropRowView drop,
    int setIndex,
    TextStyle secondaryStyle,
    TextStyle textStyle,
    Color brandColor,
  ) {
    return Dismissible(
      key: ValueKey('drop-row-$setIndex-${drop.dropIndex}'),
      direction: DismissDirection.endToStart,
      background: const SizedBox.shrink(),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.red.withOpacity(0.18),
        child: const Icon(
          Icons.delete,
          semanticLabel: 'Dropsatz löschen',
        ),
      ),
      onDismissed: (_) => drop.onRemove(),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '↘︎',
              style: secondaryStyle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              '-',
              style: secondaryStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: _TableInputCell(
              controller: drop.weightController,
              focusNode: drop.weightFocusNode,
              isFocused: drop.isWeightFocused,
              placeholder: '',
              textStyle: textStyle,
              onTap: drop.onTapWeight,
            ),
          ),
          Expanded(
            flex: 2,
            child: _TableInputCell(
              controller: drop.repsController,
              focusNode: drop.repsFocusNode,
              isFocused: drop.isRepsFocused,
              placeholder: '',
              textStyle: textStyle,
              onTap: drop.onTapReps,
            ),
          ),
          const SizedBox(width: 4),
          if (drop.showAddButton)
            _WorkoutRoundButton(
              icon: Icons.add,
              semantics: 'Dropsatz hinzufügen',
              filled: false,
              color: brandColor,
              onTap: drop.onAdd,
            )
          else
            const SizedBox(width: 30, height: 30),
          const SizedBox(width: 4),
          const SizedBox(width: 30, height: 30),
        ],
      ),
    );
  }
}

class _DropRowView {
  const _DropRowView({
    required this.dropIndex,
    required this.weightController,
    required this.repsController,
    required this.weightFocusNode,
    required this.repsFocusNode,
    required this.isWeightFocused,
    required this.isRepsFocused,
    required this.onTapWeight,
    required this.onTapReps,
    required this.onRemove,
    required this.showAddButton,
    required this.onAdd,
  });

  final int dropIndex;
  final TextEditingController weightController;
  final TextEditingController repsController;
  final FocusNode weightFocusNode;
  final FocusNode repsFocusNode;
  final bool isWeightFocused;
  final bool isRepsFocused;
  final VoidCallback onTapWeight;
  final VoidCallback onTapReps;
  final VoidCallback onRemove;
  final bool showAddButton;
  final VoidCallback onAdd;
}

class _WorkoutRoundButton extends StatefulWidget {
  const _WorkoutRoundButton({
    required this.icon,
    required this.semantics,
    required this.filled,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String semantics;
  final bool filled;
  final Color color;
  final VoidCallback? onTap;

  @override
  State<_WorkoutRoundButton> createState() => _WorkoutRoundButtonState();
}

class _WorkoutRoundButtonState extends State<_WorkoutRoundButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final size = 32.0;
    final scale = _pressed ? 0.95 : 1.0;

    final isEnabled = widget.onTap != null;
    final isFilled = widget.filled;

    final bgColor = isFilled
        ? widget.color
        : (isEnabled
            ? Colors.white.withOpacity(0.12)
            : Colors.white.withOpacity(0.06));

    final iconColor = isFilled
        ? Colors.white
        : (isEnabled
            ? Colors.white
            : Colors.white.withOpacity(0.4));

    return Semantics(
      label: widget.semantics,
      button: true,
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            isEnabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size / 2),
              color: bgColor,
              boxShadow: isFilled
                  ? [
                      BoxShadow(
                        color: widget.color.withOpacity(0.5),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
              border: isFilled
                  ? null
                  : Border.all(
                      color: Colors.white.withOpacity(
                        isEnabled ? 0.12 : 0.06,
                      ),
                    ),
            ),
            child: Icon(
              widget.icon,
              color: iconColor,
              size: size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkoutSwipeableSessionContent extends StatefulWidget {
  const _WorkoutSwipeableSessionContent({
    required this.setsPage,
    required this.actionsPage,
    required this.visibleRowCount,
    this.trailing,
  });

  final Widget setsPage;
  final Widget actionsPage;
  final int visibleRowCount;
  final Widget? trailing;

  @override
  State<_WorkoutSwipeableSessionContent> createState() =>
      _WorkoutSwipeableSessionContentState();
}

class _WorkoutSwipeableSessionContentState
    extends State<_WorkoutSwipeableSessionContent>
    with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  double _dragAccum = 0;

  void _goToPage(int target) {
    if (target == _currentPage) return;
    setState(() {
      _currentPage = target;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColor =
        theme.extension<AppBrandTheme>()?.outline ??
        theme.colorScheme.secondary;

    const rowHeight = 36.0;
    const baseHeight = 70.0;
    final setsHeight =
        baseHeight + widget.visibleRowCount.clamp(1, 20) * rowHeight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _goToPage(_currentPage == 0 ? 1 : 0),
                onHorizontalDragStart: (_) => _dragAccum = 0,
                onHorizontalDragUpdate: (details) {
                  _dragAccum += details.delta.dx;
                  const threshold = 24.0;
                  if (_dragAccum.abs() >= threshold) {
                    _goToPage(_dragAccum < 0 ? 1 : 0);
                    _dragAccum = 0;
                  }
                },
                onHorizontalDragEnd: (_) => _dragAccum = 0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 18, minWidth: 88),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _WorkoutPageIndicator(
                        isActive: _currentPage == 0,
                        color: brandColor,
                      ),
                      const SizedBox(width: 8),
                      _WorkoutPageIndicator(
                        isActive: _currentPage == 1,
                        color: brandColor,
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.trailing != null)
                Positioned(
                  right: 0,
                  child: widget.trailing!,
                ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: _currentPage == 0 ? setsHeight : 240,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              transitionBuilder: (child, animation) {
                final offsetTween = Tween<Offset>(
                  begin: Offset(_currentPage == 0 ? -0.06 : 0.06, 0),
                  end: Offset.zero,
                );
                return SlideTransition(
                  position: offsetTween.animate(animation),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: _currentPage == 0
                  ? KeyedSubtree(
                      key: const ValueKey('sets'),
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: widget.setsPage,
                      ),
                    )
                  : KeyedSubtree(
                      key: const ValueKey('actions'),
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: widget.actionsPage,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkoutPageIndicator extends StatelessWidget {
  const _WorkoutPageIndicator({
    required this.isActive,
    required this.color,
  });

  final bool isActive;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? color : color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _WorkoutActionsGrid extends StatelessWidget {
  const _WorkoutActionsGrid({
    required this.prov,
    this.onOpenLeaderboard,
    this.onOpenHistory,
    this.onToggleBodyweight,
    this.onFeedback,
    this.onOpenNote,
  });

  final DeviceProvider prov;
  final VoidCallback? onOpenLeaderboard;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onToggleBodyweight;
  final VoidCallback? onFeedback;
  final VoidCallback? onOpenNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColor =
        theme.extension<AppBrandTheme>()?.outline ??
        theme.colorScheme.secondary;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
        children: [
          if (onOpenLeaderboard != null)
            _WorkoutActionGridButton(
              icon: Icons.emoji_events_rounded,
              label: 'Bestenliste',
              color: brandColor,
              onTap: onOpenLeaderboard!,
            ),
          if (onOpenHistory != null)
            _WorkoutActionGridButton(
              icon: Icons.history_rounded,
              label: 'Verlauf',
              color: brandColor,
              onTap: onOpenHistory!,
            ),
          if (onToggleBodyweight != null)
            _WorkoutActionGridButton(
              icon: Icons.accessibility_new_rounded,
              label: 'Körpergewicht',
              color: brandColor,
              onTap: onToggleBodyweight!,
              isActive: prov.isBodyweightMode,
            ),
          _WorkoutActionGridButton(
            icon: Icons.military_tech_rounded,
            label: 'Level ${prov.level}',
            subtitle: '${prov.xp} XP',
            color: brandColor,
            onTap: () {},
          ),
          if (onFeedback != null)
            _WorkoutActionGridButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Feedback',
              color: brandColor,
              onTap: onFeedback!,
            ),
          _WorkoutActionGridButton(
            icon: Icons.edit_note_rounded,
            label: 'Notiz',
            color: brandColor,
            isActive: prov.note.isNotEmpty,
            onTap: onOpenNote ?? () {},
          ),
        ],
      ),
    );
  }
}

class _WorkoutActionGridButton extends StatelessWidget {
  const _WorkoutActionGridButton({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceColor = Colors.black.withOpacity(0.4);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.2) : surfaceColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isActive
                  ? color.withOpacity(0.6)
                  : Colors.white.withOpacity(0.08),
              width: 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isActive
                  ? [
                      color.withOpacity(0.3),
                      color.withOpacity(0.1),
                    ]
                  : [
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.02),
                    ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? color
                      : Colors.white.withOpacity(0.05),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.6),
                            blurRadius: 12,
                            offset: const Offset(0, 0),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isActive
                      ? Colors.white
                      : Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isActive
                      ? Colors.white
                      : Colors.white.withOpacity(0.7),
                  fontWeight:
                      isActive ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isActive
                        ? Colors.white.withOpacity(0.9)
                        : Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
