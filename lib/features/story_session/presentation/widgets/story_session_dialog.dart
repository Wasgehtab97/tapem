import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapem/features/story_session/domain/models/story_achievement.dart';
import 'package:tapem/features/story_session/domain/models/story_session_summary.dart';
import 'package:tapem/l10n/app_localizations.dart';

class StorySessionDialog extends StatelessWidget {
  final StorySessionSummary summary;
  final VoidCallback? onShare;

  const StorySessionDialog({super.key, required this.summary, this.onShare});

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
                onShare: onShare,
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
  final VoidCallback? onShare;

  const _StorySessionCard({
    required this.headerTitle,
    required this.headerSubtitle,
    required this.xp,
    required this.stats,
    required this.achievements,
    required this.loc,
    this.onShare,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
            colors: [Color(0xFF31135D), Color(0xFF150A2C)],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x8010021F),
              blurRadius: 36,
              offset: Offset(0, 24),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned(
              left: -76,
              top: -48,
              child: _GlowingBlob(
                size: 220,
                color: Color(0xFF8F5BFF),
                opacity: 0.26,
              ),
            ),
            const Positioned(
              right: -92,
              top: 24,
              child: _GlowingBlob(
                size: 180,
                color: Color(0xFFFF7AD5),
                opacity: 0.18,
              ),
            ),
            const Positioned(
              left: -64,
              bottom: -54,
              child: _GlowingBlob(
                size: 210,
                color: Color(0xFF5225FF),
                opacity: 0.22,
              ),
            ),
            Positioned(
              top: 36,
              left: 32,
              child: _FloatingStar(size: 18, opacity: 0.35),
            ),
            Positioned(
              top: 80,
              right: 44,
              child: _FloatingStar(size: 12, opacity: 0.32),
            ),
            Positioned(
              bottom: 132,
              left: 80,
              child: _FloatingStar(size: 14, opacity: 0.28),
            ),
            Positioned(
              bottom: 60,
              right: 62,
              child: _FloatingStar(size: 22, opacity: 0.4),
            ),
            Positioned(
              top: 48,
              right: 132,
              child: _FloatingStar(size: 10, opacity: 0.28),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
              child: SingleChildScrollView(
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
                            shape: const CircleBorder(),
                            backgroundColor: Colors.white.withOpacity(0.12),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(10),
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
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withOpacity(0.76),
                            textStyle: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                          ),
                          child: Text(loc.commonClose),
                        ),
                        const Spacer(),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6DD6), Color(0xFF815DFF)],
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x661F0438),
                                blurRadius: 18,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: TextButton.icon(
                            onPressed: () {
                              onShare?.call();
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.ios_share_rounded),
                            label: Text(loc.commonShare),
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
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF7B5BFF), Color(0xFFFF6CD8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80170132),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 22,
            left: 38,
            child: _FloatingStar(size: 16, opacity: 0.45, color: Colors.white),
          ),
          Positioned(
            bottom: 22,
            right: 42,
            child: _FloatingStar(size: 20, opacity: 0.38, color: Colors.white),
          ),
          Positioned(
            top: -48,
            right: -60,
            child: _GlowingBlob(
              size: 160,
              color: Colors.white.withOpacity(0.5),
              opacity: 0.12,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${format.format(xp)} XP',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  loc.storySessionDailyXpTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.88),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.25,
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
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x442C1E4A), Color(0x6613172F)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3314022A),
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: valueStyle,
                maxLines: 1,
                softWrap: false,
              ),
            ),
            const SizedBox(height: 10),
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
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF37205E), Color(0xFF281245)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3316032C),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6DD6), Color(0xFF815DFF)],
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
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.72),
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
        final weight = achievement.prWeight;
        final reps = achievement.prReps;
        if (weight != null && reps != null && reps > 0) {
          final numberFormat = NumberFormat('#,##0.##', loc.localeName);
          final repsFormat = NumberFormat.decimalPattern(loc.localeName);
          final weightText = numberFormat.format(weight);
          final repsText = repsFormat.format(reps);
          return loc.storySessionNewPrSubtitle(weightText, repsText);
        }
        final value = achievement.e1rm;
        if (value != null && value > 0) {
          return loc.storySessionNewPrFallback(value.toStringAsFixed(1));
        }
        return null;
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

class _GlowingBlob extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GlowingBlob({
    this.size = 160,
    this.color = const Color(0xFF7B5BFF),
    this.opacity = 0.2,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(opacity), Colors.transparent],
          ),
        ),
      ),
    );
  }
}
