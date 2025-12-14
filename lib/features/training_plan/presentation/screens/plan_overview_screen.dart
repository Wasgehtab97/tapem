import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
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
    final authState = ref.watch(authViewStateProvider);

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
            padding: const EdgeInsets.all(AppSpacing.md),
            itemBuilder: (context, index) {
              final plan = plans[index];
              final isCoachPlan =
                  plan.coachId != null && plan.coachId != authState.userId;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _PlanCard(
                  name: plan.name,
                  exerciseCount: plan.exercises.length,
                  isCoachPlan: isCoachPlan,
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

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.name,
    required this.exerciseCount,
    this.isCoachPlan = false,
    required this.onTap,
  });

  final String name;
  final int exerciseCount;
  final bool isCoachPlan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final radius =
        (brandTheme?.radius ?? BorderRadius.circular(AppRadius.card)) as BorderRadius;
    final onSurface = theme.colorScheme.onSurface;
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return BrandInteractiveCard(
      onTap: onTap,
      borderRadius: radius,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              brandColor.withOpacity(0.08),
              brandColor.withOpacity(0.02),
            ],
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: theme.colorScheme.onSurface.withOpacity(0.05),
                ),
              ),
              child: Icon(
                Icons.view_list_rounded,
                color: brandColor,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$exerciseCount ${exerciseCount == 1 ? 'Übung' : 'Übungen'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onSurface.withOpacity(0.6),
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (isCoachPlan) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: brandColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Coach-Plan',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: brandColor.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    brandColor.withOpacity(0.22),
                    brandColor.withOpacity(0.02),
                  ],
                  center: Alignment.topLeft,
                  radius: 1.0,
                ),
                border: Border.all(
                  color: brandColor.withOpacity(0.4),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_outward_rounded,
                color: brandColor,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
