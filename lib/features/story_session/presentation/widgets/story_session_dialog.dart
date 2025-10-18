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
    final date = DateTime.tryParse(summary.dayKey);
    final dateText = date != null
        ? DateFormat.yMMMMd(loc.localeName).format(date)
        : summary.dayKey;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.clamp(320.0, 480.0).toDouble();
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: _StorySessionCard(
                headerTitle: loc.storySessionTitle,
                headerSubtitle: dateText,
                xp: summary.totalXp,
                stats: summary.stats,
                achievements: achievements,
                loc: loc,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StorySessionCard extends StatelessWidget {
  final String headerTitle;
  final String headerSubtitle;
  final int xp;
  final StorySessionStats stats;
  final List<StoryAchievement> achievements;
  final AppLocalizations loc;

  const _StorySessionCard({
    required this.headerTitle,
    required this.headerSubtitle,
    required this.xp,
    required this.stats,
    required this.achievements,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final headlineStyle = textTheme.headlineSmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    );
    final subtitleStyle = textTheme.bodyMedium?.copyWith(
      color: Colors.white.withOpacity(0.72),
      fontWeight: FontWeight.w500,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3F216D), Color(0xFF150926)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 32,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 36,
            left: 24,
            child: _FloatingStar(size: 18, opacity: 0.25),
          ),
          Positioned(
            top: 70,
            right: 36,
            child: _FloatingStar(size: 12, opacity: 0.3),
          ),
          Positioned(
            bottom: 120,
            left: 64,
            child: _FloatingStar(size: 14, opacity: 0.2),
          ),
          Positioned(
            bottom: 48,
            right: 54,
            child: _FloatingStar(size: 20, opacity: 0.35),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(headerTitle, style: headlineStyle),
                          const SizedBox(height: 4),
                          Text(headerSubtitle, style: subtitleStyle),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: loc.commonClose,
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.08),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _XpBanner(xp: xp),
                const SizedBox(height: 24),
                _StoryStatsRow(stats: stats),
                const SizedBox(height: 30),
                if (achievements.isNotEmpty) ...[
                  Text(
                    loc.storySessionBadgesTitle,
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _BadgesSection(achievements: achievements, loc: loc),
                ] else ...[
                  Text(
                    loc.storySessionEmptyMessage,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.65),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF63CE), Color(0xFF7F5CFF)],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x661F0438),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                        textStyle: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(loc.commonClose),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6BD5), Color(0xFF7C5CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80170132),
            blurRadius: 26,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 18,
            left: 32,
            child: _FloatingStar(size: 14, opacity: 0.4, color: Colors.white),
          ),
          Positioned(
            bottom: 18,
            right: 36,
            child: _FloatingStar(size: 18, opacity: 0.35, color: Colors.white),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${format.format(xp)} XP',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.storySessionDailyXpTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
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
    final isCompactLayout = MediaQuery.sizeOf(context).width < 360;
    final cards = [
      _StoryStatCard(
        title: loc.storySessionStatsExercisesTitle,
        value: exerciseValue,
      ),
      _StoryStatCard(
        title: loc.storySessionStatsSetsTitle,
        value: setsValue,
      ),
      _StoryStatCard(
        title: loc.storySessionStatsDurationTitle,
        value: durationText,
      ),
    ];
    if (isCompactLayout) {
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
    final titleStyle = theme.textTheme.bodySmall?.copyWith(
      color: Colors.white.withOpacity(0.65),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );
    final valueStyle = theme.textTheme.titleLarge?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x33222146), Color(0x6613192F)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: valueStyle),
            const SizedBox(height: 8),
            Text(title, style: titleStyle),
          ],
        ),
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
      constraints: const BoxConstraints(maxHeight: 280),
      child: Scrollbar(
        thumbVisibility: achievements.length > 6,
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF2F1B4D), Color(0xFF27113E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x401D0436),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6CD8), Color(0xFF7E5CFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    softWrap: true,
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                        softWrap: true,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
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

class _FloatingStar extends StatelessWidget {
  final double size;
  final double opacity;
  final Color color;

  const _FloatingStar({
    this.size = 16,
    this.opacity = 0.25,
    this.color = const Color(0xFFFFD6FF),
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.auto_awesome,
      size: size,
      color: color.withOpacity(opacity.clamp(0, 1).toDouble()),
    );
  }
}
