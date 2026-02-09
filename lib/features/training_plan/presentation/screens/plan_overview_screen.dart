import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/app_error_card.dart';
import 'package:tapem/core/widgets/app_loading_indicator.dart';
import 'package:tapem/core/widgets/brand_modal.dart';
import 'package:tapem/core/widgets/brand_primary_button.dart';
import 'package:tapem/core/widgets/premium_action_tile.dart';
import 'package:tapem/features/training_plan/presentation/widgets/plan_color_palette.dart';
import 'package:tapem/features/training_plan/application/plan_builder_provider.dart';
import 'package:tapem/features/training_plan/application/training_plan_provider.dart';

class PlanOverviewScreen extends ConsumerWidget {
  const PlanOverviewScreen({super.key, this.onExitToProfile});

  final VoidCallback? onExitToProfile;

  void _handleBackPressed(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    onExitToProfile?.call();
  }

  Widget? _buildLeadingBackButton(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    if (!canPop && onExitToProfile == null) {
      return null;
    }
    return IconButton(
      onPressed: () => _handleBackPressed(context),
      icon: const Icon(Icons.chevron_left_rounded),
    );
  }

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
        automaticallyImplyLeading: false,
        leading: _buildLeadingBackButton(context),
        title: Text(
          'Trainingspläne',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        foregroundColor: brandColor,
      ),
      body: plansAsync.when(
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
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewPlan(context, ref),
        backgroundColor: brandColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _createNewPlan(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const _CreatePlanDialog(),
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

class _CreatePlanDialog extends StatefulWidget {
  const _CreatePlanDialog();

  @override
  State<_CreatePlanDialog> createState() => _CreatePlanDialogState();
}

class _CreatePlanDialogState extends State<_CreatePlanDialog> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    final canCreate = _nameController.text.trim().isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: BrandModalSurface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BrandModalHeader(
              icon: Icons.assignment_rounded,
              accent: brandColor,
              title: 'Neuer Trainingsplan',
              subtitle: 'Gib deinem Plan einen Namen',
              onClose: () => Navigator.pop(context),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameController,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                final value = _nameController.text.trim();
                if (value.isEmpty) return;
                Navigator.pop(context, value);
              },
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Name (z.B. Push Day)',
                filled: true,
                fillColor: Colors.white.withOpacity(0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: brandColor.withOpacity(0.4),
                    width: 1.2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: brandColor.withOpacity(0.9),
                    width: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Abbrechen'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BrandPrimaryButton(
                    onPressed: canCreate
                        ? () => Navigator.pop(
                            context,
                            _nameController.text.trim(),
                          )
                        : null,
                    child: const Text(
                      'Erstellen',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
    final tileAccent =
        theme.extension<AppBrandTheme>()?.outline ??
        theme.colorScheme.secondary;
    final arrowColor = PlanColorPalette.colorForIndex(colorIndex, theme);
    final subtitle = StringBuffer(
      '$exerciseCount ${exerciseCount == 1 ? 'Übung' : 'Übungen'}',
    );
    if (isCoachPlan) {
      subtitle.write(' · Coach-Plan');
    }

    return PremiumActionTile(
      onTap: onTap,
      leading: const Icon(Icons.view_list_rounded, size: 20),
      title: name,
      subtitle: subtitle.toString(),
      accentColor: tileAccent,
      trailingColor: arrowColor,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
    );
  }
}
