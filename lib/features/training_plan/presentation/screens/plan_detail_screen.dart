import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/gym_provider.dart' hide gymProvider;
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/training_plan/application/draft_training_plan.dart';
import 'package:tapem/features/training_plan/application/plan_builder_provider.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan_exercise.dart';
import 'package:tapem/features/device/providers/workout_day_controller_provider.dart';
import 'package:tapem/features/device/providers/device_riverpod.dart';
import 'package:tapem/features/training_plan/application/training_plan_provider.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan_stats.dart';

class PlanDetailScreen extends ConsumerStatefulWidget {
  const PlanDetailScreen({super.key, this.plan});

  final TrainingPlan? plan;

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  Map<String, String> _resolvedNames = {};
  bool _hydratingNames = false;

  @override
  void initState() {
    super.initState();
    // Initialize builder with plan if provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.plan != null) {
        ref.read(planBuilderProvider.notifier).editExisting(widget.plan!);
      }
    });
  }

  String _exerciseKey(TrainingPlanExercise ex) =>
      '${ex.deviceId}::${ex.exerciseId}';

  String _exerciseKeyFromIds(String deviceId, String exerciseId) =>
      '$deviceId::$exerciseId';

  void _openHistory(
    TrainingPlanExercise item,
    Map<String, Device> deviceMap,
  ) {
    final device = deviceMap[item.deviceId];
    final isMulti = device?.isMulti ?? false;
    final exerciseName =
        item.name?.isNotEmpty == true ? item.name : _resolvedNames[_exerciseKey(item)];
    Navigator.pushNamed(
      context,
      AppRouter.history,
      arguments: {
        'deviceId': item.deviceId,
        'deviceName': device?.name ?? item.deviceId,
        'deviceDescription': device?.description,
        'isMulti': isMulti,
        if (isMulti) 'exerciseId': item.exerciseId,
        if (isMulti && exerciseName != null) 'exerciseName': exerciseName,
      },
    );
  }

  void _openStats(
    BuildContext context,
    TrainingPlanStats stats,
    DraftTrainingPlan draft,
    Map<String, Device> deviceMap,
  ) {
    final plan = widget.plan;
    // Durchschnittliche Abschlüsse pro Woche:
    // Basis ist der Zeitraum zwischen der ersten Plan-Nutzung und heute.
    // Mindestens 1 Kalenderwoche, damit neue Pläne keine extremen Werte liefern.
    final now = DateTime.now();
    final firstUse = stats.firstCompletedAt ?? plan?.createdAt ?? now;
    final totalDays = now.difference(firstUse).inDays;
    final weeksSpan = (totalDays ~/ 7) + 1; // mindestens 1 Woche
    final perWeek = weeksSpan > 0
        ? stats.completions / weeksSpan
        : stats.completions.toDouble();
    final theme = Theme.of(context);
    final brandColor =
        theme.extension<AppBrandTheme>()?.outline ?? theme.colorScheme.secondary;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) {
          return ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Plan-Stats',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: brandColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatCard(
                    title: 'Abgeschlossen',
                    value: stats.completions.toString(),
                    subtitle: 'Gesamt',
                    color: brandColor,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    title: perWeek.isFinite ? perWeek.toStringAsFixed(1) : '0',
                    value: 'Ø/Woche',
                    subtitle: 'seit Start',
                    color: brandColor.withOpacity(0.85),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (stats.lastCompletedAt != null)
                _StatTile(
                  icon: Icons.check_circle,
                  label: 'Letztes Mal',
                  value: _formatDate(stats.lastCompletedAt!),
                ),
              if (stats.firstCompletedAt != null)
                _StatTile(
                  icon: Icons.calendar_month,
                  label: 'Erstes Mal',
                  value: _formatDate(stats.firstCompletedAt!),
                ),
              const SizedBox(height: 12),
              Text(
                'Übungs-History',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: brandColor,
                ),
              ),
              const SizedBox(height: 8),
              for (final ex in draft.exercises)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      ex.name?.isNotEmpty == true
                          ? ex.name!
                          : _resolvedNames[_exerciseKey(ex)] ??
                              deviceMap[ex.deviceId]?.name ??
                              ex.deviceId,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      deviceMap[ex.deviceId]?.name ?? ex.deviceId,
                    ),
                    trailing: Icon(Icons.arrow_forward, color: brandColor),
                    onTap: () => _openHistory(ex, deviceMap),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Future<Map<String, String>> _ensureExerciseNames(
    DraftTrainingPlan draft,
    Map<String, Device> deviceMap,
  ) async {
    final names = Map<String, String>.from(_resolvedNames);
    final auth = ref.read(authViewStateProvider);
    final gymId = auth.gymCode;
    final userId = auth.userId;
    if (gymId == null || userId == null) return names;

    final pendingByDevice = <String, Set<String>>{};
    for (final ex in draft.exercises) {
      final key = _exerciseKey(ex);
      if (ex.name?.isNotEmpty == true) {
        names[key] = ex.name!;
        continue;
      }
      if (names.containsKey(key)) continue;
      final device = deviceMap[ex.deviceId];
      if (device == null) continue;
      if (!device.isMulti) {
        names[key] = device.name;
        continue;
      }
      pendingByDevice.putIfAbsent(ex.deviceId, () => <String>{}).add(ex.exerciseId);
    }

    if (pendingByDevice.isEmpty) {
      if (names.isNotEmpty && mounted) {
        setState(() {
          _resolvedNames = names;
        });
      }
      ref.read(planBuilderProvider.notifier).applyResolvedNames(names);
      return names;
    }

    final getExercises = ref.read(getExercisesForDeviceProvider);
    if (!_hydratingNames && mounted) {
      setState(() => _hydratingNames = true);
    }
    try {
      for (final entry in pendingByDevice.entries) {
        try {
          final exercises =
              await getExercises.execute(gymId, entry.key, userId);
          for (final exerciseId in entry.value) {
            final match =
                exercises.firstWhereOrNull((e) => e.id == exerciseId);
            if (match != null) {
              names[_exerciseKeyFromIds(entry.key, exerciseId)] = match.name;
            }
          }
        } catch (e) {
          debugPrint('Failed to load exercises for ${entry.key}: $e');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _hydratingNames = false);
      }
    }

    if (names.isNotEmpty && mounted) {
      setState(() {
        _resolvedNames = names;
      });
    }
    ref.read(planBuilderProvider.notifier).applyResolvedNames(names);
    return names;
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(planBuilderProvider);
    final gymState = ref.watch(gymProvider);
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    final planId = widget.plan?.id ?? draft.originalId;
    final statsAsync =
        planId != null ? ref.watch(trainingPlanStatsProvider(planId)) : null;
    final statsCount =
        statsAsync?.maybeWhen(data: (s) => s.completions, orElse: () => null);

    final auth = ref.watch(authViewStateProvider);
    final currentGymId = auth.gymCode ?? '';
    final workoutController = ref.watch(workoutDayControllerProvider);
    final activePlanContext = currentGymId.isNotEmpty
        ? workoutController.getPlanContext(gymId: currentGymId)
        : null;
    final isTodayPlanActive =
        planId != null && activePlanContext != null && activePlanContext.$1 == planId;

    // Helper map for device names
    final deviceMap = {
      for (final d in gymState.devices) d.uid: d,
    };

    final needsHydration = draft.exercises.any((ex) {
      final key = _exerciseKey(ex);
      final hasName = (ex.name?.isNotEmpty ?? false) || _resolvedNames.containsKey(key);
      final device = deviceMap[ex.deviceId];
      return !hasName && (device?.isMulti ?? false);
    });

    if (needsHydration && !_hydratingNames) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureExerciseNames(draft, deviceMap);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () async {
             // Edit Name Dialog
             final controller = TextEditingController(text: draft.name);
             final newName = await showDialog<String>(
               context: context, 
               builder: (ctx) => AlertDialog(
                 title: const Text('Name ändern'),
                 content: TextField(
                   controller: controller,
                   decoration: const InputDecoration(filled: true),
                   textCapitalization: TextCapitalization.sentences,
                   autofocus: true,
                 ),
                 actions: [
                   TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
                   FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Speichern')),
                 ],
               ),
             );
             if (newName != null && newName.isNotEmpty) {
               ref.read(planBuilderProvider.notifier).updateName(newName);
             }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(draft.name.isEmpty ? 'Neuer Plan' : draft.name),
              const SizedBox(width: 8),
              const Icon(Icons.edit, size: 16),
            ],
          ),
        ),
        actions: [
          if (draft.isDirty || widget.plan == null) // Show Save if dirty OR new
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Speichern',
              onPressed: () async {
                if (draft.name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bitte gib dem Plan einen Namen')),
                  );
                  return;
                }
                if (draft.exercises.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Füge mindestens eine Übung hinzu')),
                  );
                  return;
                }
                try {
                  await ref.read(planBuilderProvider.notifier).save();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Plan gespeichert')),
                  );
                  // Optionally pop or stay?
                  // If logic was "Create -> Picker -> Save -> Overview", we are done.
                  // But here we are in "Detail". The user might want to start.
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fehler: $e')),
                  );
                }
              },
            ),
          IconButton(
             icon: const Icon(Icons.add),
             tooltip: 'Übung hinzufügen',
             onPressed: () {
               Navigator.pushNamed(context, AppRouter.trainingPlanPicker);
             },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: draft.exercises.isEmpty
                ? Center(
                    child: Text(
                      'Keine Übungen.\nFüge Übungen über "+" hinzu.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 100), // Space for FAB
                    itemCount: draft.exercises.length,
                    onReorder: (oldIndex, newIndex) {
                      ref
                          .read(planBuilderProvider.notifier)
                          .reorderExercises(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final item = draft.exercises[index];
                      final device = deviceMap[item.deviceId];
                      final deviceName = device?.name ?? 'Unbekanntes Gerät (${item.deviceId})';
                      final nameKey = _exerciseKey(item);
                      final exerciseName = item.name?.isNotEmpty == true
                          ? item.name
                          : _resolvedNames[nameKey];
                      final title = exerciseName ?? deviceName;
                      
                      // Identify Exercise Name if different?
                      // Currently assuming single device selection mostly or handling implicitly.
                      // If multi, exerciseId might help distinguish? 
                      // Need access to Exercise definition? Not easily available in gymState (list of Devices).
                      // The `Device` model has exercises? No, `Device` has sub-properties?
                      // Assuming Device Name is sufficient for now, or "Squat Rack (Squats)".
                       
                      return Dismissible(
                        key: ValueKey('${item.deviceId}_${item.exerciseId}_$index'), // Unique key
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          color: Colors.red,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          ref.read(planBuilderProvider.notifier).removeExercise(index);
                        },
                        child: ListTile(
                          key: ValueKey('${item.deviceId}_${item.exerciseId}_$index'),
                          leading: CircleAvatar(
                            backgroundColor: brandColor.withOpacity(0.1),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(color: brandColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: (exerciseName != null && exerciseName != deviceName)
                              ? Text(deviceName)
                              : null,
                          // Subtitle for exercise ID if needed?
                          trailing: const Icon(Icons.drag_handle),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Row(
          children: [
            if (planId != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final stats =
                        ref.read(trainingPlanStatsProvider(planId!).future);
                    stats.then((value) {
                      if (!mounted) return;
                      _openStats(
                        context,
                        value,
                        draft,
                        deviceMap,
                      );
                    });
                  },
                  icon: const Icon(Icons.bar_chart_rounded),
                  label: Text(
                    statsCount != null ? 'Stats ($statsCount)' : 'Stats',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: brandColor,
                    side: BorderSide(color: brandColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            if (planId != null) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: draft.exercises.isEmpty
                    ? null
                    : () async {
                        final authState = ref.read(authViewStateProvider);
                        final userId = authState.userId;
                        final gymId = authState.gymCode ?? '';
                        if (userId == null || gymId.isEmpty) return;

                        final controller =
                            ref.read(workoutDayControllerProvider);

                        if (isTodayPlanActive) {
                          // Training beenden: offene Sessions schließen und Plan-Kontext löschen.
                          controller.cancelActivePlan(
                            userId: userId,
                            gymId: gymId,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Training beendet'),
                              ),
                            );
                          }
                          return;
                        }

                        // Training starten
                        final resolvedNames =
                            await _ensureExerciseNames(draft, deviceMap);

                        for (final item in draft.exercises) {
                          final exerciseName =
                              item.name?.isNotEmpty == true
                                  ? item.name
                                  : resolvedNames[_exerciseKey(item)];
                          controller.addOrFocusSession(
                            gymId: gymId,
                            deviceId: item.deviceId,
                            exerciseId: item.exerciseId,
                            exerciseName: exerciseName,
                            userId: userId,
                          );
                        }

                        final firstItem = draft.exercises.firstOrNull;

                        // Sicherstellen, dass es eine persistierte planId gibt.
                        var effectivePlanId = planId;
                        if (effectivePlanId == null) {
                          effectivePlanId =
                              await ref.read(planBuilderProvider.notifier).save();
                        }

                        // Plan-Kontext im Controller registrieren.
                        controller.setPlanContext(
                          gymId: gymId,
                          planId: effectivePlanId,
                          planName: draft.name,
                        );

                        if (firstItem != null) {
                          Navigator.pushNamed(
                            context,
                            AppRouter.workoutDay,
                            arguments: {
                              'gymId': gymId,
                              'deviceId': firstItem.deviceId,
                              'exerciseId': firstItem.exerciseId,
                              'planId': effectivePlanId,
                              'planName': draft.name,
                            },
                          );
                        }
                      },
                icon: Icon(isTodayPlanActive ? Icons.stop : Icons.play_arrow),
                label: Text(isTodayPlanActive ? 'Training beenden' : 'Training starten'),
                style: FilledButton.styleFrom(
                  backgroundColor: brandColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ) ??
                  TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: color.withOpacity(0.9),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        theme.extension<AppBrandTheme>()?.outline ?? theme.colorScheme.secondary;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(value),
      ),
    );
  }
}
