import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/config/feature_flags.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/providers/exercise_provider.dart';
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/core/providers/training_plan_provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/time/logic_day.dart';
import 'package:tapem/core/widgets/brand_outline.dart';
import 'package:tapem/core/widgets/brand_outline_button.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/device/presentation/models/session_set_vm.dart';
import 'package:tapem/features/device/presentation/widgets/device_pager.dart';
import 'package:tapem/features/device/presentation/widgets/last_session_card.dart';
import 'package:tapem/features/device/presentation/widgets/machine_leaderboard_sheet.dart';
import 'package:tapem/features/device/presentation/widgets/note_button_widget.dart';
import 'package:tapem/features/device/presentation/widgets/session_action_strip.dart';
import 'package:tapem/features/device/presentation/widgets/session_navigation_controls.dart';
import 'package:tapem/features/device/presentation/widgets/set_card.dart';
import 'package:tapem/features/feedback/presentation/widgets/feedback_button.dart'
    show
        showFeedbackDialog;
import 'package:tapem/features/nfc/widgets/nfc_scan_button.dart';
import 'package:tapem/features/rank/presentation/device_level_style.dart';
import 'package:tapem/features/rank/presentation/widgets/xp_info_button.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';
import 'package:tapem/ui/timer/session_timer_bar.dart';

import '../../../training_plan/domain/models/exercise_entry.dart';

class DeviceSessionSection extends StatelessWidget {
  const DeviceSessionSection({
    super.key,
    required this.provider,
    required this.gymId,
    required this.deviceId,
    required this.exerciseId,
    required this.userId,
    this.sessionKey,
    this.plannedEntry,
    this.onSessionSaved,
    this.onCloseRequested,
  });

  final DeviceProvider provider;
  final String gymId;
  final String deviceId;
  final String exerciseId;
  final String userId;
  final String? sessionKey;
  final ExerciseEntry? plannedEntry;
  final VoidCallback? onSessionSaved;
  final VoidCallback? onCloseRequested;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DeviceProvider>.value(
      value: provider,
      child: _DeviceSessionSectionBody(
        gymId: gymId,
        deviceId: deviceId,
        exerciseId: exerciseId,
        userId: userId,
        sessionKey: sessionKey,
        plannedEntry: plannedEntry,
        onSessionSaved: onSessionSaved,
        onCloseRequested: onCloseRequested,
      ),
    );
  }
}

class _DeviceSessionSectionBody extends StatefulWidget {
  const _DeviceSessionSectionBody({
    required this.gymId,
    required this.deviceId,
    required this.exerciseId,
    required this.userId,
    this.sessionKey,
    this.plannedEntry,
    this.onSessionSaved,
    this.onCloseRequested,
  });

  final String gymId;
  final String deviceId;
  final String exerciseId;
  final String userId;
  final String? sessionKey;
  final ExerciseEntry? plannedEntry;
  final VoidCallback? onSessionSaved;
  final VoidCallback? onCloseRequested;

  @override
  State<_DeviceSessionSectionBody> createState() => _DeviceSessionSectionBodyState();
}

class _DeviceSessionSectionBodyState extends State<_DeviceSessionSectionBody> {
  final _formKey = GlobalKey<FormState>();
  final _setListController = ScrollController();
  final List<GlobalKey<SetCardState>> _setKeys = [];
  final _pagerKey = GlobalKey<DevicePagerState>();
  int _currentPagerIndex = 0;
  OverlayNumericKeypadController? _keypadController;
  bool _didLoad = false;

