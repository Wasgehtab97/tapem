import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:google_fonts/google_fonts.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/config/feature_flags.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/time/logic_day.dart';
import 'package:tapem/core/widgets/brand_outline.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/device/presentation/models/session_set_vm.dart';
import 'package:tapem/features/device/presentation/widgets/last_session_card.dart';
import 'package:tapem/features/device/presentation/widgets/machine_leaderboard_sheet.dart';
import 'package:tapem/features/device/presentation/widgets/note_button_widget.dart';
import 'package:tapem/features/device/presentation/widgets/session_action_button_style.dart';
import 'package:tapem/features/device/presentation/widgets/session_action_strip.dart';
import 'package:tapem/features/device/presentation/widgets/set_card.dart';
import 'package:tapem/features/device/providers/device_riverpod.dart';
import 'package:tapem/features/device/providers/exercise_provider.dart';
import 'package:tapem/features/device/providers/workout_day_controller_provider.dart';
import 'package:tapem/features/rank/presentation/device_level_style.dart';
import 'package:tapem/features/rank/presentation/widgets/xp_info_button.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';
import 'package:tapem/features/feedback/presentation/widgets/feedback_button.dart'
    show showFeedbackDialog;



class DeviceSessionSection extends StatelessWidget {
  const DeviceSessionSection({
    super.key,
    required this.provider,
    required this.gymId,
    required this.deviceId,
    required this.exerciseId,
    required this.userId,
    this.displayIndex = 1,
    this.sessionKey,
    this.exerciseName,

    this.onSessionSaved,
    this.onCloseRequested,
  });

  final DeviceProvider provider;
  final String gymId;
  final String deviceId;
  final String exerciseId;
  final String? exerciseName;
  final String userId;
  final int displayIndex;
  final String? sessionKey;

  final VoidCallback? onSessionSaved;
  final VoidCallback? onCloseRequested;

  @override
  Widget build(BuildContext context) {
    return _DeviceSessionSectionBody(
      provider: provider,
      gymId: gymId,
      deviceId: deviceId,
      exerciseId: exerciseId,
      userId: userId,
      displayIndex: displayIndex,
      sessionKey: sessionKey,
      exerciseName: exerciseName,
      onSessionSaved: onSessionSaved,
      onCloseRequested: onCloseRequested,
    );
  }
}

class _DeviceSessionSectionBody extends riverpod.ConsumerStatefulWidget {
  const _DeviceSessionSectionBody({
    required this.provider,
    required this.gymId,
    required this.deviceId,
    required this.exerciseId,
    required this.userId,
    required this.displayIndex,
    this.sessionKey,
    this.exerciseName,

    this.onSessionSaved,
    this.onCloseRequested,
  });

  final DeviceProvider provider;
  final String gymId;
  final String deviceId;
  final String exerciseId;
  final String? exerciseName;
  final String userId;
  final int displayIndex;
  final String? sessionKey;

  final VoidCallback? onSessionSaved;
  final VoidCallback? onCloseRequested;

  @override
  riverpod.ConsumerState<_DeviceSessionSectionBody> createState() => _DeviceSessionSectionBodyState();
}

class _DeviceSessionSectionBodyState extends riverpod.ConsumerState<_DeviceSessionSectionBody> {
  final _formKey = GlobalKey<FormState>();
  final List<GlobalKey<SetCardState>> _setKeys = [];
  OverlayNumericKeypadController? _keypadController;
  bool _didLoad = false;
  OverlayNumericKeypadController get _overlayKeypad =>
      _keypadController ??
      riverpod.ProviderScope.containerOf(context, listen: false)
          .read(overlayNumericKeypadControllerProvider);

