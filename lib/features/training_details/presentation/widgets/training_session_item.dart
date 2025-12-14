import 'package:flutter/material.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';
import 'package:tapem/l10n/app_localizations.dart';

class TrainingSessionItem extends StatelessWidget {
  final Session session;
  final int index;
  final VoidCallback? onLongPress;

  const TrainingSessionItem({
    super.key,
    required this.session,
    required this.index,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    final onSurface = theme.colorScheme.onSurface;

    return GestureDetector(
      onLongPress: onLongPress,
      child: BrandInteractiveCard(
        padding: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                brandColor.withOpacity(0.05),
                brandColor.withOpacity(0.01),
              ],
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sequence Number Strip
                Container(
                  width: 40,
                  decoration: BoxDecoration(
                    color: brandColor.withOpacity(0.1),
                    border: Border(
                      right: BorderSide(
                        color: brandColor.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '#$index',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: brandColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Builder(
                                    builder: (_) {
                                      final hasExerciseName =
                                          (session.exerciseName ?? '').isNotEmpty;
                                      final isMulti = session.isMulti;
                                      final title = isMulti && hasExerciseName
                                          ? session.exerciseName!
                                          : session.deviceName;
                                      final subtitle =
                                          isMulti && hasExerciseName
                                              ? session.deviceName
                                              : session.deviceDescription;

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: onSurface,
                                            ),
                                          ),
                                          if (subtitle != null &&
                                              subtitle.isNotEmpty)
                                            Text(
                                              subtitle,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: onSurface
                                                    .withOpacity(0.5),
                                                fontSize: 11,
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // Sets List
                        ...session.sets.asMap().entries.map((entry) {
                          final i = entry.key;
                          final set = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: _SetRow(set: set, index: i + 1),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final SessionSet set;
  final int index;

  const _SetRow({required this.set, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final isBodyweight = set.isBodyweight;
    final loc = isBodyweight ? AppLocalizations.of(context) : null;

    final weightText = () {
      if (!isBodyweight) {
        return '${set.weight.toStringAsFixed(1)} kg';
      }
      final additional = set.weight.abs() < 0.01 ? 0 : set.weight;
      final base = loc?.bodyweightAbbrev ?? 'BW';
      if (additional == 0) {
        return base;
      }
      return '$base + ${additional.toStringAsFixed(1)} kg';
    }();

    final isDropSet = set.dropWeightKg != null &&
        set.dropReps != null &&
        (set.dropWeightKg! > 0 || set.dropReps! > 0);

    return Row(
      children: [
        // Set Number
        SizedBox(
          width: 20,
          child: Text(
            '$index.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: onSurface.withOpacity(0.4),
              fontSize: 11,
            ),
          ),
        ),
        // Weight & Reps
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: onSurface.withOpacity(0.03),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                weightText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: onSurface.withOpacity(0.9),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '×',
                  style: TextStyle(
                    color: onSurface.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                '${set.reps}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: onSurface.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
        if (isDropSet) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.subdirectory_arrow_right,
            size: 14,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 2),
          Text(
            '${set.dropWeightKg!.toStringAsFixed(1)} × ${set.dropReps}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
