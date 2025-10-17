import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapem/features/story_session/domain/models/story_achievement.dart';
import 'package:tapem/features/story_session/domain/models/story_session_summary.dart';
import 'package:tapem/l10n/app_localizations.dart';

class StorySessionDialog extends StatelessWidget {
  final StorySessionSummary summary;

  const StorySessionDialog({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final achievements = summary.achievements
        .where((a) => a.type != StoryAchievementType.dailyXp)
        .toList();
    return AlertDialog(
      title: Text(loc.storySessionTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _XpBanner(xp: summary.totalXp),
              const SizedBox(height: 16),
              _StoryStatsRow(stats: summary.stats),
              const SizedBox(height: 24),
              if (achievements.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    loc.storySessionBadgesTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 12),
                _BadgesSection(achievements: achievements, loc: loc),
              ] else ...[
                Text(
                  loc.storySessionEmptyMessage,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.commonClose),
        ),
      ],
    );
  }
}

class _XpBanner extends StatelessWidget {
  final int xp;
  const _XpBanner({required this.xp});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final format = NumberFormat.decimalPattern(loc.localeName);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '${format.format(xp)} XP',
            style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.storySessionDailyXpTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryStatsRow extends StatelessWidget {
  final StorySessionStats stats;

  const _StoryStatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final format = NumberFormat.decimalPattern(loc.localeName);
    final exerciseValue = format.format(stats.exerciseCount);
    final setsValue = format.format(stats.setCount);
    final durationText = _formatDuration(loc, stats.duration);
    final cards = [
      _StoryStatCard(title: loc.storySessionStatsExercisesTitle, value: exerciseValue),
      _StoryStatCard(title: loc.storySessionStatsSetsTitle, value: setsValue),
      _StoryStatCard(title: loc.storySessionStatsDurationTitle, value: durationText),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                cards[i],
              ],
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
            const SizedBox(width: 12),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }

  String _formatDuration(AppLocalizations loc, Duration duration) {
    final totalMinutes = duration.inMinutes;
    if (totalMinutes >= 60) {
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      if (minutes == 0) {
        return loc.storySessionDurationHours(hours);
      }
      return loc.storySessionDurationHoursMinutes(hours, minutes);
    }
    if (totalMinutes > 0) {
      return loc.storySessionDurationMinutes(totalMinutes);
    }
    if (duration.inSeconds > 0) {
      return loc.storySessionDurationMinutes(1);
    }
    return loc.storySessionDurationMinutes(0);
  }
}

class _StoryStatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StoryStatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _BadgesSection extends StatelessWidget {
  final List<StoryAchievement> achievements;
  final AppLocalizations loc;

  const _BadgesSection({required this.achievements, required this.loc});

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) {
      return const SizedBox.shrink();
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 260),
      child: Scrollbar(
        thumbVisibility: achievements.length > 6,
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: achievements
                .map((achievement) =>
                    _StoryBadgeChip(achievement: achievement, loc: loc))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _StoryBadgeChip extends StatelessWidget {
  final StoryAchievement achievement;
  final AppLocalizations loc;

  const _StoryBadgeChip({required this.achievement, required this.loc});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _resolveIcon(achievement.type);
    final title = _buildTitle();
    final subtitle = _buildSubtitle();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon,
                color: theme.colorScheme.onSecondaryContainer, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _resolveIcon(StoryAchievementType type) {
    switch (type) {
      case StoryAchievementType.newDevice:
        return Icons.fitness_center;
      case StoryAchievementType.newExercise:
        return Icons.self_improvement;
      case StoryAchievementType.personalRecord:
        return Icons.military_tech;
      case StoryAchievementType.dailyXp:
        return Icons.star;
    }
  }

  String _buildTitle() {
    switch (achievement.type) {
      case StoryAchievementType.newDevice:
        return loc.storySessionNewDeviceTitle(achievement.deviceName ?? '—');
      case StoryAchievementType.newExercise:
        final device = achievement.deviceName ?? '—';
        final exercise = achievement.exerciseName ?? '—';
        return loc.storySessionNewExerciseTitle(device, exercise);
      case StoryAchievementType.personalRecord:
        final name = achievement.exerciseName ?? achievement.deviceName ?? '—';
        return loc.storySessionNewPrTitle(name);
      case StoryAchievementType.dailyXp:
        return loc.storySessionDailyXpTitle;
    }
  }

  String? _buildSubtitle() {
    switch (achievement.type) {
      case StoryAchievementType.personalRecord:
        final value = achievement.e1rm ?? 0;
        return loc.storySessionNewPrSubtitle(value.toStringAsFixed(1));
      case StoryAchievementType.newDevice:
      case StoryAchievementType.newExercise:
      case StoryAchievementType.dailyXp:
        return null;
    }
  }
}