  @override
  void initState() {
    super.initState();
    widget.provider.addListener(_handleProviderChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _keypadController ??=
        riverpod.ProviderScope.containerOf(context, listen: false)
            .read(overlayNumericKeypadControllerProvider);
    _ensureSessionLoaded();
  }

  void _handleProviderChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _ensureSessionLoaded() async {
    if (_didLoad) return;
    _didLoad = true;
    final container = riverpod.ProviderScope.containerOf(context, listen: false);
    final auth = container.read(authControllerProvider);
    final settings = container.read(settingsProvider);
    await settings.load(auth.userId!);
    await widget.provider.loadDevice(
      gymId: widget.gymId,
      deviceId: widget.deviceId,
      exerciseId: widget.exerciseId,
      userId: widget.userId,
    );

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  void _addSet() {
    _focusSession();
    final prov = widget.provider;
    prov.addSet();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final index = prov.sets.length - 1;
      if (index >= 0 && index < _setKeys.length) {
        final key = _setKeys[index];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = key.currentContext;
          if (ctx != null) {
            Scrollable.ensureVisible(
              ctx,
              alignment: 0.5,
              duration: const Duration(milliseconds: 200),
            );
          }
        });
      }
    });
  }

  void _closeKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
    _overlayKeypad.close();
  }

  void _focusSession() {
    final key = widget.sessionKey;
    if (key != null) {
      riverpod.ProviderScope.containerOf(context, listen: false)
          .read(workoutDayControllerProvider)
          .focusSession(key);
    }
  }

  void _openLeaderboard(DeviceProvider prov, String? headerTitle) {
    _focusSession();
    final device = prov.device;
    if (device == null) return;
    _closeKeyboard();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MachineLeaderboardSheet(
        gymId: widget.gymId,
        machineId: device.uid,
        isMulti: device.isMulti,
        title: headerTitle ?? device.name,
      ),
    );
  }

  void _openHistory(DeviceProvider prov) {
    _focusSession();
    _closeKeyboard();
    final deviceProv = prov;
    String? exerciseName = widget.exerciseName;
    if (exerciseName == null && (deviceProv.device?.isMulti ?? false)) {
      final exProv = riverpod.ProviderScope.containerOf(context, listen: false)
          .read(exerciseProvider);
      exerciseName = exProv.exercises
          .firstWhere(
            (e) => e.id == widget.exerciseId,
            orElse: () => Exercise(id: '', name: 'Unknown', userId: ''),
          )
          .name;
    }
    Navigator.of(context).pushNamed(
      AppRouter.history,
      arguments: {
        'deviceId': widget.deviceId,
        'deviceName': deviceProv.device?.name ?? widget.deviceId,
        'deviceDescription': deviceProv.device?.description,
        'isMulti': deviceProv.device?.isMulti ?? false,
        if (deviceProv.device?.isMulti ?? false) 'exerciseId': widget.exerciseId,
        if (deviceProv.device?.isMulti ?? false) 'exerciseName': exerciseName,
      },
    );
  }

  void _toggleBodyweight(DeviceProvider prov) {
    _focusSession();
    prov.toggleBodyweightMode();
    elogUi('bodyweight_toggle', {
      'enabled': prov.isBodyweightMode,
      'deviceId': widget.deviceId,
      'exerciseId': widget.exerciseId,
    });
  }

  void _handleFeedback() {
    _focusSession();
    _closeKeyboard();
    unawaited(
      showFeedbackDialog(
        context,
        ref,
        gymId: widget.gymId,
        deviceId: widget.deviceId,
      ),
    );
  }

  void _openNote(DeviceProvider prov) {
    _focusSession();
    _closeKeyboard();
    final loc = AppLocalizations.of(context)!;
    showModalBottomSheet(
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

  String? _resolveExerciseTitle(
    BuildContext context,
    DeviceProvider prov, {
    List<Exercise>? exercises,
  }) {
    final device = prov.device;
    if (device == null) {
      return null;
    }
    if (!device.isMulti) {
      return device.name;
    }
    if (widget.exerciseName != null && widget.exerciseName!.isNotEmpty) {
      return widget.exerciseName;
    }
    final availableExercises =
        exercises ??
        riverpod.ProviderScope.containerOf(context, listen: false)
            .read(exerciseProvider)
            .exercises;
    final match = availableExercises.where((e) => e.id == widget.exerciseId);
    if (match.isNotEmpty) {
      return match.first.name;
    }
    return device.name;
  }




  Widget _buildEditablePage(
    DeviceProvider prov,
    AppLocalizations loc,
  ) {
    final theme = Theme.of(context);
    final outlineColor =
        theme.extension<AppBrandTheme>()?.outline ?? theme.colorScheme.secondary;
    final exercises = prov.device?.isMulti ?? false
        ? riverpod.ProviderScope.containerOf(context)
            .read(exerciseProvider)
            .exercises
        : null;
    final exerciseTitle = _resolveExerciseTitle(
      context,
      prov,
      exercises: exercises,
    );

    while (_setKeys.length < prov.sets.length) {
      _setKeys.add(GlobalKey<SetCardState>());
    }
    if (_setKeys.length > prov.sets.length) {
      _setKeys.removeRange(prov.sets.length, _setKeys.length);
    }
    final snapshot =
        prov.sessionSnapshots.isNotEmpty ? prov.sessionSnapshots.first : null;
    late final List<SessionSetVM> lastSets;
    DateTime? lastDate;
    late final String? lastNote;
    if (snapshot != null && snapshot.sets.isNotEmpty) {
      lastSets = mapSnapshotToVM(snapshot);
      lastDate = snapshot.createdAt;
      lastNote = snapshot.note;
    } else {
      lastSets = mapLegacySetsToVM(prov.lastSessionSets);
      lastDate = prov.lastSessionDate;
      lastNote = prov.lastSessionNote;
    }

    final resolvedTitle = exerciseTitle ?? loc.newSessionTitle;

    // Build sets content
    final setsContent = <Widget>[
      if (prov.sets.isNotEmpty) ...[
        const SizedBox(height: 6),
        _GroupedSetList(
          sets: prov.sets,
          setKeys: _setKeys,
          sessionKey: widget.sessionKey,
          previousSets: lastSets,
          onRemove: (index, removed) {
            _focusSession();
            prov.removeSet(index);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loc.setRemoved),
                action: SnackBarAction(
                  label: loc.undo,
                  onPressed: () {
                    _focusSession();
                    prov.insertSetAt(index, removed);
                  },
                ),
              ),
            );
          },
        ),
      ],
      if (prov.sets.isEmpty) const SizedBox(height: 8),
      Align(
        alignment: Alignment.center,
        child: _AddSetButton(
          label: loc.addSetButton,
          onPressed: _addSet,
        ),
      ),
      if ((FF.showLastSessionOnDevicePage ||
              FF.runtimeShowLastSessionOnDevicePage) &&
          lastDate != null &&
          lastSets.isNotEmpty) ...[
        const SizedBox(height: 12),
        LastSessionCard(
          date: lastDate,
          sets: lastSets,
          note: lastNote,
        ),
      ],
    ];

    // Build save button
    final saveButton = widget.onSessionSaved != null
        ? <Widget>[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: prov.hasSessionToday || prov.isSaving
                  ? null
                  : () => _saveSession(prov, loc),
              child: prov.isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(outlineColor),
                      ),
                    )
                  : Text(loc.saveButton),
            ),
          ]
        : <Widget>[];

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            _SwipeableSessionContent(
              setsPage: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...setsContent,
                  ...saveButton,
                ],
              ),
              actionsPage: _StylishActionsGrid(
                onOpenLeaderboard: prov.device == null
                    ? null
                    : () => _openLeaderboard(prov, resolvedTitle),
                onOpenHistory: prov.device == null ? null : () => _openHistory(prov),
                onToggleBodyweight: () => _toggleBodyweight(prov),
                onFeedback: () => _handleFeedback(),
                onOpenNote: () => _openNote(prov),
                isBodyweightMode: prov.isBodyweightMode,
                xp: prov.xp,
                level: prov.level,
                deviceId: widget.deviceId,
                hasNote: prov.note.isNotEmpty,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSession(
    DeviceProvider prov,
    AppLocalizations loc,
  ) async {
    _focusSession();
    final container = riverpod.ProviderScope.containerOf(context, listen: false);
    final auth = container.read(authControllerProvider);
    final base = {
      'uid': auth.userId!,
      'gymId': widget.gymId,
      'deviceId': widget.deviceId,
      'isMulti': prov.device?.isMulti ?? false,
      'screen': 'DeviceSessionSection',
      'dayKey': logicDayKey(DateTime.now()),
    };
    elogUi('CLICK_SAVE', base);
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.pleaseCheckInputs),
        ),
      );
      return;
    }
    final counts = prov.getSetCounts();
    final totalFilled = counts.done + counts.filledNotDone;
    if (counts.filledNotDone > 0) {
      elogUi('SAVE_OPEN_SETS_DIALOG', {
        'doneCount': counts.done,
        'filledNotDoneCount': counts.filledNotDone,
        'emptyOrIncompleteCount': counts.emptyOrIncomplete,
      });
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(loc.notAllSetsConfirmed),
          content: Text(loc.notAllSetsConfirmed),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(loc.cancelButton),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(loc.confirmAllSets),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      final added = prov.completeAllFilledNotDone();
      elogUi('CONFIRM_ALL_SETS', {
        'completedCount': added,
      });
      if (prov.completedCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.noCompletedSets)),
        );
        return;
      }
    } else if (totalFilled == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.noCompletedSets)),
      );
      return;
    }
    elogUi('SAVE_STARTED', base);
    final settingsProv = container.read(settingsProvider);
    final ok = await prov.saveWorkoutSession(
      gymId: widget.gymId,
      userId: auth.userId!,
      showInLeaderboard: auth.showInLeaderboard ?? true,
      userName: auth.userName,
      gender: settingsProv.gender,
      bodyWeightKg: settingsProv.bodyWeightKg,

    );
    final sessionId = prov.lastSessionId;
    if (!ok) {
      elogUi('SAVE_PERSIST_ERROR', {
        ...base,
        if (sessionId != null) 'sessionId': sessionId,
        'reason': prov.error ?? 'unknown',
      });
      final msg = prov.error ?? 'Speichern fehlgeschlagen.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
      elogUi('SAVE_DONE', {
        ...base,
        if (sessionId != null) 'sessionId': sessionId,
        'result': 'error',
      });
      return;
    }
    elogUi('SAVE_DONE', {
      ...base,
      if (sessionId != null) 'sessionId': sessionId,
      'result': 'ok',
    });
    if (!mounted) {
      return;
    }
    final message = prov.device?.isMulti == true
        ? loc.multiDeviceSessionSaved
        : loc.sessionSaved;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    _closeKeyboard();
    widget.onSessionSaved?.call();
  }

  Widget _buildContent(BuildContext context, DeviceProvider prov) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final outlineColor =
        theme.extension<AppBrandTheme>()?.outline ?? theme.colorScheme.secondary;
    if (prov.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 96),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (prov.error != null || prov.device == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: outlineColor),
            const SizedBox(height: 12),
            Text(
              prov.error ?? loc.deviceNotFound,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }



    return _buildEditablePage(prov, loc);
  }

  @override
  void dispose() {
    widget.provider.removeListener(_handleProviderChanged);
    FocusManager.instance.primaryFocus?.unfocus();
    // Das globale Keypad wird zentral verwaltet.
    // Hier kein direktes close(), um Provider-Änderungen während dispose()
    // und entsprechende Riverpod-Assertions zu vermeiden.
    super.dispose();
  }

  Widget _buildHeader(BuildContext context, DeviceProvider prov) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.primary;
    final exercises = prov.device?.isMulti ?? false
        ? riverpod.ProviderScope.containerOf(context, listen: false)
            .read(exerciseProvider)
            .exercises
        : null;
    final resolvedTitle =
        _resolveExerciseTitle(context, prov, exercises: exercises) ??
            loc.newSessionTitle;
    final deviceDescription = prov.device?.description;

    final showClose = widget.onCloseRequested != null;
    final counts = prov.getSetCounts();
    final canClose = widget.onCloseRequested != null && counts.done == 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          // Premium Index Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  brandColor,
                  brandColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: brandColor.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              widget.displayIndex.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Title + optional description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resolvedTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (deviceDescription != null &&
                    deviceDescription.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    deviceDescription,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Close Button
          if (showClose)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: canClose
                    ? () {
                        _closeKeyboard();
                        widget.onCloseRequested?.call();
                      }
                    : null,
                borderRadius: BorderRadius.circular(50),
                child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.close,
                      color: Colors.white.withOpacity(0.6),
                    )),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final container = riverpod.ProviderScope.containerOf(context);
    final prov = widget.provider;
    final auth = container.read(authControllerProvider);
    prov.updateAutoSavePreference(auth.showInLeaderboard ?? true);

    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.primary;

    final hasScrollableParent = Scrollable.maybeOf(context) != null;
    final content = _buildContent(context, prov);
    final Widget wrappedContent = hasScrollableParent
        ? content
        : SingleChildScrollView(
            padding: EdgeInsets.zero,
            clipBehavior: Clip.none,
            child: content,
          );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.canvasColor.withOpacity(0.9), // Darker base
            Color.alphaBlend(
              brandColor.withOpacity(0.05),
              theme.canvasColor,
            ),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, prov),
            // Premium Separator (Subtle Gradient Line)
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            wrappedContent,
             const SizedBox(height: 12), // Bottom padding
          ],
        ),
      ),
    );
  }
}

