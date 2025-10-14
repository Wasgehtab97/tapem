import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/profile_provider.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/utils/duration_format.dart';
import 'package:tapem/features/profile/presentation/providers/session_story_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';

Future<void> showSessionStoryDialog({
  required BuildContext context,
  required DateTime date,
  required String userId,
  required String gymId,
  required ProfileProvider profileProvider,
  String? gymName,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    pageBuilder: (_, __, ___) {
      return ChangeNotifierProvider<SessionStoryProvider>(
        create: (_) => SessionStoryProvider(profileProvider: profileProvider)
          ..load(
            userId: userId,
            gymId: gymId,
            date: date,
            gymName: gymName,
          ),
        child: const _SessionStoryOverlay(),
      );
    },
    transitionBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

class _SessionStoryOverlay extends StatelessWidget {
  const _SessionStoryOverlay();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.black.withOpacity(0.65),
      child: SafeArea(
        child: GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Stack(
            children: [
              const SizedBox.expand(),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF6C2CF6),
                              Color(0xFFB14BFF),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.45),
                              blurRadius: 24,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: _SessionStoryContent(theme: theme),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionStoryContent extends StatelessWidget {
  const _SessionStoryContent({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Consumer<SessionStoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return SizedBox(
              height: 300,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            );
          }
          if (provider.error != null) {
            return _SessionStoryError(message: provider.error!);
          }
          final story = provider.story;
          if (story == null) {
            return _SessionStoryError(message: loc.sessionStoryEmptyState);
          }
          return _SessionStoryCard(story: story);
        },
      ),
    );
  }
}

class _SessionStoryError extends StatelessWidget {
  const _SessionStoryError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final onBrand = Theme.of(context).colorScheme.onPrimary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, color: onBrand),
        const SizedBox(height: AppSpacing.sm),
        Text(
          loc.sessionStoryErrorTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: onBrand,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          message,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: onBrand.withOpacity(0.85)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          style: TextButton.styleFrom(foregroundColor: onBrand),
          child: Text(loc.sessionStoryCloseButton),
        ),
      ],
    );
  }
}

class _SessionStoryCard extends StatelessWidget {
  const _SessionStoryCard({required this.story});

  final SessionStoryData story;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final onBrand = Theme.of(context).colorScheme.onPrimary;
    final dateFormat = DateFormat.yMMMMd(loc.localeName);
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: onBrand,
          fontWeight: FontWeight.bold,
        );
    final captionStyle = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: onBrand.withOpacity(0.8));

    return Stack(
      children: [
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: Icon(Icons.close, color: onBrand),
            tooltip: loc.sessionStoryCloseButton,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Text(loc.sessionStoryTitle, style: titleStyle),
            const SizedBox(height: AppSpacing.xs),
            Text(
              dateFormat.format(story.date),
              style: captionStyle,
            ),
            if (story.gymName != null && story.gymName!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                story.gymName!,
                style: captionStyle,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _SessionStoryXpHighlight(xp: story.xp),
            const SizedBox(height: AppSpacing.lg),
            _SessionStoryStatsRow(story: story),
            const SizedBox(height: AppSpacing.lg),
            Text(
              loc.sessionStoryBadgesLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: onBrand,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SessionStoryBadges(badges: story.badges),
          ],
        ),
      ],
    );
  }
}

class _SessionStoryXpHighlight extends StatelessWidget {
  const _SessionStoryXpHighlight({required this.xp});

  final int xp;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final onBrand = Theme.of(context).colorScheme.onPrimary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$xp',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: onBrand,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            loc.sessionStoryDailyXpLabel,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: onBrand.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }
}

class _SessionStoryStatsRow extends StatelessWidget {
  const _SessionStoryStatsRow({required this.story});

  final SessionStoryData story;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final onBrand = Theme.of(context).colorScheme.onPrimary;
    final durationText = story.totalDuration.inMinutes <= 0
        ? '—'
        : formatDurationHm(story.totalDuration);
    final volumeText = story.totalVolumeKg <= 0
        ? '—'
        : story.totalVolumeKg >= 1000
            ? '${(story.totalVolumeKg / 1000).toStringAsFixed(1)} t'
            : '${story.totalVolumeKg.toStringAsFixed(1)} kg';

    Widget buildStat(String label, String value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: onBrand,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: onBrand.withOpacity(0.75)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        buildStat(loc.sessionStorySetsLabel, story.totalSets.toString()),
        const SizedBox(width: AppSpacing.sm),
        buildStat(loc.sessionStoryDurationLabel, durationText),
        const SizedBox(width: AppSpacing.sm),
        buildStat(loc.sessionStoryVolumeLabel, volumeText),
      ],
    );
  }
}

class _SessionStoryBadges extends StatelessWidget {
  const _SessionStoryBadges({required this.badges});

  final List<SessionStoryBadge> badges;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final onBrand = Theme.of(context).colorScheme.onPrimary;
    if (badges.isEmpty) {
      return Text(
        loc.sessionStoryNoBadges,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: onBrand.withOpacity(0.7)),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: badges.map((badge) {
        final isRecord = badge.type == SessionStoryBadgeType.recordE1rm;
        final title = () {
          switch (badge.type) {
            case SessionStoryBadgeType.firstDevice:
              return loc.sessionStoryBadgeFirstDevice;
            case SessionStoryBadgeType.firstExercise:
              return loc.sessionStoryBadgeFirstExercise;
            case SessionStoryBadgeType.recordE1rm:
              return loc.sessionStoryBadgeRecord;
          }
        }();
        final metricText = isRecord && badge.metricKg != null
            ? '${badge.metricKg!.toStringAsFixed(1)} kg'
            : null;
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: onBrand.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                badge.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: onBrand,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (metricText != null) ...[
                const SizedBox(height: 2),
                Text(
                  metricText,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: onBrand.withOpacity(0.75)),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
