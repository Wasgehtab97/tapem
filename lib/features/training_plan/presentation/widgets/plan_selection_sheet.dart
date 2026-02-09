import 'package:flutter/material.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_modal.dart';

class PlanSelectionSheet extends StatelessWidget {
  const PlanSelectionSheet({
    super.key,
    required this.plans,
    required this.currentUserId,
    required this.onSelect,
    this.selectedPlanId,
    this.onClear,
  });

  final List<TrainingPlan> plans;
  final String? currentUserId;
  final ValueChanged<TrainingPlan> onSelect;
  final String? selectedPlanId;
  final VoidCallback? onClear;

  bool _isCoachPlan(TrainingPlan plan) {
    final coachId = plan.coachId;
    if (coachId == null || coachId.isEmpty) {
      return false;
    }
    if (currentUserId == null || currentUserId!.isEmpty) {
      return true;
    }
    return coachId != currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return BrandModalSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandModalHeader(
            icon: Icons.view_list_rounded,
            accent: brandColor,
            title: 'Plan auswählen',
            subtitle: 'Trainingsplan für deinen Start festlegen',
            onClose: () => Navigator.pop(context),
          ),
          if (selectedPlanId != null && onClear != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onClear!();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Plan-Zuweisung entfernen'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (plans.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.sm,
              ),
              child: Text(
                'Du hast aktuell keine aktiven Trainingspläne.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: plans.length,
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  final isCoachPlan = _isCoachPlan(plan);
                  final isSelected = plan.id == selectedPlanId;
                  final subtitle = StringBuffer(
                    '${plan.exercises.length} '
                    '${plan.exercises.length == 1 ? 'Übung' : 'Übungen'}',
                  );
                  if (isCoachPlan) {
                    subtitle.write(' · Coach-Plan');
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: BrandModalOptionCard(
                      title: plan.name,
                      subtitle: subtitle.toString(),
                      icon: Icons.assignment_rounded,
                      accent: brandColor,
                      highlighted: isSelected,
                      trailing: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.arrow_forward_rounded,
                        color: isSelected
                            ? brandColor
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        onSelect(plan);
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
