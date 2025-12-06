import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/gym_provider.dart' hide gymProvider;
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/training_plan/application/plan_builder_provider.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan.dart';
import 'package:tapem/features/device/providers/workout_day_controller_provider.dart';

class PlanDetailScreen extends ConsumerStatefulWidget {
  const PlanDetailScreen({super.key, this.plan});

  final TrainingPlan? plan;

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
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

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(planBuilderProvider);
    final gymState = ref.watch(gymProvider);
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    // Helper map for device names
    final deviceMap = {
      for (final d in gymState.devices) d.uid: d,
    };

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
                          title: Text(deviceName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          // Subtitle for exercise ID if needed?
                          trailing: const Icon(Icons.drag_handle),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: draft.exercises.isEmpty ? null : () async {
          // Start Training
          final auth = ref.read(authViewStateProvider);
          if (auth.userId == null) return;
          
          final controller = ref.read(workoutDayControllerProvider);
          final gymId = auth.gymCode ?? '';
          
          // Add items in normal order effectively?
          // Controller preserves insertion order.
          // UI (WorkoutDaySession) displays them reversed in sessionsFor logic, meaning Last Added is Top.
          // User said "normal müsste bankdrücken unten als erstes stehen".
          // In screenshot, Session 1 is Bottom. Session 3 is Top.
          // This means "First Added" is "Bottom" (Session 1).
          // If I want Plan Exercise #1 (Bankdrücken) to be Session 1 (Bottom):
          // I must add Bankdrücken FIRST.
          // So I should iterate in NORMAL order.
          // Previous code: `draft.exercises.reversed` -> Added Last Plan Item first.
          // So Last Plan Item became Session 1.
          
          for (final item in draft.exercises) {
            controller.addOrFocusSession(
              gymId: gymId,
              deviceId: item.deviceId,
              exerciseId: item.exerciseId,
              userId: auth.userId!,
            );
          }
          
          final firstItem = draft.exercises.firstOrNull;
          
          Navigator.pushNamed(context, AppRouter.workoutDay, arguments: {
            'gymId': gymId,
            'deviceId': firstItem?.deviceId ?? '',
            'exerciseId': firstItem?.exerciseId ?? '',
          });
        },
        label: const Text('Training starten'),
        icon: const Icon(Icons.play_arrow),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
