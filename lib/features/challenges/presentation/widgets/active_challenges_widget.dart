import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';

import '../../../../core/providers/challenge_provider.dart';
import '../../domain/models/challenge.dart';

class ActiveChallengesWidget extends ConsumerWidget {
  const ActiveChallengesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeState = ref.watch(challengeProvider);
    final challenges = challengeState.challenges;
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    if (challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              loc.challengeEmptyActive,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: challenges.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) {
        final c = challenges[i];
        final progress = challengeState.progressFor(c.id);
        final target = c.targetCount;
        final ratio = target <= 0 ? 0.0 : (progress / target).clamp(0.0, 1.0);
        return BrandInteractiveCard(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(c.title),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.description),
                    const SizedBox(height: 8),
                    Text(loc.challengeDetailXpReward(c.xpReward)),
                    const SizedBox(height: 8),
                    Text(loc.challengeProgressValue(progress, target)),
                    const SizedBox(height: 8),
                    Text(_goalLabel(loc, c)),
                    if (c.deviceIds.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(loc.challengeDetailDevices(c.deviceIds.join(', '))),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(loc.commonOk),
                  ),
                ],
              ),
            );
          },
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: brandColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Icon(
                  Icons.local_fire_department,
                  color: brandColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _goalLabel(loc, c),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 7,
                        value: ratio,
                        backgroundColor: theme.colorScheme.onSurface
                            .withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(brandColor),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      loc.challengeProgressValue(progress, target),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        border: Border.all(
                          color: theme.colorScheme.onSurface.withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        '+${c.xpReward} XP',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: brandColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _goalLabel(AppLocalizations loc, Challenge challenge) {
    switch (challenge.goalType) {
      case ChallengeGoalType.deviceSets:
        return loc.challengeDetailGoalDeviceSets(challenge.minSets);
      case ChallengeGoalType.workoutDays:
        return loc.challengeDetailGoalWorkoutFrequency(
          challenge.targetWorkouts,
          challenge.durationWeeks,
        );
      case ChallengeGoalType.totalReps:
        return loc.challengeDetailGoalTotalReps(challenge.targetReps);
      case ChallengeGoalType.totalVolume:
        return loc.challengeDetailGoalTotalVolume(challenge.targetVolume);
      case ChallengeGoalType.deviceVariety:
        return loc.challengeDetailGoalDeviceVariety(
          challenge.targetDistinctDevices,
        );
    }
  }
}
