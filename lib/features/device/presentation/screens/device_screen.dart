// lib/features/device/presentation/screens/device_screen.dart
// Reordered addSet flow (open keypad first, then ensureVisible).
// PlannedTable uses silent updates to avoid re-entrant rebuilds.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/widgets/brand_gradient_card.dart';
import 'package:tapem/core/widgets/brand_gradient_text.dart';
import 'package:tapem/core/widgets/brand_outline.dart';
import 'package:tapem/core/widgets/brand_primary_button.dart';
import 'package:tapem/core/theme/brand_on_colors.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/config/feature_flags.dart';

import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/providers/training_plan_provider.dart';
import 'package:tapem/core/providers/exercise_provider.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import '../../../training_plan/domain/models/exercise_entry.dart';
import '../widgets/note_button_widget.dart';
import '../widgets/set_card.dart';
import '../models/session_set_vm.dart';
import '../widgets/last_session_card.dart';
import '../widgets/device_pager.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';
import 'package:tapem/features/rank/presentation/device_level_style.dart';
import 'package:tapem/features/rank/presentation/widgets/xp_info_button.dart';
import 'package:tapem/features/feedback/presentation/widgets/feedback_button.dart';
import 'package:tapem/ui/timer/session_timer_bar.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/time/logic_day.dart';

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

    // PostFrame #1: Keypad öffnen (fokussiert Gewicht)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final index = prov.sets.length - 1;
      if (index >= 0 && index < _setKeys.length) {
        final key = _setKeys[index];
        key.currentState?.focusWeight();

        // PostFrame #2: erst NACH keypad-open scrollen (korrektes bottomPad)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (key.currentContext != null) {
            _dlog(
              'after add: sets=${prov.sets.length}, ensureVisible index=$index',
            );
            Scrollable.ensureVisible(
              key.currentContext!,
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
    context.read<OverlayNumericKeypadController>().close();
  }

  Widget _buildEditablePage(
    DeviceProvider prov,
    AppLocalizations loc,
    String locale,
    ExerciseEntry? plannedEntry,
    Color onBrandColor,
  ) {
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
                return ListView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
                  children: [
                    if (plannedEntry != null)
                      _PlannedTable(entry: plannedEntry)
                    else ...[
                      Text(
                        loc.newSessionTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
                        child: _AddSetButton(
                          label: loc.addSetButton,
                          onPressed: _addSet,
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
          child: Row(
            children: [
              Expanded(
                child: BrandPrimaryButton(
                  onPressed: () {
                    _closeKeyboard();
                    Navigator.pop(context);
                  },
                  child: Text(loc.cancelButton),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BrandPrimaryButton(
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
                            'dayKey': logicDayKey(DateTime.now().toUtc()),
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              onBrandColor,
                            ),
                          ),
                        )
                      : Text(loc.saveButton),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _closeKeyboard();
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
      scaffold = const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (prov.error != null || prov.device == null) {
      scaffold = Scaffold(
        appBar: AppBar(title: const Text('Gerät nicht gefunden')),
        body: Center(child: Text('Fehler: ${prov.error ?? "Unbekannt"}')),
      );
    } else {
      final theme = Theme.of(context);
      final accentColor = theme.colorScheme.secondary;
      final onBrandColor =
          theme.extension<BrandOnColors>()?.onCta ?? Colors.black;
      final titleBase = theme.textTheme.titleLarge ??
          const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          );
      final titleStyle = titleBase.copyWith(fontWeight: FontWeight.w600);

      scaffold = Scaffold(
        appBar: AppBar(
          foregroundColor: accentColor,
          iconTheme: IconThemeData(color: accentColor),
          actionsIconTheme: IconThemeData(color: accentColor),
          titleTextStyle: titleStyle,
          toolbarTextStyle:
              theme.textTheme.titleMedium?.copyWith(color: accentColor),
          title: Hero(
            tag: 'device-${prov.device!.uid}',
            child: Material(
              type: MaterialType.transparency,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ConstrainedBox(
                    constraints:
                        BoxConstraints(maxWidth: constraints.maxWidth),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: BrandGradientText(
                        prov.device!.name,
                        style: titleStyle,
                        textAlign: TextAlign.center,
                        softWrap: false,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: XpInfoButton(xp: prov.xp, level: prov.level),
            ),
            FeedbackButton(gymId: widget.gymId, deviceId: widget.deviceId),
            IconButton(
              icon: Icon(
                Icons.accessibility_new,
                color: prov.isBodyweightMode
                    ? theme.colorScheme.primary
                    : accentColor,
              ),
              tooltip: loc.bodyweightToggleTooltip,
              onPressed: () {
                prov.toggleBodyweightMode();
                elogUi('bodyweight_toggle', {
                  'enabled': prov.isBodyweightMode,
                  'deviceId': widget.deviceId,
                  'exerciseId': widget.exerciseId,
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Verlauf',
              onPressed: () {
                _closeKeyboard();
                final deviceProv = context.read<DeviceProvider>();
                String? exerciseName;
                if (deviceProv.device?.isMulti ?? false) {
                  final exProv = context.read<ExerciseProvider>();
                  exerciseName = exProv.exercises
                      .firstWhere(
                        (e) => e.id == widget.exerciseId,
                        orElse: () =>
                            Exercise(id: '', name: 'Unknown', userId: ''),
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
                    if (deviceProv.device?.isMulti ?? false)
                      'exerciseId': widget.exerciseId,
                    if (deviceProv.device?.isMulti ?? false)
                      'exerciseName': exerciseName,
                  },
                );
              },
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: NoteButtonWidget(deviceId: widget.deviceId),
        body: DevicePager(
          key: _pagerKey,
          gymId: widget.gymId,
          deviceId: prov.device!.uid,
          userId: auth.userId!,
          provider: prov,
          editablePage:
              _buildEditablePage(
                prov,
                loc,
                locale,
                plannedEntry,
                onBrandColor,
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
    final textStyle = theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(
          fontSize: AppFontSizes.title,
          fontWeight: FontWeight.w600,
        );

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
              ShaderMask(
                shaderCallback: (bounds) {
                  final rect = bounds.isEmpty
                      ? const Rect.fromLTWH(0, 0, 1, 1)
                      : Rect.fromLTWH(0, 0, bounds.width, bounds.height);
                  return AppGradients.brandGradient.createShader(rect);
                },
                blendMode: BlendMode.srcIn,
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              BrandGradientText(
                label,
                style: textStyle,
              ),
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
    final outlineRadius = (brand?.outlineRadius as BorderRadius?) ??
        BorderRadius.circular(AppRadius.card);
    final outlineWidth = brand?.outlineWidth ?? 2;
    final innerRadius = outlineRadius - BorderRadius.circular(outlineWidth);

    return BrandOutline(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < sets.length; index++) ...[
            if (index > 0)
              const Divider(
                height: 1,
                thickness: 1,
              ),
            Dismissible(
              key: ValueKey('set-${sets[index]['number']}'),
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
                final removed = Map<String, dynamic>.from(sets[index]);
                onRemove(index, removed);
              },
              child: SetCard(
                key: setKeys[index],
                index: index,
                set: sets[index],
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
            ),
          ],
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
        decoration: DeviceLevelStyle.widgetDecorationFor(prov.level),
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