class _AddSetButton extends StatelessWidget {
  const _AddSetButton({
    required this.onPressed,
    required this.label,
  });

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor =
        theme.extension<AppBrandTheme>()?.outline ?? theme.colorScheme.secondary;
    final baseTextStyle = theme.textTheme.titleMedium ??
        const TextStyle(
          fontSize: AppFontSizes.title,
          fontWeight: FontWeight.w600,
        );
    final textStyle = baseTextStyle.copyWith(color: accentColor);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xs,
            horizontal: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: accentColor, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(label, style: textStyle),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupedSetList extends StatelessWidget {
  const _GroupedSetList({
    required this.sets,
    required this.setKeys,
    required this.onRemove,
    required this.sessionKey,
    required this.previousSets,
  });

  final List<Map<String, dynamic>> sets;
  final List<GlobalKey<SetCardState>> setKeys;
  final void Function(int index, Map<String, dynamic> removed) onRemove;
  final String? sessionKey;
  final List<SessionSetVM> previousSets;

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrandTheme>();
    final loc = AppLocalizations.of(context)!;
    final isBodyweightMode = sets.isNotEmpty &&
        (sets.first['isBodyweight'] == true);
    var tokens = SetCardTheme.of(context);
    const dense = true;
    if (dense) {
      tokens = tokens.copyWith(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      );
    }
    final outlineRadius = (brand?.outlineRadius as BorderRadius?) ??
        BorderRadius.circular(AppRadius.card);
    final outlineWidth = brand?.outlineWidth ?? 2;
    final innerRadius = outlineRadius - BorderRadius.circular(outlineWidth);

    bool dropActiveFor(Map<String, dynamic> set) {
      final rawDrops = set['drops'];
      if (rawDrops is List) {
        for (final drop in rawDrops) {
          if (drop is Map) {
            final weight = (drop['weight'] ?? drop['kg'] ?? '').toString().trim();
            final reps = (drop['reps'] ?? drop['wdh'] ?? '').toString().trim();
            if (weight.isNotEmpty && reps.isNotEmpty) {
              return true;
            }
          }
        }
      }
      final dropWeight = (set['dropWeight'] ?? '').toString().trim();
      final dropReps = (set['dropReps'] ?? '').toString().trim();
      return dropWeight.isNotEmpty && dropReps.isNotEmpty;
    }

    final header = sets.isEmpty
        ? null
        : _SetListFieldHeader(
            tokens: tokens,
            dense: dense,
            dropActive: dropActiveFor(sets.first),
            // Nur "kg" als Spaltenbeschriftung, direkt über dem KG-Feld.
            weightLabel: isBodyweightMode ? 'BW' : 'kg',
            repsLabel: loc.tableHeaderReps,
          );

    return BrandOutline(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null) header,
          ...sets.asMap().entries.map(
            (entry) => _buildSetItem(
              context: context,
              index: entry.key,
              set: entry.value,
              innerRadius: innerRadius,
              sessionKey: sessionKey,
              previous: entry.key < previousSets.length
                  ? previousSets[entry.key]
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetItem({
    required BuildContext context,
    required int index,
    required Map<String, dynamic> set,
    required BorderRadius innerRadius,
    required String? sessionKey,
    SessionSetVM? previous,
  }) {
    return Dismissible(
      key: ValueKey(set['id'] ?? 'set-${set['number']}'),
      direction: DismissDirection.endToStart,
      background: const SizedBox.shrink(),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.red.withOpacity(0.15),
        child: const Icon(
          Icons.delete,
          semanticLabel: 'Löschen',
        ),
      ),
      onDismissed: (_) {
        final removedSource = index < sets.length ? sets[index] : set;
        final removed = Map<String, dynamic>.from(removedSource);
        onRemove(index, removed);
      },
      child: SetCard(
        key: setKeys[index],
        index: index,
        set: set,
        size: SetCardSize.dense,
        displayMode: SetCardDisplayMode.grouped,
        sessionKey: sessionKey,
        previousSet: previous,
        groupedRadius: BorderRadius.only(
          topLeft: index == 0 ? innerRadius.topLeft : Radius.zero,
          topRight: index == 0 ? innerRadius.topRight : Radius.zero,
          bottomLeft: index == sets.length - 1 ? innerRadius.bottomLeft : Radius.zero,
          bottomRight:
              index == sets.length - 1 ? innerRadius.bottomRight : Radius.zero,
        ),
      ),
    );
  }
}

class _SetListFieldHeader extends StatelessWidget {
  const _SetListFieldHeader({
    required this.tokens,
    required this.dense,
    required this.dropActive,
    required this.weightLabel,
    required this.repsLabel,
  });

  final SetCardTheme tokens;
  final bool dense;
  final bool dropActive;
  final String weightLabel;
  final String repsLabel;

  @override
  Widget build(BuildContext context) {
    final headerStyle = GoogleFonts.inter(
      fontSize: dense ? 11 : 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: tokens.chipFg.withOpacity(0.78),
    );
    // Index-Badge (feste Breite) + Abstand.
    final double indexBadgeWidth = dense ? 28.0 : 32.0;
    final double indexBadgeGap = dense ? 6.0 : 9.0;
    final double leadingWidth = indexBadgeWidth + indexBadgeGap;
    final double colGap = dense ? 4.0 : 6.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.padding.left,
        tokens.padding.top,
        tokens.padding.right,
        dense ? 6 : 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(width: leadingWidth),
          // Nur "Vorher" in der Kopfzeile – Spaltenlabels für kg/Wdh.
          // entfallen, da die Felder eigene Platzhalter haben.
          Flexible(
            flex: 2,
            child: Text(
              'Vorher',
              style: headerStyle,
            ),
          ),
          const Spacer(flex: 3),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

/// Swipeable content with two pages: sets view and actions view
class _SwipeableSessionContent extends StatefulWidget {
  const _SwipeableSessionContent({
    required this.setsPage,
    required this.actionsPage,
  });

  final Widget setsPage;
  final Widget actionsPage;

  @override
  State<_SwipeableSessionContent> createState() => _SwipeableSessionContentState();
}

class _SwipeableSessionContentState extends State<_SwipeableSessionContent> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColor = theme.extension<AppBrandTheme>()?.outline ?? 
        theme.colorScheme.secondary;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Page Indicators
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PageIndicator(
                isActive: _currentPage == 0,
                color: brandColor,
              ),
              const SizedBox(width: 8),
              _PageIndicator(
                isActive: _currentPage == 1,
                color: brandColor,
              ),
            ],
          ),
        ),
        // PageView with page-specific height
        SizedBox(
          height: _currentPage == 0 ? 280 : 250,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              // Page 1: Sets View - compact
              SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: widget.setsPage,
              ),
              // Page 2: Actions View - grid fits perfectly
              SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: widget.actionsPage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Simple circular page indicator
class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.isActive,
    required this.color,
  });

  final bool isActive;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? color : color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Stylish grid layout for action buttons
