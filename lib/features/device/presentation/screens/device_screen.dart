// lib/features/device/presentation/screens/device_screen.dart
// Reordered addSet flow (open keypad first, then ensureVisible).
// PlannedTable uses silent updates to avoid re-entrant rebuilds.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/config/feature_flags.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/providers/exercise_provider.dart';
import 'package:tapem/core/providers/training_plan_provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/time/logic_day.dart';
import 'package:tapem/core/widgets/brand_gradient_card.dart';
import 'package:tapem/core/widgets/brand_outline.dart';
import 'package:tapem/core/widgets/brand_outline_button.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import 'package:tapem/features/feedback/presentation/widgets/feedback_button.dart';
import 'package:tapem/features/nfc/widgets/nfc_scan_button.dart';
import 'package:tapem/features/rank/presentation/device_level_style.dart';
import 'package:tapem/features/rank/presentation/widgets/xp_info_button.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';
import 'package:tapem/ui/timer/active_workout_timer.dart';
import 'package:tapem/ui/timer/session_timer_bar.dart';

import '../models/session_set_vm.dart';
import '../widgets/device_pager.dart';
import '../widgets/last_session_card.dart';
import '../widgets/note_button_widget.dart';
import '../widgets/session_navigation_controls.dart';
import '../widgets/set_card.dart';
import '../../../training_plan/domain/models/exercise_entry.dart';

void _dlog(String m) {}

class DeviceScreen extends StatefulWidget {
  final String gymId;
  final String deviceId;
  final String exerciseId;

