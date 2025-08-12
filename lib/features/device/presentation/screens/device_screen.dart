// lib/features/device/presentation/screens/device_screen.dart
// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/widgets/gradient_button.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/theme/brand_surface_theme.dart';
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
import '../widgets/multi_device_banner.dart';
import '../widgets/exercise_header.dart';
import '../widgets/exercise_bottom_sheet.dart';
import 'package:tapem/features/rank/presentation/device_level_style.dart';
import 'package:tapem/features/rank/presentation/widgets/xp_info_button.dart';
import 'package:tapem/features/feedback/presentation/widgets/feedback_button.dart';
import 'package:tapem/ui/timer/session_timer_bar.dart';

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
  bool _showTimer = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      await context.read<DeviceProvider>().loadDevice(
        gymId: widget.gymId,
        deviceId: widget.deviceId,
        exerciseId: widget.exerciseId,
        userId: auth.userId!,
      );
      final planProv = context.read<TrainingPlanProvider>();
      if (planProv.plans.isEmpty && !planProv.isLoading) {
        await planProv.loadPlans(widget.gymId, auth.userId!);
      }
      if (planProv.activePlanId == null && planProv.plans.isNotEmpty) {
        await planProv.setActivePlan(planProv.plans.first.id);
      }
      setState(() {});
    });
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
    final exProv = context.watch<ExerciseProvider>();
    Exercise? currentExercise;
    try {
      currentExercise = exProv.exercises
          .firstWhere((e) => e.id == widget.exerciseId);
    } catch (_) {}

    if (prov.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (prov.error != null || prov.device == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gerät nicht gefunden')),
        body: Center(child: Text('Fehler: ${prov.error ?? "Unbekannt"}')),
      );
    }

    // Single-Übung: hier bleiben
    return Scaffold(
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
            icon: const Icon(Icons.history),
            tooltip: 'Verlauf',
            onPressed: () {
              Navigator.of(
                context,
              ).pushNamed(AppRouter.history, arguments: widget.deviceId);
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: NoteButtonWidget(deviceId: widget.deviceId),
      body: Column(
        children: [
          if (_showTimer)
            Padding(
              padding: const EdgeInsets.all(8),
              child: SessionTimerBar(
                total: const Duration(seconds: 90),
                onClose: () => setState(() => _showTimer = false),
              ),
            ),
          if (prov.device!.isMulti) const MultiDeviceBanner(),
          if (prov.device!.isMulti && currentExercise != null)
            ExerciseHeader(
              name: currentExercise.name,
              muscleGroupIds: currentExercise.muscleGroupIds,
              onChange: () {
                Navigator.of(context).pushReplacementNamed(
                  AppRouter.exerciseList,
                  arguments: {
                    'gymId': widget.gymId,
                    'deviceId': widget.deviceId,
                  },
                );
              },
              onEdit: () async {
                await showModalBottomSheet<Exercise>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => ExerciseBottomSheet(
                    gymId: widget.gymId,
                    deviceId: widget.deviceId,
                    exercise: currentExercise,
                  ),
                );
              },
            ),
          if (prov.device!.isMulti)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(loc.multiDeviceSessionHint),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    if (prov.lastSessionSets.isNotEmpty) ...[
                      Builder(builder: (context) {
                        final surface =
                            Theme.of(context).extension<BrandSurfaceTheme>();
                        var gradient =
                            surface?.gradient ?? AppGradients.brandGradient;
                        if (surface != null) {
                          final lums =
                              gradient.colors.map((c) => c.computeLuminance());
                          final lum =
                              lums.reduce((a, b) => a + b) / gradient.colors.length;
                          final delta = surface.luminanceRef - lum;
                          gradient = Tone.gradient(gradient, delta);
                        }
                        final textColor =
                            Theme.of(context).colorScheme.onPrimary;
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: surface?.radius as BorderRadius? ??
                                BorderRadius.circular(AppRadius.card),
                            boxShadow: surface?.shadow,
                          ),
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: DefaultTextStyle.merge(
                            style: TextStyle(color: textColor),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Letzte Session: ${DateFormat.yMd(locale).add_Hm().format(prov.lastSessionDate!)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                for (var set in prov.lastSessionSets)
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        child: Text(set['number']!),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text('${set['weight']} kg'),
                                      ),
                                      const SizedBox(width: 16),
                                      Text('${set['reps']} x'),
                                      if (set['rir'] != null &&
                                          set['rir']!.isNotEmpty) ...[
                                        const SizedBox(width: 16),
                                        Text('RIR ${set['rir']}'),
                                      ],
                                      if (set['note'] != null &&
                                          set['note']!.isNotEmpty) ...[
                                        const SizedBox(width: 16),
                                        Expanded(child: Text(set['note']!)),
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
                        );
                      }),
                    ],
                    const Divider(),
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
                      for (var entry in prov.sets.asMap().entries) ...[
                        Dismissible(
                          key: ValueKey('set-${entry.key}-${entry.value['number']}'),
                          direction: DismissDirection.endToStart,
                          background: const SizedBox.shrink(),
                          secondaryBackground: Container(
                            alignment: Alignment.centerRight,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            color: Colors.red.withOpacity(0.15),
                            child:
                                const Icon(Icons.delete, semanticLabel: 'Löschen'),
                          ),
                          onDismissed: (_) {
                            final removed =
                                Map<String, dynamic>.from(entry.value);
                            final removedIndex = entry.key;
                            context
                                .read<DeviceProvider>()
                                .removeSet(entry.key);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(loc.setRemoved),
                                action: SnackBarAction(
                                  label: loc.undo,
                                  onPressed: () => context
                                      .read<DeviceProvider>()
                                      .insertSetAt(removedIndex, removed),
                                ),
                              ),
                            );
                          },
                          child: SetCard(
                            index: entry.key,
                            set: entry.value,
                            previous: entry.key < prov.lastSessionSets.length
                                ? prov.lastSessionSets[entry.key]
                                : null,
                          ),
                        ),
                        if (entry.key < prov.sets.length - 1) ...[
                          const SizedBox(height: 12),
                          const Divider(thickness: 1, height: 1),
                          const SizedBox(height: 12),
                        ]
                      ],
                      Center(
                        child: TextButton.icon(
                          onPressed: prov.addSet,
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.primary,
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          icon: const Icon(Icons.add),
                          label: Text(loc.addSetButton),
                        ),
                      ),
                    ],
                  ],
                ),
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
                      Navigator.pop(context);
                    },
                    child: Text(loc.cancelButton),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientButton(
                    onPressed: prov.hasSessionToday || prov.isSaving
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(loc.pleaseCheckInputs)),
                              );
                              return;
                            }
                            if (prov.completedCount == 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(loc.noCompletedSets)),
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
                              final msg = prov.error ?? 'Speichern fehlgeschlagen.';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(msg)),
                              );
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
                        : Text(
                            prov.device!.isMulti
                                ? loc.multiDeviceSaveButton
                                : loc.saveButton,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannedTable extends StatelessWidget {
  final ExerciseEntry entry;

  const _PlannedTable({required this.entry});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DeviceProvider>();

    if (prov.sets.length < entry.totalSets) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        while (prov.sets.length < entry.totalSets) {
          prov.addSet();
        }
      });
    }

    // Prefill repetitions from the training plan so the value ist sichtbar
    if (entry.reps != null &&
        prov.sets.every((s) => s['reps'] != null && s['reps']!.isEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (var i = 0; i < prov.sets.length; i++) {
          prov.updateSet(i, reps: entry.reps!.toString());
        }
      });
    }

    final weightHint = entry.weight?.toString();
    final repsHint = entry.reps?.toString();
    final rirHint = entry.rir > 0 ? entry.rir.toString() : null;

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
                        key: ValueKey(
                          'w-${entrySet.key}-${entrySet.value['weight']}',
                        ),
                        initialValue: entrySet.value['weight'],
                        decoration: InputDecoration(
                          labelText: 'kg',
                          hintText: weightHint,
                          isDense: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged:
                            (v) => prov.updateSet(entrySet.key, weight: v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey(
                          'r-${entrySet.key}-${entrySet.value['reps']}',
                        ),
                        initialValue: entrySet.value['reps'],
                        decoration: InputDecoration(
                          labelText: 'x',
                          hintText: repsHint,
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => prov.updateSet(entrySet.key, reps: v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('rir-${entrySet.key}'),
                        initialValue: entrySet.value['rir'],
                        decoration: InputDecoration(
                          labelText: 'RIR',
                          hintText: rirHint,
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => prov.updateSet(entrySet.key, rir: v),
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
            if (entry.notes != null && entry.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notiz: ${entry.notes!}'),
            ],
            const Divider(),
          ],
        ),
      ),
    );
  }
}