class _StylishActionsGrid extends StatelessWidget {
  const _StylishActionsGrid({
    this.onOpenLeaderboard,
    this.onOpenHistory,
    this.onToggleBodyweight,
    this.onFeedback,
    this.onOpenNote,
    required this.isBodyweightMode,
    required this.xp,
    required this.level,
    required this.deviceId,
    this.hasNote = false,
  });

  final VoidCallback? onOpenLeaderboard;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onToggleBodyweight;
  final VoidCallback? onFeedback;
  final VoidCallback? onOpenNote;
  final bool isBodyweightMode;
  final int xp;
  final int level;
  final String deviceId;
  final bool hasNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColor = theme.extension<AppBrandTheme>()?.outline ?? 
        theme.colorScheme.secondary;
    final loc = AppLocalizations.of(context)!;

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
            _ActionGridButton(
              icon: Icons.emoji_events_rounded,
              label: 'Bestenliste',
              color: brandColor,
              onTap: onOpenLeaderboard!,
            ),
          if (onOpenHistory != null)
            _ActionGridButton(
              icon: Icons.history_rounded,
              label: 'Verlauf',
              color: brandColor,
              onTap: onOpenHistory!,
            ),
          if (onToggleBodyweight != null)
            _ActionGridButton(
              icon: Icons.accessibility_new_rounded,
              label: 'Körpergewicht',
              color: brandColor,
              onTap: onToggleBodyweight!,
              isActive: isBodyweightMode,
            ),
          _ActionGridButton(
            icon: Icons.military_tech_rounded,
            label: 'Level $level',
            subtitle: '$xp XP',
            color: brandColor,
            onTap: () {
              // XP info - could show details
            },
          ),
          if (onFeedback != null)
            _ActionGridButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Feedback',
              color: brandColor,
              onTap: onFeedback!,
            ),
          _ActionGridButton(
            icon: Icons.edit_note_rounded,
            label: 'Notiz',
            color: brandColor,
            isActive: hasNote,
            onTap: onOpenNote ?? () {},
          ),
        ],
      ),
    );
  }
}

/// Individual action button for the grid
class _ActionGridButton extends StatelessWidget {
  const _ActionGridButton({
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
    // Dark surface color for premium look
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
              // Glowing Icon Container
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
                  color: isActive ? Colors.white : Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
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
