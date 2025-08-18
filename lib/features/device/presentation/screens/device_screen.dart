// lib/features/device/presentation/screens/device_screen.dart
// Reordered addSet flow (open keypad first, then ensureVisible).
// PlannedTable uses silent updates to avoid re-entrant rebuilds.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/widgets/brand_primary_button.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_gradient_card.dart';
import 'package:tapem/l10n/app_localizations.dart';

import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/providers/training_plan_provider.dart';
import 'package:tapem/core/providers/exercise_provider.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import '../../../training_plan/domain/models/exercise_entry.dart';
import '../widgets/note_button_widget.dart';
import '../widgets/set_card.dart';
import '../widgets/device_pager.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';
import 'package:tapem/features/rank/presentation/device_level_style.dart';
import 'package:tapem/features/rank/presentation/widgets/xp_info_button.dart';
import 'package:tapem/features/feedback/presentation/widgets/feedback_button.dart';
import 'package:tapem/ui/timer/session_timer_bar.dart';

void _dlog(String m) => debugPrint('📱 [DeviceScreen] $m');
// void _elog(String m) => debugPrint('❗ [DeviceScreen] $m');

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<DeviceProvider>().loadMoreSnapshots(
              gymId: widget.gymId,
              deviceId: widget.deviceId,
            );
      });
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
                return ListView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
                  children: [
                    if (prov.device!.description.isNotEmpty) ...[
                      Text(
                        prov.device!.description,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
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
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: prov.sets.length,
                        itemBuilder: (context, index) {
                          final set = prov.sets[index];
                          final prev = index < prov.lastSessionSets.length
                              ? prov.lastSessionSets[index]
                              : null;
                          return Dismissible(
                            key: ValueKey('set-${set['number']}'),
                            direction: DismissDirection.endToStart,
                            background: const SizedBox.shrink(),
                            secondaryBackground: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              color: Colors.red.withOpacity(0.15),
                              child: const Icon(
                                Icons.delete,
                                semanticLabel: 'Löschen',
                              ),
                            ),
                            onDismissed: (_) {
                              final removed = Map<String, dynamic>.from(set);
                              context
                                  .read<DeviceProvider>()
                                  .removeSet(index);
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
                            child: SetCard(
                              key: _setKeys[index],
                              index: index,
                              set: set,
                              previous: prev,
                              size: SetCardSize.dense,
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(thickness: 1, height: 1),
                        ),
                      ),
                      Center(
                        child: TextButton.icon(
                          onPressed: _addSet,
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.primary,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: Text(loc.addSetButton),
                        ),
                      ),
                    ],
                    if (prov.lastSessionSets.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
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
                              child: BrandGradientCard(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Letzte Session: ${DateFormat.yMd(locale).add_Hm().format(prov.lastSessionDate!)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    for (final set in prov.lastSessionSets)
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('${set['number']}. '),
                                          const SizedBox(width: 12),
                                          BrandGradientCard(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.sm,
                                              vertical: AppSpacing.xs,
                                            ),
                                            child: Text(
                                              '${set['weight']} kg',
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Text('${set['reps']} x'),
                                          if (set['dropWeight'] != null &&
                                              set['dropWeight']!.isNotEmpty) ...[
                                            const SizedBox(width: 16),
                                            Text(
                                              '↘︎ ${set['dropWeight']} kg × ${set['dropReps']}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                          if (set['rir'] != null &&
                                              set['rir']!.isNotEmpty) ...[
                                            const SizedBox(width: 16),
                                            Text('RIR ${set['rir']}'),
                                          ],
                                          if (set['note'] != null &&
                                              set['note']!.isNotEmpty) ...[
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Text(set['note']!),
                                            ),
                                          ],
                                        ],
                                      ),
                                    if (prov.lastSessionNote.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text('Notiz: ${prov.lastSessionNote}'),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
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
                child: OutlinedButton(
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
                          if (!_formKey.currentState!.validate()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(loc.pleaseCheckInputs),
                              ),
                            );
                            return;
                          }
                          if (prov.completedCount == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(loc.noCompletedSets),
                              ),
                            );
                            return;
                          }
                          final auth = context.read<AuthProvider>();
                          final ok = await prov.saveWorkoutSession(
                            context: context,
                            gymId: widget.gymId,
                            userId: auth.userId!,
                            showInLeaderboard:
                                auth.showInLeaderboard ?? true,
                          );
                          if (!ok) {
                            final msg =
                                prov.error ?? 'Speichern fehlgeschlagen.';
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(msg)));
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                prov.device!.isMulti
                                    ? loc.multiDeviceSessionSaved
                                    : loc.sessionSaved,
                              ),
                            ),
                          );
                        },
                  child: prov.isSaving
                      ? const CircularProgressIndicator()
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
      scaffold = Scaffold(
        appBar: AppBar(
          title: Hero(
            tag: 'device-${prov.device!.uid}',
            child: Material(
              type: MaterialType.transparency,
              child: Text(prov.device!.name),
            ),
          ),
          centerTitle: true,
          actions: [
            if (!prov.device!.isMulti)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: XpInfoButton(xp: prov.xp, level: prov.level),
              ),
            FeedbackButton(gymId: widget.gymId, deviceId: widget.deviceId),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Zur aktuellen Session',
              onPressed: () =>
                  _pagerKey.currentState?.animateToPage(0),
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
          provider: prov,
          editablePage:
              _buildEditablePage(prov, loc, locale, plannedEntry),
        ),
      );
    }

    return scaffold;
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
  final List<TextEditingController> _rirCtrls = [];

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
      _rirCtrls.add(TextEditingController(text: sets[i]['rir'] ?? ''));

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
      _rirCtrls[i].addListener(() {
        if (_muted) return;
        context.read<DeviceProvider>().updateSet(i, rir: _rirCtrls[i].text);
      });
    }

    while (_weightCtrls.length > sets.length) {
      _weightCtrls.removeLast().dispose();
      _repsCtrls.removeLast().dispose();
      _rirCtrls.removeLast().dispose();
    }

    for (var i = 0; i < sets.length; i++) {
      final w = sets[i]['weight'] ?? '';
      final r = sets[i]['reps'] ?? '';
      final rir = sets[i]['rir'] ?? '';
      _setTextSilently(_weightCtrls[i], w);
      _setTextSilently(_repsCtrls[i], r);
      _setTextSilently(_rirCtrls[i], rir);
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
    for (final c in _rirCtrls) {
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

    _syncControllers(prov.sets);

    final weightHint = widget.entry.weight?.toString();
    final repsHint = widget.entry.reps?.toString();
    final rirHint = widget.entry.rir > 0 ? widget.entry.rir.toString() : null;

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
                          labelText: 'kg',
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
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('rir-${entrySet.key}'),
                        controller: _rirCtrls[entrySet.key],
                        decoration: InputDecoration(
                          labelText: 'RIR',
                          hintText: rirHint,
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
                                _rirCtrls[entrySet.key],
                                allowDecimal: false,
                              );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        key: ValueKey('n-${entrySet.key}'),
                        initialValue: entrySet.value['note'],
                        decoration: const InputDecoration(
                          labelText: 'Notiz',
                          isDense: true,
                        ),
                        onChanged: (v) => prov.updateSet(entrySet.key, note: v),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => prov.removeSet(entrySet.key),
                    ),
                  ],
                ),
              ),
            TextButton.icon(
              onPressed: () => prov.addSet(),
              icon: const Icon(Icons.add),
              label: const Text('Set hinzufügen'),
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