  const DeviceScreen({
    Key? key,
    required this.gymId,
    required this.deviceId,
    required this.exerciseId,
  }) : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final List<GlobalKey<SetCardState>> _setKeys = [];
  final _pagerKey = GlobalKey<DevicePagerState>();
  int _currentPagerIndex = 0;
  OverlayNumericKeypadController? _keypadController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _keypadController ??= context.read<OverlayNumericKeypadController>();
  }

  @override
  void initState() {
    super.initState();
    _dlog(
      'initState()\ndeviceId=${widget.deviceId}\nexerciseId=${widget.exerciseId}',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      _dlog('loadDevice() → start');
      await context.read<DeviceProvider>().loadDevice(
        gymId: widget.gymId,
        deviceId: widget.deviceId,
        exerciseId: widget.exerciseId,
        userId: auth.userId!,
      );
      final planProv = context.read<TrainingPlanProvider>();
      if (planProv.plans.isEmpty && !planProv.isLoading) {
        _dlog('TrainingPlanProvider.loadPlans()');
        await planProv.loadPlans(widget.gymId, auth.userId!);
      }
      if (planProv.activePlanId == null && planProv.plans.isNotEmpty) {
        await planProv.setActivePlan(planProv.plans.first.id);
      }
      _dlog('loadDevice() → done');
      setState(() {});
    });
  }

  void _addSet() {
    final prov = context.read<DeviceProvider>();
    _dlog('tap: +Set (before=${prov.sets.length})');
    prov.addSet();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final index = prov.sets.length - 1;
      if (index >= 0 && index < _setKeys.length) {
        final key = _setKeys[index];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final context = key.currentContext;
          if (context != null) {
            _dlog(
              'after add: sets=${prov.sets.length}, ensureVisible index=$index',
            );
            Scrollable.ensureVisible(
              context,
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
    (_keypadController ?? context.read<OverlayNumericKeypadController>()).close();
  }

  void _handlePagerIndexChanged(int index) {
    if (_currentPagerIndex != index) {
      setState(() {
        _currentPagerIndex = index;
      });
    }
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

  AppBar _buildAppBar(
    BuildContext context,
    DeviceProvider prov,
  ) {
    final theme = Theme.of(context);
    final accentColor =
        theme.extension<AppBrandTheme>()?.outline ?? theme.colorScheme.secondary;
    final titleBase = theme.textTheme.titleLarge ??
        const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        );
    final titleStyle = titleBase.copyWith(fontWeight: FontWeight.w600);
    final resolvedTitleStyle = titleStyle.copyWith(color: accentColor);

    final isMulti = prov.device?.isMulti ?? false;
    final exercises = isMulti
        ? context.select<ExerciseProvider, List<Exercise>>((p) => p.exercises)
        : null;
    final headerTitle = _resolveExerciseTitle(
      context,
      prov,
      exercises: exercises,
    );
    final hasOutlineBranding = theme.extension<AppBrandTheme>() != null;

    Widget titleWidget;
    if (hasOutlineBranding) {
      titleWidget = const _DeviceAppBarTimer();
    } else if (headerTitle != null) {
      final textTitle = Text(
        headerTitle,
        key: ValueKey(headerTitle),
        style: resolvedTitleStyle,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
      if (prov.device != null) {
        titleWidget = Hero(
          tag: 'device-${prov.device!.uid}',
          child: Material(
            type: MaterialType.transparency,
            child: textTitle,
          ),
        );
      } else {
        titleWidget = textTitle;
      }
    } else {
      titleWidget = const SizedBox.shrink();
    }

    return AppBar(
      foregroundColor: accentColor,
      iconTheme: IconThemeData(color: accentColor),
      actionsIconTheme: IconThemeData(color: accentColor),
      titleTextStyle: resolvedTitleStyle,
      toolbarTextStyle:
          theme.textTheme.titleMedium?.copyWith(color: accentColor),
      centerTitle: true,
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: titleWidget,
      ),
      actions: const [
        NfcScanButton(),
        SizedBox(width: 8),
      ],
      bottom: prov.device == null
          ? null
          : _DeviceAppBarFooter(
              provider: prov,
              gymId: widget.gymId,
              deviceId: widget.deviceId,
              exerciseId: widget.exerciseId,
              closeKeyboard: _closeKeyboard,
            ),
    );
  }

  Widget _buildEditablePage(
    DeviceProvider prov,
    AppLocalizations loc,
    String locale,
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
                final bottomPad =
                    keypad.keypadContentHeight + mq.padding.bottom + 16;
                _dlog(
                  'list bottomPad=$bottomPad keypadHeight=${keypad.keypadContentHeight}',
                );
                while (_setKeys.length < prov.sets.length) {
                  _setKeys.add(GlobalKey<SetCardState>());
                }
                if (_setKeys.length > prov.sets.length) {
                  _setKeys.removeRange(prov.sets.length, _setKeys.length);
                }
                final lastSnap = prov.sessionSnapshots.isNotEmpty ? prov.sessionSnapshots.first : null;
                final lastSets = lastSnap != null ? mapSnapshotToVM(lastSnap) : mapLegacySetsToVM(prov.lastSessionSets);
                final lastDate = lastSnap?.createdAt ?? prov.lastSessionDate;
                final lastNote = lastSnap?.note ?? prov.lastSessionNote;
                final itemCount = 1 + prov.sessionSnapshots.length;
                final canGoOlder = _currentPagerIndex < itemCount - 1;
                final canGoNewer = _currentPagerIndex > 0;
                return ListView(
                  controller: _scrollController,
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
                          onRemove: (index, removed) {
                            context.read<DeviceProvider>().removeSet(index);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(loc.setRemoved),
                                action: SnackBarAction(
                                  label: loc.undo,
                                  onPressed: () => context
                                      .read<DeviceProvider>()
                                      .insertSetAt(index, removed),
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
                      : () async {
                          final auth = context.read<AuthProvider>();
                          final base = {
                            'uid': auth.userId!,
                            'gymId': widget.gymId,
                            'deviceId': widget.deviceId,
                            'isMulti': prov.device?.isMulti ?? false,
                            'screen': 'DeviceScreen',
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
                          final totalFilled =
                              counts.done + counts.filledNotDone;
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
                          final ok = await prov.saveWorkoutSession(
                            gymId: widget.gymId,
                            userId: auth.userId!,
                            showInLeaderboard:
                                auth.showInLeaderboard ?? true,
                            plannedRestSeconds: plannedEntry?.restInSeconds,
                          );
                          final sessionId = prov.lastSessionId;
                          if (!ok) {
                            elogUi('SAVE_PERSIST_ERROR', {
                              ...base,
                              if (sessionId != null) 'sessionId': sessionId,
                              'reason': prov.error ?? 'unknown',
                            });
                            final msg =
                                prov.error ?? 'Speichern fehlgeschlagen.';
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
                          final message = prov.device!.isMulti
                              ? loc.multiDeviceSessionSaved
                              : loc.sessionSaved;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(message)),
                          );
                          _closeKeyboard();
                          Navigator.of(context).popUntil((route) {
                            final name = route.settings.name;
                            return name == AppRouter.home || route.isFirst;
                          });
                        },
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

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();
    _keypadController?.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DeviceProvider>();
    final auth = context.watch<AuthProvider>();
    prov.updateAutoSavePreference(auth.showInLeaderboard ?? true);
    final locale = Localizations.localeOf(context).toString();
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brandColor =
        theme.extension<AppBrandTheme>()?.outline ?? theme.colorScheme.secondary;
    final planProv = context.watch<TrainingPlanProvider>();
    final plannedEntry = planProv.entryForDate(
      widget.deviceId,
      widget.exerciseId,
      DateTime.now(),
    );
    _dlog(
      'build() isLoading=${prov.isLoading} error=${prov.error} sets=${prov.sets.length}',
    );

    Widget scaffold;
    if (prov.isLoading) {
      scaffold = Scaffold(
        appBar: _buildAppBar(context, prov),
        body: const Center(child: CircularProgressIndicator()),
      );
    } else if (prov.error != null || prov.device == null) {
      scaffold = Scaffold(
        appBar: _buildAppBar(context, prov),
        body: DefaultTextStyle.merge(
          style: TextStyle(color: brandColor),
          child: Center(
            child: Text('${loc.errorPrefix}: ${prov.error ?? loc.commonUnknown}'),
          ),
        ),
      );
    } else {
      scaffold = Scaffold(
        appBar: _buildAppBar(context, prov),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 72, right: 4),
          child: NoteButtonWidget(deviceId: widget.deviceId),
        ),
        body: DefaultTextStyle.merge(
          style: TextStyle(color: brandColor),
          child: DevicePager(
            key: _pagerKey,
            gymId: widget.gymId,
            deviceId: prov.device!.uid,
            userId: auth.userId!,
            provider: prov,
            onIndexChanged: _handlePagerIndexChanged,
            editablePage:
                _buildEditablePage(
                  prov,
                  loc,
                  locale,
                  plannedEntry,
                ),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        _closeKeyboard();
        return true;
      },
      child: scaffold,
    );
  }
}

class _DeviceAppBarTimer extends StatelessWidget {
  const _DeviceAppBarTimer();

  @override
  Widget build(BuildContext context) {
    final hasOutlineBranding =
        Theme.of(context).extension<AppBrandTheme>() != null;
    if (!hasOutlineBranding) {
      return const SizedBox.shrink();
    }
    return const ActiveWorkoutTimer(
      key: ValueKey('deviceAppBarTimer'),
      padding: EdgeInsets.zero,
      compact: true,
    );
  }
}

class _DeviceAppBarFooter extends StatelessWidget
    implements PreferredSizeWidget {
  final DeviceProvider provider;
  final String gymId;
  final String deviceId;
  final String exerciseId;
  final VoidCallback closeKeyboard;

  const _DeviceAppBarFooter({
    required this.provider,
    required this.gymId,
    required this.deviceId,
    required this.exerciseId,
    required this.closeKeyboard,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor =
        theme.extension<AppBrandTheme>()?.outline ?? theme.colorScheme.secondary;
    final loc = AppLocalizations.of(context)!;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(child: SizedBox()),
            const SizedBox(width: 8),
            XpInfoButton(
              xp: provider.xp,
              level: provider.level,
              color: accentColor,
            ),
            const SizedBox(width: 4),
            FeedbackButton(
              gymId: gymId,
              deviceId: deviceId,
              color: accentColor,
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                Icons.accessibility_new,
                color: provider.isBodyweightMode
                    ? theme.colorScheme.primary
                    : accentColor,
              ),
              tooltip: loc.bodyweightToggleTooltip,
              onPressed: () {
                provider.toggleBodyweightMode();
                elogUi('bodyweight_toggle', {
                  'enabled': provider.isBodyweightMode,
                  'deviceId': deviceId,
                  'exerciseId': exerciseId,
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.history, color: accentColor),
              tooltip: loc.deviceHistoryTooltip,
              onPressed: () {
                closeKeyboard();
                final deviceProv = provider;
                String? exerciseName;
                if (deviceProv.device?.isMulti ?? false) {
                  final exProv = context.read<ExerciseProvider>();
                  exerciseName = exProv.exercises
                      .firstWhere(
                        (e) => e.id == exerciseId,
                        orElse: () =>
                            Exercise(id: '', name: 'Unknown', userId: ''),
                      )
                      .name;
                }
                Navigator.of(context).pushNamed(
                  AppRouter.history,
                  arguments: {
                    'deviceId': deviceId,
                    'deviceName': deviceProv.device?.name ?? deviceId,
                    'deviceDescription': deviceProv.device?.description,
                    'isMulti': deviceProv.device?.isMulti ?? false,
                    if (deviceProv.device?.isMulti ?? false)
                      'exerciseId': exerciseId,
                    if (deviceProv.device?.isMulti ?? false)
                      'exerciseName': exerciseName,
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddSetButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const _AddSetButton({
    required this.onPressed,
    required this.label,
  });

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
  final List<Map<String, dynamic>> sets;
  final List<GlobalKey<SetCardState>> setKeys;
  final void Function(int index, Map<String, dynamic> removed) onRemove;

  const _GroupedSetList({
    required this.sets,
    required this.setKeys,
    required this.onRemove,
  });

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
            final weight =
                (drop['weight'] ?? drop['kg'] ?? '').toString().trim();
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
  }) {
    return Dismissible(
      key: ValueKey("set-${set['number']}"),
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
        groupedRadius: BorderRadius.only(
          topLeft: index == 0 ? innerRadius.topLeft : Radius.zero,
          topRight: index == 0 ? innerRadius.topRight : Radius.zero,
          bottomLeft:
              index == sets.length - 1 ? innerRadius.bottomLeft : Radius.zero,
          bottomRight:
              index == sets.length - 1 ? innerRadius.bottomRight : Radius.zero,
        ),
      ),
    );
  }
}

class _SetListFieldHeader extends StatelessWidget {
  final SetCardTheme tokens;
  final bool dense;
  final bool dropActive;
  final String weightLabel;
  final String repsLabel;

  const _SetListFieldHeader({
    required this.tokens,
    required this.dense,
    required this.dropActive,
    required this.weightLabel,
    required this.repsLabel,
  });

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
  final ExerciseEntry entry;

  const _PlannedTable({required this.entry});

  @override
  State<_PlannedTable> createState() => _PlannedTableState();
}

class _PlannedTableState extends State<_PlannedTable> {
  final List<TextEditingController> _weightCtrls = [];
  final List<TextEditingController> _repsCtrls = [];

  // 🔒 Silent-update Mechanik
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
                    SizedBox(width: 24, child: Text(entrySet.value['number']!)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('w-${entrySet.key}'),
                        controller: _weightCtrls[entrySet.key],
                        decoration: InputDecoration(
                          labelText:
                              prov.isBodyweightMode ? loc.bodyweight : 'kg',
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
            if (widget.entry.notes != null &&
                widget.entry.notes!.isNotEmpty) ...[
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
