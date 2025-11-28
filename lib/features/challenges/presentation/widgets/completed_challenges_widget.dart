import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/challenge_provider.dart';

class CompletedChallengesWidget extends StatelessWidget {
  const CompletedChallengesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final completed = context.watch<ChallengeProvider>().completed;
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (completed.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.2)),
            const SizedBox(height: AppSpacing.md),
            Text(
              loc.challengeEmptyCompleted,
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
      itemCount: completed.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) {
        final c = completed[i];
        return BrandInteractiveCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
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
                        decoration: TextDecoration.lineThrough,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.yMMMd().format(c.completedAt.toLocal()),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
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
