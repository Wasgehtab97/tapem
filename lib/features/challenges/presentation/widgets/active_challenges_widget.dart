import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';

import '../../../../core/providers/challenge_provider.dart';

class ActiveChallengesWidget extends StatelessWidget {
  const ActiveChallengesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final challenges = context.watch<ChallengeProvider>().challenges;
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    if (challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.2)),
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
        return BrandInteractiveCard(
          onTap: () {
            showDialog(
              context: context,
              builder:
                  (_) => AlertDialog(
                    title: Text(c.title),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.description),
                        const SizedBox(height: 8),
                        Text(loc.challengeDetailXpReward(c.xpReward)),
                        const SizedBox(height: 8),
                        Text(loc.challengeDetailDevices(c.deviceIds.join(', '))),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
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
}
