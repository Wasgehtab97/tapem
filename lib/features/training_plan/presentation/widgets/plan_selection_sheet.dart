import 'package:flutter/material.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';

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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Plan auswählen',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (selectedPlanId != null && onClear != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onClear!();
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Plan-Zuweisung entfernen'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface
                        .withOpacity(0.8),
                  ),
                ),
              ),
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
                    final subtitleParts = <String>[];
                    subtitleParts.add(
                      '${plan.exercises.length} '
                      '${plan.exercises.length == 1 ? 'Übung' : 'Übungen'}',
                    );
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () {
                          Navigator.pop(context);
                          onSelect(plan);
                        },
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                plan.name,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Padding(
                                padding:
                                    const EdgeInsets.only(right: 8),
                                child: Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: brandColor,
                                ),
                              ),
                            if (isCoachPlan)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: brandColor.withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Coach-Plan',
                                  style: theme
                                      .textTheme.bodySmall
                                      ?.copyWith(
                                    color:
                                        brandColor.withOpacity(0.9),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          subtitleParts.join(' · '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.7),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
