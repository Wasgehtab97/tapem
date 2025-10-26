import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/brand_on_colors.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/story_session/domain/models/story_achievement.dart';
import 'package:tapem/features/story_session/domain/models/story_daily_xp.dart';
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
                dailyXp: summary.dailyXp,
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
  final StoryDailyXp dailyXp;
  final StorySessionStats stats;
  final List<StoryAchievement> achievements;
  final AppLocalizations loc;
  final VoidCallback? onShare;

  const _StorySessionCard({
    required this.headerTitle,
    required this.headerSubtitle,
    required this.dailyXp,
    required this.stats,
    required this.achievements,
    required this.loc,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _StorySessionPalette.fromTheme(theme);
    final textTheme = theme.textTheme;
    final headlineStyle = textTheme.headlineSmall?.copyWith(
      color: palette.onCardPrimary,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    );
    final subtitleStyle = textTheme.bodyMedium?.copyWith(
      color: palette.onCardSecondary,
      fontWeight: FontWeight.w500,
    );
    final hasBreakdown = dailyXp.components.isNotEmpty || dailyXp.penalties.isNotEmpty;
    return ClipRRect(
      borderRadius: palette.cardRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: palette.cardRadius,
            gradient: palette.cardBackground,
            border: Border.all(color: palette.cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: palette.cardShadow,
                blurRadius: 42,
                offset: const Offset(0, 28),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: palette.cardRadius,
                    gradient: palette.cardHighlight,
                  ),
                ),
              ),
              Positioned(
                left: -76,
                top: -48,
                child: _GlowingBlob(
                  size: 220,
                  color: palette.glowColors[0],
                  opacity: 0.26,
                ),
              ),
              Positioned(
                right: -92,
                top: 24,
                child: _GlowingBlob(
                  size: 180,
                  color: palette.glowColors[1 % palette.glowColors.length],
                  opacity: 0.18,
                ),
              ),
              Positioned(
                left: -64,
                bottom: -54,
                child: _GlowingBlob(
                  size: 210,
                  color: palette.glowColors[2 % palette.glowColors.length],
                  opacity: 0.22,
                ),
              ),
              Positioned(
                top: 36,
                left: 32,
                child: _FloatingStar(
                  size: 18,
                  opacity: 0.35,
                  color: palette.starColors[0 % palette.starColors.length],
                ),
              ),
              Positioned(
                top: 80,
                right: 44,
                child: _FloatingStar(
                  size: 12,
                  opacity: 0.32,
                  color: palette.starColors[1 % palette.starColors.length],
                ),
              ),
              Positioned(
                bottom: 132,
                left: 80,
                child: _FloatingStar(
                  size: 14,
                  opacity: 0.28,
                  color: palette.starColors[2 % palette.starColors.length],
                ),
              ),
              Positioned(
                bottom: 60,
                right: 62,
                child: _FloatingStar(
                  size: 22,
                  opacity: 0.4,
                  color: palette.starColors[3 % palette.starColors.length],
                ),
              ),
              Positioned(
                top: 48,
                right: 132,
                child: _FloatingStar(
                  size: 10,
                  opacity: 0.28,
                  color: palette.starColors[1 % palette.starColors.length],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(36, 36, 36, 32),
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
                              backgroundColor: palette.closeButtonBackground,
                              foregroundColor: palette.onCardPrimary,
                              padding: const EdgeInsets.all(10),
                            ),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _XpBanner(dailyXp: dailyXp, palette: palette),
                      if (hasBreakdown) ...[
                        const SizedBox(height: 24),
                        _XpBreakdownSection(
                          dailyXp: dailyXp,
                          palette: palette,
                        ),
                      ],
                      const SizedBox(height: 24),
                      _StoryStatsRow(stats: stats, palette: palette),
                      const SizedBox(height: 30),
                      if (achievements.isNotEmpty) ...[
                        Text(
                          loc.storySessionBadgesTitle,
                          style: textTheme.titleMedium?.copyWith(
                            color: palette.onCardPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _BadgesSection(
                          achievements: achievements,
                          loc: loc,
                          palette: palette,
                        ),
                      ] else ...[
                        Text(
                          loc.storySessionEmptyMessage,
                          style: textTheme.bodyMedium?.copyWith(
                            color: palette.emptyState,
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: palette.onCardSecondary,
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
                              borderRadius: palette.shareRadius,
                              gradient: palette.shareGradient,
                              boxShadow: palette.shareShadow,
                            ),
                            child: TextButton.icon(
                              onPressed: () {
                                onShare?.call();
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.ios_share_rounded),
                              label: Text(loc.commonShare),
                              style: TextButton.styleFrom(
                                foregroundColor: palette.onGradientPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: palette.shareRadius,
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
      ),
    );
  }
}

class _XpBanner extends StatelessWidget {
  final StoryDailyXp dailyXp;
  final _StorySessionPalette palette;

  const _XpBanner({required this.dailyXp, required this.palette});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final format = NumberFormat.decimalPattern(loc.localeName);
    final theme = Theme.of(context);
    final netDelta = dailyXp.netXpDelta ?? (dailyXp.xp + dailyXp.penaltySum);
    final previousTotal = dailyXp.previousTotalXp;
    final resultingTotal = dailyXp.totalXp ??
        dailyXp.computedTotalXp ??
        dailyXp.runningTotalXp ??
        (previousTotal != null ? previousTotal + netDelta : null);
    final netText = '${_formatSignedInt(netDelta, format)} XP';
    final previousText = previousTotal != null ? format.format(previousTotal) : null;
    final resultingText = resultingTotal != null ? format.format(resultingTotal) : null;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: palette.xpRadius,
        gradient: palette.xpBanner,
        border: Border.all(color: palette.xpBorder),
        boxShadow: [
          BoxShadow(
            color: palette.xpShadow,
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 22,
            left: 38,
            child: _FloatingStar(
              size: 16,
              opacity: 0.45,
              color: palette.onGradientPrimary,
            ),
          ),
          Positioned(
            bottom: 22,
            right: 42,
            child: _FloatingStar(
              size: 20,
              opacity: 0.38,
              color: palette.onGradientPrimary,
            ),
          ),
          Positioned(
            top: -48,
            right: -60,
            child: _GlowingBlob(
              size: 160,
              color: palette.glowColors.last,
              opacity: 0.18,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  loc.storySessionDailyXpNetLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: palette.onGradientMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.25,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  netText,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: palette.onGradientPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                if (dailyXp.floorApplied) ...[
                  const SizedBox(height: 8),
                  Text(
                    loc.storySessionDailyXpFloorAppliedNotice,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.onGradientMuted,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
                if (previousText != null || resultingText != null) ...[
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 28,
                    runSpacing: 12,
                    children: [
                      if (previousText != null)
                        _XpBannerStat(
                          label: loc.storySessionDailyXpPreviousTotalLabel,
                          value: '$previousText XP',
                          palette: palette,
                        ),
                      if (resultingText != null)
                        _XpBannerStat(
                          label: loc.storySessionDailyXpResultingTotalLabel,
                          value: '$resultingText XP',
                          palette: palette,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _XpBannerStat extends StatelessWidget {
  final String label;
  final String value;
  final _StorySessionPalette palette;

  const _XpBannerStat({
    required this.label,
    required this.value,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: palette.onGradientMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: palette.onGradientPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _XpBreakdownSection extends StatelessWidget {
  final StoryDailyXp dailyXp;
  final _StorySessionPalette palette;

  const _XpBreakdownSection({required this.dailyXp, required this.palette});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final format = NumberFormat.decimalPattern(loc.localeName);

    final componentLines = dailyXp.components
        .where((component) => component.amount != 0)
        .map(
          (component) => _XpBreakdownLine(
            label: _componentLabel(component, loc),
            subtitle: _componentSubtitle(component, loc),
            amount: component.amount,
            isPenalty: component.amount < 0,
          ),
        )
        .toList();

    final penaltyLines = dailyXp.penalties
        .where((penalty) => penalty.delta < 0)
        .map(
          (penalty) => _XpBreakdownLine(
            label: _penaltyLabel(penalty, loc),
            subtitle: _penaltySubtitle(penalty, loc),
            amount: penalty.delta,
            isPenalty: true,
          ),
        )
        .toList();

    final children = <Widget>[];
    for (var i = 0; i < componentLines.length; i++) {
      if (i != 0) {
        children.add(_XpBreakdownDivider(palette: palette));
      }
      children.add(
        _XpBreakdownRow(
          line: componentLines[i],
          palette: palette,
          format: format,
        ),
      );
    }

    if (penaltyLines.isNotEmpty) {
      if (children.isNotEmpty) {
        children.add(_XpBreakdownDivider(palette: palette));
      }
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text(
            loc.storySessionDailyXpPenaltyTitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.onCardSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      );
      for (var i = 0; i < penaltyLines.length; i++) {
        if (i != 0) {
          children.add(_XpBreakdownDivider(palette: palette));
        }
        children.add(
          _XpBreakdownRow(
            line: penaltyLines[i],
            palette: palette,
            format: format,
          ),
        );
      }
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final borderColor = palette.cardBorder.withOpacity(0.28);
    final backgroundColor = palette.cardBorder.withOpacity(0.18);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.storySessionDailyXpBreakdownTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            color: palette.onCardPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: 16),
        _XpReconciliationFooter(
          dailyXp: dailyXp,
          palette: palette,
        ),
      ],
    );
  }
}

class _XpBreakdownDivider extends StatelessWidget {
  final _StorySessionPalette palette;

  const _XpBreakdownDivider({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: palette.cardBorder.withOpacity(0.16),
    );
  }
}

class _XpReconciliationFooter extends StatelessWidget {
  final StoryDailyXp dailyXp;
  final _StorySessionPalette palette;

  const _XpReconciliationFooter({required this.dailyXp, required this.palette});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final format = NumberFormat.decimalPattern(loc.localeName);
    final theme = Theme.of(context);
    final gross = dailyXp.xp;
    final penalties = dailyXp.penaltySum;
    final result = dailyXp.totalXp ??
        dailyXp.computedTotalXp ??
        dailyXp.runningTotalXp ??
        (dailyXp.previousTotalXp != null && dailyXp.netXpDelta != null
            ? dailyXp.previousTotalXp! + dailyXp.netXpDelta!
            : null);
    final tiles = <Widget>[
      _XpSummaryTile(
        label: loc.storySessionDailyXpGrossLabel,
        value: '${format.format(gross)} XP',
        palette: palette,
        theme: theme.textTheme,
      ),
      _XpSummaryTile(
        label: loc.storySessionDailyXpPenaltiesLabel,
        value: '${_formatSignedInt(penalties, format)} XP',
        palette: palette,
        theme: theme.textTheme,
        isPenalty: penalties < 0,
      ),
      if (result != null)
        _XpSummaryTile(
          label: loc.storySessionDailyXpResultingTotalLabel,
          value: '${format.format(result)} XP',
          palette: palette,
          theme: theme.textTheme,
        ),
    ];

    if (tiles.length < 2) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.cardBorder.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 360;
            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    tiles[i],
                  ],
                ],
              );
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  Expanded(child: tiles[i]),
                  if (i < tiles.length - 1) const SizedBox(width: 12),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _XpSummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final _StorySessionPalette palette;
  final TextTheme theme;
  final bool isPenalty;

  const _XpSummaryTile({
    required this.label,
    required this.value,
    required this.palette,
    required this.theme,
    this.isPenalty = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.bodySmall?.copyWith(
            color: palette.onCardSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.titleMedium?.copyWith(
            color: isPenalty
                ? palette.onCardSecondary
                : palette.onCardPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

String _formatSignedInt(int value, NumberFormat format) {
  if (value > 0) {
    return '+${format.format(value)}';
  }
  if (value < 0) {
    return '-${format.format(value.abs())}';
  }
  return format.format(0);
}

class _XpBreakdownRow extends StatelessWidget {
  final _XpBreakdownLine line;
  final _StorySessionPalette palette;
  final NumberFormat format;

  const _XpBreakdownRow({
    required this.line,
    required this.palette,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final amount = line.amount;
    final formatted = '${amount >= 0 ? '+' : ''}${format.format(amount)} XP';
    final valueColor = line.isPenalty
        ? theme.colorScheme.error
        : palette.onCardPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.label,
                  style: textTheme.bodyLarge?.copyWith(
                    color: palette.onCardPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (line.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    line.subtitle!,
                    style: textTheme.bodySmall?.copyWith(
                      color: palette.onCardSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            formatted,
            style: textTheme.bodyLarge?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _XpBreakdownLine {
  final String label;
  final String? subtitle;
  final int amount;
  final bool isPenalty;

  const _XpBreakdownLine({
    required this.label,
    this.subtitle,
    required this.amount,
    this.isPenalty = false,
  });
}

String _componentLabel(StoryXpComponent component, AppLocalizations loc) {
  switch (component.code) {
    case 'base_daily':
      return loc.storySessionDailyXpComponentBase;
    case 'comeback_bonus':
      return loc.storySessionDailyXpComponentComeback;
    case 'streak_bonus':
      return loc.storySessionDailyXpComponentStreak;
    case 'training_day_milestone':
      return loc.storySessionDailyXpComponentMilestone;
    default:
      return loc.storySessionDailyXpComponentUnknown;
  }
}

String? _componentSubtitle(StoryXpComponent component, AppLocalizations loc) {
  final metadata = component.metadata;
  switch (component.code) {
    case 'base_daily':
      final dayIndex = (metadata['trainingDayIndex'] as num?)?.toInt();
      if (dayIndex != null && dayIndex > 0) {
        return loc.storySessionDailyXpComponentBaseSubtitle(dayIndex);
      }
      break;
    case 'streak_bonus':
      final streak = (metadata['streakLength'] as num?)?.toInt();
      if (streak != null && streak > 0) {
        return loc.storySessionDailyXpComponentStreakSubtitle(streak);
      }
      break;
    case 'training_day_milestone':
      final milestone = (metadata['milestoneDay'] as num?)?.toInt();
      if (milestone != null && milestone > 0) {
        return loc.storySessionDailyXpComponentMilestoneSubtitle(milestone);
      }
      break;
  }
  return null;
}

String _penaltyLabel(StoryXpPenalty penalty, AppLocalizations loc) {
  switch (penalty.type) {
    case 'streakBreakPenalty':
      return loc.storySessionDailyXpPenaltyStreakBreak;
    case 'missedWeekPenalty':
      return loc.storySessionDailyXpPenaltyMissedWeek;
    default:
      return loc.storySessionDailyXpPenaltyGeneric;
  }
}

String? _penaltySubtitle(StoryXpPenalty penalty, AppLocalizations loc) {
  final metadata = penalty.metadata;
  final idleDays = (metadata['idleDays'] as num?)?.toInt();
  final week = (metadata['missedWeekNumber'] as num?)?.toInt();
  switch (penalty.type) {
    case 'streakBreakPenalty':
      if (idleDays != null && idleDays > 0) {
        return loc.storySessionDailyXpPenaltyIdleDays(idleDays);
      }
      break;
    case 'missedWeekPenalty':
      final segments = <String>[];
      if (week != null && week > 0) {
        segments.add(loc.storySessionDailyXpPenaltyWeekLabel(week));
      }
      if (idleDays != null && idleDays > 0) {
        segments.add(loc.storySessionDailyXpPenaltyIdleDays(idleDays));
      }
      if (segments.isNotEmpty) {
        return segments.join(' · ');
      }
      break;
    default:
      if (idleDays != null && idleDays > 0) {
        return loc.storySessionDailyXpPenaltyIdleDays(idleDays);
      }
      break;
  }
  return null;
}

class _StoryStatsRow extends StatelessWidget {
  final StorySessionStats stats;
  final _StorySessionPalette palette;

  const _StoryStatsRow({required this.stats, required this.palette});

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
        palette: palette,
      ),
      _StoryStatCard(
        title: loc.storySessionStatsSetsTitle,
        value: setsValue,
        palette: palette,
      ),
      _StoryStatCard(
        title: loc.storySessionStatsDurationTitle,
        value: durationText,
        palette: palette,
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
  final _StorySessionPalette palette;

  const _StoryStatCard({required this.title, required this.value, required this.palette});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.bodySmall?.copyWith(
      color: palette.onCardMuted,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );
    final valueStyle = theme.textTheme.titleLarge?.copyWith(
      color: palette.onCardPrimary,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: palette.statRadius,
        gradient: palette.statCardBackground,
        border: Border.all(color: palette.statBorder),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 12),
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

class _BadgesSection extends StatefulWidget {
  final List<StoryAchievement> achievements;
  final AppLocalizations loc;
  final _StorySessionPalette palette;

  const _BadgesSection({
    required this.achievements,
    required this.loc,
    required this.palette,
  });

  @override
  State<_BadgesSection> createState() => _BadgesSectionState();
}

class _BadgesSectionState extends State<_BadgesSection> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievements = widget.achievements;
    if (achievements.isEmpty) {
      return const SizedBox.shrink();
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 280),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: achievements.length > 6,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: achievements
                .map((achievement) => _StoryBadgeChip(
                      achievement: achievement,
                      loc: widget.loc,
                      palette: widget.palette,
                    ))
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
  final _StorySessionPalette palette;

  const _StoryBadgeChip({
    required this.achievement,
    required this.loc,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _resolveIcon(achievement.type);
    final title = _buildTitle();
    final subtitle = _buildSubtitle();
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: palette.badgeRadius,
        gradient: palette.badgeBackground,
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow.withOpacity(0.32),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(color: palette.badgeBorder),
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
                gradient: palette.badgeIconBackground,
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  icon,
                  color: palette.onGradientPrimary,
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
                      color: palette.onCardPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    softWrap: true,
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.onCardSecondary,
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

class _StorySessionPalette {
  final LinearGradient cardBackground;
  final LinearGradient xpBanner;
  final LinearGradient statCardBackground;
  final LinearGradient badgeBackground;
  final LinearGradient badgeIconBackground;
  final LinearGradient shareGradient;
  final Color cardBorder;
  final Color cardShadow;
  final Color closeButtonBackground;
  final Color onCardPrimary;
  final Color onCardSecondary;
  final Color onCardMuted;
  final Color onGradientPrimary;
  final Color onGradientMuted;
  final Color statBorder;
  final Color badgeBorder;
  final Color emptyState;
  final Color xpBorder;
  final Color xpShadow;
  final List<BoxShadow> shareShadow;
  final List<Color> glowColors;
  final List<Color> starColors;
  final BorderRadius cardRadius;
  final LinearGradient cardHighlight;

  const _StorySessionPalette({
    required this.cardBackground,
    required this.xpBanner,
    required this.statCardBackground,
    required this.badgeBackground,
    required this.badgeIconBackground,
    required this.shareGradient,
    required this.cardBorder,
    required this.cardShadow,
    required this.closeButtonBackground,
    required this.onCardPrimary,
    required this.onCardSecondary,
    required this.onCardMuted,
    required this.onGradientPrimary,
    required this.onGradientMuted,
    required this.statBorder,
    required this.badgeBorder,
    required this.emptyState,
    required this.xpBorder,
    required this.xpShadow,
    required this.shareShadow,
    required this.glowColors,
    required this.starColors,
    required this.cardRadius,
    required this.cardHighlight,
  });

  factory _StorySessionPalette.fromTheme(ThemeData theme) {
    final brandTheme = theme.extension<AppBrandTheme>();
    final onColors = theme.extension<BrandOnColors>();
    final gradient = brandTheme?.gradient ?? AppGradients.brandGradient;
    final colors = gradient.colors;
    final start = colors.first;
    final end = colors.last;
    final mid = Color.lerp(start, end, 0.5)!;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;

    Color mix(Color a, Color b, double t) => Color.lerp(a, b, t) ?? b;
    Color lighten(Color color, double amount) =>
        Color.lerp(color, Colors.white, amount) ?? color;
    Color darken(Color color, double amount) =>
        Color.lerp(color, Colors.black, amount) ?? color;
    Color tintSurface(Color color, double opacity) =>
        Color.alphaBlend(color.withOpacity(opacity), surface);

    final cardBackground = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomRight,
      colors: [
        mix(surface, darken(start, 0.35), 0.75),
        mix(surface, darken(end, 0.45), 0.8),
      ],
    );

    final xpBanner = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        lighten(start, 0.12),
        lighten(end, 0.12),
      ],
    );

    final statCardBackground = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        tintSurface(darken(start, 0.2), 0.35),
        tintSurface(darken(end, 0.2), 0.4),
      ],
    );

    final badgeBackground = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        tintSurface(darken(start, 0.15), 0.45),
        tintSurface(darken(end, 0.2), 0.55),
      ],
    );

    final badgeIconBackground = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        lighten(start, 0.08),
        lighten(end, 0.08),
      ],
    );

    final shareGradient = LinearGradient(
      begin: gradient.begin,
      end: gradient.end,
      colors: [
        lighten(start, 0.05),
        lighten(end, 0.05),
      ],
    );

    final onGradientPrimary =
        onColors?.onGradient ?? brandTheme?.onBrand ?? Colors.black;
    final onGradientMuted = onGradientPrimary.withOpacity(0.82);
    final onCardSecondary = onSurface.withOpacity(0.72);
    final onCardMuted = onSurface.withOpacity(0.65);

    final shareShadow = brandTheme?.shadow ??
        [
          BoxShadow(
            color: darken(mid, 0.6).withOpacity(0.45),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ];

    final exaggeratedRadius = BorderRadius.lerp(
          (brandTheme?.radius as BorderRadius?) ?? BorderRadius.circular(32),
          BorderRadius.circular(56),
          0.75,
        ) ??
        BorderRadius.circular(48);

    return _StorySessionPalette(
      cardBackground: cardBackground,
      xpBanner: xpBanner,
      statCardBackground: statCardBackground,
      badgeBackground: badgeBackground,
      badgeIconBackground: badgeIconBackground,
      shareGradient: shareGradient,
      cardBorder: tintSurface(onSurface, 0.08),
      cardShadow: darken(end, 0.7).withOpacity(0.45),
      closeButtonBackground: tintSurface(mid, 0.5),
      onCardPrimary: onSurface,
      onCardSecondary: onCardSecondary,
      onCardMuted: onCardMuted,
      onGradientPrimary: onGradientPrimary,
      onGradientMuted: onGradientMuted,
      statBorder: tintSurface(onSurface, 0.12),
      badgeBorder: tintSurface(onSurface, 0.14),
      emptyState: onCardSecondary,
      xpBorder: tintSurface(onSurface, 0.14),
      xpShadow: darken(mid, 0.65).withOpacity(0.45),
      shareShadow: shareShadow,
      glowColors: [
        lighten(start, 0.22),
        lighten(end, 0.25),
        lighten(mid, 0.2),
      ],
      starColors: [
        lighten(start, 0.35),
        lighten(end, 0.32),
        lighten(mid, 0.28),
        lighten(end, 0.4),
      ],
      cardRadius: exaggeratedRadius,
      cardHighlight: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.08),
          Colors.white.withOpacity(0.015),
        ],
      ),
    );
  }

  BorderRadius get xpRadius => BorderRadius.circular(
        _clampRadius(cardRadius.topLeft.x + 14, cardRadius.topLeft.x, 72),
      );

  BorderRadius get statRadius => BorderRadius.circular(
        _clampRadius(cardRadius.topLeft.x - 6, 20, 64),
      );

  BorderRadius get badgeRadius => BorderRadius.circular(
        _clampRadius(cardRadius.topLeft.x - 2, 22, 68),
      );

  BorderRadius get shareRadius => BorderRadius.circular(
        _clampRadius(cardRadius.topLeft.x - 10, 24, 60),
      );

  double _clampRadius(double value, double min, double max) =>
      value.clamp(min, max).toDouble();
}