  OverlayNumericKeypadController get _overlayKeypad =>
      _keypadController ?? context.read<OverlayNumericKeypadController>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _keypadController ??= context.read<OverlayNumericKeypadController>();
    _ensureSessionLoaded();
  }

  Future<void> _ensureSessionLoaded() async {
    if (_didLoad) return;
    _didLoad = true;
    final auth = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    await settings.load(auth.userId!);
    final provider = context.read<DeviceProvider>();
    await provider.loadDevice(
      gymId: widget.gymId,
      deviceId: widget.deviceId,
      exerciseId: widget.exerciseId,
      userId: widget.userId,
    );
    final planProv = context.read<TrainingPlanProvider>();
    if (planProv.plans.isEmpty && !planProv.isLoading) {
      await planProv.loadPlans(widget.gymId, widget.userId);
    }
    if (planProv.activePlanId == null && planProv.plans.isNotEmpty) {
      await planProv.setActivePlan(planProv.plans.first.id);
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _addSet() {
    _focusSession();
    final prov = context.read<DeviceProvider>();
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
      context.read<WorkoutDayController>().focusSession(key);
    }
  }

  void _handlePagerIndexChanged(int index) {
    if (_currentPagerIndex != index) {
      setState(() {
        _currentPagerIndex = index;
      });
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
    String? exerciseName;
    if (deviceProv.device?.isMulti ?? false) {
      final exProv = context.read<ExerciseProvider>();
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
        gymId: widget.gymId,
        deviceId: widget.deviceId,
      ),
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
    final availableExercises =
        exercises ?? context.select<ExerciseProvider, List<Exercise>>((p) => p.exercises);
    final match = availableExercises.where((e) => e.id == widget.exerciseId);
    if (match.isNotEmpty) {
      return match.first.name;
    }
    return device.name;
  }

  Widget _buildHeader(BuildContext context, DeviceProvider prov) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final accentColor =
        theme.extension<AppBrandTheme>()?.outline ?? theme.colorScheme.secondary;
    final exercises = prov.device?.isMulti ?? false
        ? context.watch<ExerciseProvider>().exercises
        : null;
    final resolvedTitle =
        _resolveExerciseTitle(context, prov, exercises: exercises) ??
            loc.newSessionTitle;
    final subtitle = prov.device?.isMulti == true &&
            resolvedTitle != prov.device?.name
        ? prov.device?.name
        : null;

    return SessionActionStrip(
      title: resolvedTitle,
      subtitle: subtitle,
      sessionKey: widget.sessionKey,
      nfcButton: NfcScanButton(
        deviceId: widget.deviceId,
        exerciseId: widget.exerciseId,
        onBeforeOpen: _closeKeyboard,
      ),
      onClose: () {
        _closeKeyboard();
        widget.onCloseRequested?.call();
      },
      closeTooltip: loc.commonClose,
      onOpenLeaderboard: prov.device == null
          ? null
          : () => _openLeaderboard(prov, resolvedTitle),
      onOpenHistory: prov.device == null ? null : () => _openHistory(prov),
      onToggleBodyweight: () => _toggleBodyweight(prov),
      onFeedback: () => _handleFeedback(),
      isBodyweightMode: prov.isBodyweightMode,
      accentColor: accentColor,
      leaderboardTooltip: loc.deviceLeaderboardTooltip,
      historyTooltip: loc.deviceHistoryTooltip,
      bodyweightTooltip: loc.bodyweightToggleTooltip,
      feedbackTooltip: loc.feedbackTooltip,
      preFeedbackActions: [
        XpInfoButton(
          xp: prov.xp,
          level: prov.level,
          color: accentColor,
        ),
      ],
      postFeedbackActions: [
        NoteButtonWidget(
          deviceId: widget.deviceId,
          sessionIdentifier:
              widget.sessionKey ?? (widget.deviceId, widget.exerciseId),
        ),
      ],
    );
  }

  Widget _buildEditablePage(
    DeviceProvider prov,
    AppLocalizations loc,
    ExerciseEntry? plannedEntry,
  ) {
    final theme = Theme.of(context);
    final outlineColor =
        theme.extension<AppBrandTheme>()?.outline ?? theme.colorScheme.secondary;
    final exercises = prov.device?.isMulti ?? false
        ? context.watch<ExerciseProvider>().exercises
        : null;
    final exerciseTitle = _resolveExerciseTitle(
      context,
      prov,
      exercises: exercises,
    );

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8),
          child: SessionTimerBar(
            initialDuration: Duration(seconds: 90),
          ),
        ),
        Expanded(
          child: Form(
            key: _formKey,
            child: Consumer<OverlayNumericKeypadController>(
              builder: (context, keypad, _) {
                final mq = MediaQuery.of(context);
                final bottomPad = max(
                  0.0,
                  keypad.keypadContentHeight + mq.padding.bottom + 16,
                ).toDouble();
                while (_setKeys.length < prov.sets.length) {
                  _setKeys.add(GlobalKey<SetCardState>());
                }
                if (_setKeys.length > prov.sets.length) {
                  _setKeys.removeRange(prov.sets.length, _setKeys.length);
                }
                final lastSnap =
                    prov.sessionSnapshots.isNotEmpty ? prov.sessionSnapshots.first : null;
                final lastSets = lastSnap != null
                    ? mapSnapshotToVM(lastSnap)
                    : mapLegacySetsToVM(prov.lastSessionSets);
                final lastDate = lastSnap?.createdAt ?? prov.lastSessionDate;
                final lastNote = lastSnap?.note ?? prov.lastSessionNote;
                final itemCount = 1 + prov.sessionSnapshots.length;
                final canGoOlder = _currentPagerIndex < itemCount - 1;
                final canGoNewer = _currentPagerIndex > 0;

                return ListView(
                  controller: _setListController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
                  children: [
                    if (plannedEntry != null)
                      _PlannedTable(entry: plannedEntry)
                    else ...[
                      Center(
                        child: Text(
                          exerciseTitle ?? loc.newSessionTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ).copyWith(color: outlineColor),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (prov.sets.isNotEmpty)
                        _GroupedSetList(
                          sets: prov.sets,
                          setKeys: _setKeys,
                          sessionKey: widget.sessionKey,
                          onRemove: (index, removed) {
                            _focusSession();
                            context.read<DeviceProvider>().removeSet(index);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(loc.setRemoved),
                                action: SnackBarAction(
                                  label: loc.undo,
                                  onPressed: () {
                                    _focusSession();
                                    context
                                        .read<DeviceProvider>()
                                        .insertSetAt(index, removed);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      if (prov.sets.isNotEmpty) const SizedBox(height: 12),
                      Center(
                        child: SessionNavigationControls(
                          onPrevious: canGoOlder
                              ? () => _pagerKey.currentState?.goToPreviousSession()
                              : null,
                          onNext: canGoNewer
                              ? () => _pagerKey.currentState?.goToNextSession()
                              : null,
                          center: _AddSetButton(
                            label: loc.addSetButton,
                            onPressed: _addSet,
                          ),
                        ),
                      ),
                    ],
                    if ((FF.showLastSessionOnDevicePage ||
                            FF.runtimeShowLastSessionOnDevicePage) &&
                        lastDate != null &&
                        lastSets.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Builder(
                        builder: (context) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onHorizontalDragEnd: (d) {
                                final v = d.primaryVelocity ?? 0;
                                if (v > 250) {
                                  _pagerKey.currentState?.goToPreviousSession();
                                } else if (v < -250) {
                                  _pagerKey.currentState?.goToNextSession();
                                }
                              },
                              child: LastSessionCard(
                                date: lastDate,
                                sets: lastSets,
                                note: lastNote,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: SizedBox(
                width: double.infinity,
                child: BrandOutlineButton(
                  onPressed: prov.hasSessionToday || prov.isSaving
                      ? null
                      : () => _saveSession(prov, loc, plannedEntry),
                  child: prov.isSaving
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(outlineColor),
                          ),
                        )
                      : Text(loc.saveButton),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveSession(
    DeviceProvider prov,
    AppLocalizations loc,
    ExerciseEntry? plannedEntry,
  ) async {
    _focusSession();
    final auth = context.read<AuthProvider>();
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
    final settingsProv = context.read<SettingsProvider>();
    final ok = await prov.saveWorkoutSession(
      gymId: widget.gymId,
      userId: auth.userId!,
      showInLeaderboard: auth.showInLeaderboard ?? true,
      userName: auth.userName,
      gender: settingsProv.gender,
      bodyWeightKg: settingsProv.bodyWeightKg,
      plannedRestSeconds: plannedEntry?.restInSeconds,
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

  Widget _buildPager(
    BuildContext context,
    DeviceProvider prov,
    AppLocalizations loc,
    ExerciseEntry? plannedEntry,
  ) {
    final editablePage = _buildEditablePage(prov, loc, plannedEntry);
    final mq = MediaQuery.of(context);
    final height = max(480.0, min(720.0, mq.size.height * 0.7));
    return SizedBox(
      height: height,
      child: DevicePager(
        key: _pagerKey,
        editablePage: editablePage,
        provider: prov,
        gymId: widget.gymId,
        deviceId: widget.deviceId,
        userId: widget.userId,
        onIndexChanged: _handlePagerIndexChanged,
      ),
    );
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

    final plannedEntry = widget.plannedEntry ??
        context.select<TrainingPlanProvider, ExerciseEntry?>(
          (p) => p.entryForDate(
            widget.deviceId,
            widget.exerciseId,
            DateTime.now(),
          ),
        );

    return _buildPager(context, prov, loc, plannedEntry);
  }

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();
    _keypadController?.close();
    _setListController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DeviceProvider>();
    final auth = context.watch<AuthProvider>();
    prov.updateAutoSavePreference(auth.showInLeaderboard ?? true);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, prov),
          const Divider(height: 1),
          _buildContent(context, prov),
        ],
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
  });

  final List<Map<String, dynamic>> sets;
  final List<GlobalKey<SetCardState>> setKeys;
  final void Function(int index, Map<String, dynamic> removed) onRemove;
  final String? sessionKey;

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrandTheme>();
    final loc = AppLocalizations.of(context)!;
    final isBodyweightMode = context.watch<DeviceProvider>().isBodyweightMode;
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
            weightLabel: isBodyweightMode
                ? loc.bodyweightFieldLabel(loc.tableHeaderKg)
                : loc.weightFieldLabel(loc.tableHeaderKg),
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
  }) {
    return Dismissible(
      key: ValueKey('set-${set['number']}'),
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
    final double leadingWidth =
        (dense ? 28 : 32) + (dense ? 8 : 12) + (dropActive ? (dense ? 4 : 6) + (dense ? 24 : 28) : 0);

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
          Expanded(
            child: Text(
              weightLabel,
              style: headerStyle,
            ),
          ),
          SizedBox(width: dense ? 8 : 12),
          Expanded(
            child: Text(
              repsLabel,
              style: headerStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannedTable extends StatefulWidget {
  const _PlannedTable({required this.entry});

  final ExerciseEntry entry;

  @override
  State<_PlannedTable> createState() => _PlannedTableState();
}

class _PlannedTableState extends State<_PlannedTable> {
  final List<TextEditingController> _weightCtrls = [];
  final List<TextEditingController> _repsCtrls = [];

  bool _muted = false;

  void _setTextSilently(TextEditingController c, String text) {
    if (c.text == text) return;
    _muted = true;
    c.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _muted = false;
  }

  void _syncControllers(List<Map<String, dynamic>> sets) {
    while (_weightCtrls.length < sets.length) {
      final i = _weightCtrls.length;
      _weightCtrls.add(TextEditingController(text: sets[i]['weight'] ?? ''));
      _repsCtrls.add(TextEditingController(text: sets[i]['reps'] ?? ''));

      _weightCtrls[i].addListener(() {
        if (_muted) return;
        context.read<DeviceProvider>().updateSet(
              i,
              weight: _weightCtrls[i].text,
            );
      });
      _repsCtrls[i].addListener(() {
        if (_muted) return;
        context.read<DeviceProvider>().updateSet(i, reps: _repsCtrls[i].text);
      });
    }

    while (_weightCtrls.length > sets.length) {
      _weightCtrls.removeLast().dispose();
      _repsCtrls.removeLast().dispose();
    }

    for (var i = 0; i < sets.length; i++) {
      final w = sets[i]['weight'] ?? '';
      final r = sets[i]['reps'] ?? '';
      _setTextSilently(_weightCtrls[i], w);
      _setTextSilently(_repsCtrls[i], r);
    }
  }

  @override
  void dispose() {
    for (final c in _weightCtrls) {
      c.dispose();
    }
    for (final c in _repsCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DeviceProvider>();

    if (prov.sets.length < widget.entry.totalSets) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        while (prov.sets.length < widget.entry.totalSets) {
          prov.addSet();
        }
      });
    }

    if (widget.entry.reps != null &&
        prov.sets.every((s) => (s['reps'] ?? '').toString().isEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (var i = 0; i < prov.sets.length; i++) {
          prov.updateSet(i, reps: widget.entry.reps!.toString());
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncControllers(prov.sets);
    });

    final weightHint = widget.entry.weight?.toString();
    final repsHint = widget.entry.reps?.toString();
    final loc = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Container(
        decoration: DeviceLevelStyle.widgetDecorationFor(
          prov.level,
          theme: Theme.of(context),
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Heute dran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final entrySet in prov.sets.asMap().entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 24, child: Text(entrySet.value['number'] ?? '')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('w-${entrySet.key}'),
                        controller: _weightCtrls[entrySet.key],
                        decoration: InputDecoration(
                          labelText: prov.isBodyweightMode ? loc.bodyweight : 'kg',
                          hintText: weightHint,
                          isDense: true,
                        ),
                        readOnly: true,
                        keyboardType: TextInputType.none,
                        autofocus: false,
                        onTap: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          context
                              .read<OverlayNumericKeypadController>()
                              .openFor(
                                _weightCtrls[entrySet.key],
                                allowDecimal: true,
                              );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('r-${entrySet.key}'),
                        controller: _repsCtrls[entrySet.key],
                        decoration: InputDecoration(
                          labelText: 'x',
                          hintText: repsHint,
                          isDense: true,
                        ),
                        readOnly: true,
                        keyboardType: TextInputType.none,
                        autofocus: false,
                        onTap: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          context
                              .read<OverlayNumericKeypadController>()
                              .openFor(
                                _repsCtrls[entrySet.key],
                                allowDecimal: false,
                              );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => prov.removeSet(entrySet.key),
                    ),
                  ],
                ),
              ),
            Center(
              child: _AddSetButton(
                label: loc.addSetButton,
                onPressed: () => prov.addSet(),
              ),
            ),
            if (widget.entry.notes != null && widget.entry.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notiz: ${widget.entry.notes!}'),
            ],
            const Divider(),
          ],
        ),
      ),
    );
  }
}
