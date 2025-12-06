import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/features/training_plan/application/plan_builder_provider.dart';
import 'package:tapem/features/training_plan/application/training_plan_provider.dart';

class PlanOverviewScreen extends ConsumerWidget {
  const PlanOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    
    final plansAsync = ref.watch(trainingPlansProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Trainingspläne',
          style: TextStyle(color: brandColor),
        ),
        foregroundColor: brandColor,
      ),
      body: plansAsync.when(
        data: (plans) {
          if (plans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: brandColor.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'Keine Trainingspläne vorhanden',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: brandColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _createNewPlan(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Ersten Plan erstellen'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: plans.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final plan = plans[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${plan.exercises.length} Übungen'),
                  trailing: Icon(Icons.chevron_right, color: brandColor),
                  onTap: () {
                    Navigator.pushNamed(
                      context, 
                      AppRouter.trainingPlanDetail,
                      arguments: plan,
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Fehler: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewPlan(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _createNewPlan(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Neuer Trainingsplan'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Name (z.B. Push Day)',
            filled: true,
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      if (!context.mounted) return;
      
      // Initialize Builder Logic
      ref.read(planBuilderProvider.notifier).startNew();
      ref.read(planBuilderProvider.notifier).updateName(name);

      // Navigate to Exercise Picker (Modified Gym Screen)
      Navigator.pushNamed(context, AppRouter.trainingPlanPicker);
    }
  }
}
