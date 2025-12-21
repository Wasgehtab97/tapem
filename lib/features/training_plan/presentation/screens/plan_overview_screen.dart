import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/app_error_card.dart';
import 'package:tapem/core/widgets/app_loading_indicator.dart';
import 'package:tapem/core/widgets/brand_gradient_icon.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/features/training_plan/presentation/widgets/plan_color_palette.dart';
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Trainingspläne',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        foregroundColor: brandColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              Color.alphaBlend(
                brandColor.withOpacity(0.07),
                theme.scaffoldBackgroundColor,
              ),
            ],
          ),
        ),
        child: plansAsync.when(
          data: (plans) {
            if (plans.isEmpty) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            brandColor.withOpacity(0.18),
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  brandColor.withOpacity(0.6),
                                  brandColor.withOpacity(0.08),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.assignment_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Dein erster Plan wartet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Erstelle einen Trainingsplan und bring Struktur in dein Workout.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: () => _createNewPlan(context, ref),
                            icon: const Icon(Icons.add),
                            label: const Text('Ersten Plan erstellen'),
                            style: FilledButton.styleFrom(
                              backgroundColor: brandColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Pläne helfen dir dabei, konsistent Fortschritte zu tracken.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        letterSpacing: 0.4,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: plans.length,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              itemBuilder: (context, index) {
                final plan = plans[index];
                final isCoachPlan =
                    plan.coachId != null && plan.coachId != authState.userId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _PlanCard(
                    name: plan.name,
                    exerciseCount: plan.exercises.length,
                    isCoachPlan: isCoachPlan,
                    colorIndex: plan.colorIndex,
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
          loading: () => const AppLoadingIndicator(),
          error: (err, stack) => AppErrorCard(
            message: 'Fehler beim Laden der Pläne:\n$err',
            onRetry: () => ref.invalidate(trainingPlansProvider),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewPlan(context, ref),
        backgroundColor: brandColor,
        child: const Icon(Icons.add, color: Colors.white),
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
    required this.colorIndex,
    required this.onTap,
  });

  final String name;
  final int exerciseCount;
  final bool isCoachPlan;
  final int colorIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final brandColor =
        PlanColorPalette.colorForIndex(colorIndex, theme);
    final cardRadius = BorderRadius.circular(24);

    return BrandInteractiveCard(
      onTap: onTap,
      borderRadius: cardRadius,
      backgroundColor: Colors.transparent,
      restingBorderColor: Colors.transparent,
      activeBorderColor: Colors.transparent,
      showShadow: false,
      padding: EdgeInsets.zero,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              brandColor.withOpacity(0.10),
              brandColor.withOpacity(0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: cardRadius,
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: brandColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const BrandGradientIcon(
                Icons.view_list_rounded,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '$exerciseCount ${exerciseCount == 1 ? 'Übung' : 'Übungen'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onSurface.withOpacity(0.5),
                        ),
                      ),
                      if (isCoachPlan) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Coach-Plan',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: onSurface.withOpacity(0.7),
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
