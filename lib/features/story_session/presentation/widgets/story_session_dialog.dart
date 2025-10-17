import 'package:flutter/material.dart';
import 'package:tapem/features/story_session/domain/models/story_achievement.dart';
import 'package:tapem/features/story_session/domain/models/story_session_summary.dart';
import 'package:tapem/l10n/app_localizations.dart';

class StorySessionDialog extends StatelessWidget {
  final StorySessionSummary summary;

  const StorySessionDialog({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.storySessionTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _XpBanner(xp: summary.totalXp),
              const SizedBox(height: 16),
              ...summary.achievements
                  .where((a) => a.type != StoryAchievementType.dailyXp)
                  .map((achievement) => _AchievementTile(achievement: achievement, loc: loc)),
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
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.storySessionDailyXpTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.storySessionDailyXpValue(xp),
            style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final StoryAchievement achievement;
  final AppLocalizations loc;

  const _AchievementTile({required this.achievement, required this.loc});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _resolveIcon(achievement.type);
    final title = _buildTitle();
    final subtitle = _buildSubtitle();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Icon(icon, color: theme.colorScheme.onSecondaryContainer),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      dense: true,
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
