import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/utils/duration_format.dart';
import 'package:tapem/features/challenges/domain/models/challenge.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/story_session/domain/models/story_achievement.dart';
import 'package:tapem/features/story_session/domain/models/story_challenge_highlight.dart';
import 'package:tapem/features/story_session/domain/models/story_daily_xp.dart';
import 'package:tapem/features/story_session/domain/models/story_session_summary.dart';
import 'package:tapem/l10n/app_localizations.dart';

class StorySessionDialog extends StatefulWidget {
  const StorySessionDialog({super.key, required this.summary, this.onShare});

  final StorySessionSummary summary;
  final VoidCallback? onShare;

  @override
  State<StorySessionDialog> createState() => _StorySessionDialogState();
}

class _StorySessionDialogState extends State<StorySessionDialog> {
  bool _didCelebrateChallengeCompletion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didCelebrateChallengeCompletion) {
      return;
    }
    final hasCompletedChallenge = widget.summary.challengeHighlights.any(
      (challenge) => challenge.isCompleted,
    );
    if (!hasCompletedChallenge) {
      return;
    }
    _didCelebrateChallengeCompletion = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      HapticFeedback.mediumImpact();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final viewModel = _StorySessionViewModel.fromSummary(
      summary: widget.summary,
      loc: loc,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = math.min(constraints.maxWidth, 500.0).toDouble();
          final maxHeight = math.min(constraints.maxHeight, 640.0).toDouble();
          final compact = maxHeight < 570;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: _SessionHighlightsPanel(
                viewModel: viewModel,
                maxHeight: maxHeight,
                compact: compact,
                onShare: widget.onShare,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SessionHighlightsPanel extends StatelessWidget {
  const _SessionHighlightsPanel({
    required this.viewModel,
    required this.maxHeight,
    required this.compact,
    required this.onShare,
  });

  final _StorySessionViewModel viewModel;
  final double maxHeight;
  final bool compact;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final palette = _SessionHighlightsPalette.fromTheme(theme);

    final titleStyle = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurface,
      letterSpacing: -0.6,
    );

    final dateStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface.withOpacity(0.72),
    );

    final spacing = compact ? 10.0 : 14.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 24),
        child: Container(
          height: maxHeight,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: palette.outline, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.0, -0.45),
                      radius: 1.15,
                      colors: [
                        palette.brand.withOpacity(0.16),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 18 : 20,
                  compact ? 18 : 20,
                  compact ? 18 : 20,
                  compact ? 14 : 16,
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  physics: const ClampingScrollPhysics(),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.storySessionTitle,
                                style: titleStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: palette.softSurface,
                                  border: Border.all(
                                    color: palette.outlineSoft,
                                  ),
                                ),
                                child: Text(
                                  viewModel.dateText,
                                  style: dateStyle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (onShare != null) ...[
                          _ActionIconButton(
                            icon: Icons.ios_share_rounded,
                            tooltip: loc.commonShare,
                            palette: palette,
                            onTap: onShare,
                          ),
                          const SizedBox(width: 8),
                        ],
                        _ActionIconButton(
                          icon: Icons.close_rounded,
                          tooltip: loc.commonClose,
                          palette: palette,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing),
                    _XpHeroCard(
                      viewModel: viewModel,
                      palette: palette,
                      compact: compact,
                      netLabel: loc.storySessionDailyXpNetLabel,
                    ),
                    SizedBox(height: spacing),
                    Row(
                      children: [
                        Expanded(
                          child: _StatBox(
                            icon: Icons.fitness_center_rounded,
                            label: loc.storySessionStatsExercisesTitle,
                            value: viewModel.exerciseText,
                            palette: palette,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatBox(
                            icon: Icons.repeat_rounded,
                            label: loc.storySessionStatsSetsTitle,
                            value: viewModel.setsText,
                            palette: palette,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatBox(
                            icon: Icons.timer_outlined,
                            label: loc.storySessionStatsDurationTitle,
                            value: viewModel.durationText,
                            palette: palette,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing),
                    if (viewModel.challengeHighlights.isNotEmpty) ...[
                      _ChallengeHighlightsCard(
                        viewModel: viewModel,
                        palette: palette,
                        title: loc.leaderboardChallengesTab,
                      ),
                      SizedBox(height: spacing),
                    ],
                    if (viewModel.highlights.isNotEmpty)
                      _HighlightsCard(
                        viewModel: viewModel,
                        palette: palette,
                        title: loc.storySessionBadgesTitle,
                      ),
                    if (viewModel.highlights.isNotEmpty)
                      SizedBox(height: spacing),
                    Row(
                      children: [
                        Expanded(
                          child: _MetaChip(
                            label: viewModel.rewardLabel,
                            value: '+${viewModel.gainsText}',
                            color: palette.positive,
                            palette: palette,
                            onTap: () {
                              _showXpDetailsSheet(
                                context: context,
                                palette: palette,
                                title: viewModel.rewardDetailTitle,
                                rulesetText: viewModel.rulesetText,
                                emptyMessage:
                                    viewModel.rewardDetailEmptyMessage,
                                rows: viewModel.rewardRows,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetaChip(
                            label: loc.storySessionDailyXpPenaltiesLabel,
                            value: '-${viewModel.penaltyText}',
                            color: palette.negative,
                            palette: palette,
                            onTap: () {
                              _showXpDetailsSheet(
                                context: context,
                                palette: palette,
                                title: viewModel.penaltyDetailTitle,
                                rulesetText: viewModel.rulesetText,
                                emptyMessage:
                                    viewModel.penaltyDetailEmptyMessage,
                                rows: viewModel.penaltyRows,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _XpHeroCard extends StatelessWidget {
  const _XpHeroCard({
    required this.viewModel,
    required this.palette,
    required this.compact,
    required this.netLabel,
  });

  final _StorySessionViewModel viewModel;
  final _SessionHighlightsPalette palette;
  final bool compact;
  final String netLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueColor = viewModel.netXp >= 0
        ? palette.positive
        : palette.negative;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 16,
        vertical: compact ? 12 : 14,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: palette.card,
        border: Border.all(color: palette.outlineSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  netLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.72),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: compact ? 4 : 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${viewModel.netXpText} XP',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: valueColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.9,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: compact ? 76 : 84,
            height: compact ? 76 : 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: palette.outlineSoft),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  palette.brand.withOpacity(0.22),
                  palette.brand.withOpacity(0.05),
                ],
              ),
            ),
            child: Icon(
              viewModel.netXp >= 0
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: valueColor,
              size: compact ? 34 : 38,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final String value;
  final _SessionHighlightsPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: palette.card,
        border: Border.all(color: palette.outlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
            color: theme.colorScheme.onSurface.withOpacity(0.65),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.68),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightsCard extends StatelessWidget {
  const _HighlightsCard({
    required this.viewModel,
    required this.palette,
    required this.title,
  });

  final _StorySessionViewModel viewModel;
  final _SessionHighlightsPalette palette;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasManyHighlights = viewModel.highlights.length > 2;
    final highlightTileWidth = math.min(
      MediaQuery.sizeOf(context).width * 0.68,
      280.0,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: palette.card,
        border: Border.all(color: palette.outlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (!hasManyHighlights)
            for (var i = 0; i < viewModel.highlights.length; i++) ...[
              if (i > 0) const SizedBox(height: 6),
              _HighlightRow(item: viewModel.highlights[i], palette: palette),
            ]
          else
            SizedBox(
              height: 84,
              child: ListView.separated(
                key: const ValueKey('highlights-horizontal-list'),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: viewModel.highlights.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) => SizedBox(
                  width: highlightTileWidth,
                  child: _HighlightRow(
                    item: viewModel.highlights[index],
                    palette: palette,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({required this.item, required this.palette});

  final _HighlightItem item;
  final _SessionHighlightsPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: palette.softSurface,
        border: Border.all(color: palette.outlineSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.accent.withOpacity(0.18),
            ),
            child: Icon(item.icon, size: 17, color: item.accent),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.fade,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (item.subtitle != null)
                  Text(
                    item.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.62),
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

class _ChallengeHighlightsCard extends StatelessWidget {
  const _ChallengeHighlightsCard({
    required this.viewModel,
    required this.palette,
    required this.title,
  });

  final _StorySessionViewModel viewModel;
  final _SessionHighlightsPalette palette;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final challenges = viewModel.challengeHighlights;
    final hasManyChallenges = challenges.length > 1;
    final cardWidth = math.min(MediaQuery.sizeOf(context).width * 0.74, 316.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: palette.card,
        border: Border.all(color: palette.outlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (challenges.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: palette.softSurface,
                    border: Border.all(color: palette.outlineSoft),
                  ),
                  child: Text(
                    '${challenges.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (!hasManyChallenges)
            for (var i = 0; i < challenges.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _ChallengeHighlightRow(item: challenges[i], palette: palette),
            ]
          else
            SizedBox(
              height: 136,
              child: ListView.separated(
                key: const ValueKey('challenge-highlights-horizontal-list'),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: challenges.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) => SizedBox(
                  width: cardWidth,
                  child: _ChallengeHighlightRow(
                    item: challenges[index],
                    palette: palette,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChallengeHighlightRow extends StatelessWidget {
  const _ChallengeHighlightRow({required this.item, required this.palette});

  final _ChallengeHighlightItem item;
  final _SessionHighlightsPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: item.isCompleted
            ? Color.alphaBlend(
                item.accent.withOpacity(0.08),
                palette.softSurface,
              )
            : palette.softSurface,
        border: Border.all(
          color: item.isCompleted
              ? item.accent.withOpacity(0.55)
              : palette.outlineSoft,
          width: item.isCompleted ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.accent.withOpacity(0.2),
                ),
                child: Icon(
                  item.isCompleted
                      ? Icons.emoji_events_rounded
                      : Icons.local_fire_department_rounded,
                  size: 16,
                  color: item.accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: item.accent.withOpacity(0.14),
                ),
                child: Text(
                  item.xpLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: item.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (item.goalText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.goalText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0, end: item.progressRatio),
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  minHeight: 7,
                  value: value,
                  backgroundColor: theme.colorScheme.onSurface.withOpacity(
                    0.12,
                  ),
                  valueColor: AlwaysStoppedAnimation<Color>(item.accent),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                item.progressText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.72),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (item.periodText != null && item.periodText!.isNotEmpty)
                Text(
                  item.periodText!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.58),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.value,
    required this.color,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final _SessionHighlightsPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: palette.card,
            border: Border.all(color: palette.outlineSoft),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.62),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurface.withOpacity(0.58),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _XpBreakdownRow extends StatelessWidget {
  const _XpBreakdownRow({required this.item, required this.palette});

  final _XpBreakdownItem item;
  final _SessionHighlightsPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueColor = item.positive ? palette.positive : palette.negative;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: palette.softSurface,
        border: Border.all(color: palette.outlineSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (item.subtitle != null)
                  Text(
                    item.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.62),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.valueText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showXpDetailsSheet({
  required BuildContext context,
  required _SessionHighlightsPalette palette,
  required String title,
  required String rulesetText,
  required String emptyMessage,
  required List<_XpBreakdownItem> rows,
}) {
  final theme = Theme.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          12,
          12,
          12 + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 18),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 420),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: palette.outlineSoft),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rulesetText,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.66),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: rows.isEmpty
                        ? Center(
                            child: Text(
                              emptyMessage,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.62,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.separated(
                            itemCount: rows.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) => _XpBreakdownRow(
                              item: rows[index],
                              palette: palette,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final _SessionHighlightsPalette palette;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.softSurface,
            border: Border.all(color: palette.outlineSoft),
          ),
          child: Icon(icon, color: palette.icon, size: 30),
        ),
      ),
    );
  }
}

class _SessionHighlightsPalette {
  const _SessionHighlightsPalette({
    required this.surface,
    required this.card,
    required this.softSurface,
    required this.outline,
    required this.outlineSoft,
    required this.shadow,
    required this.brand,
    required this.icon,
    required this.positive,
    required this.negative,
  });

  final Color surface;
  final Color card;
  final Color softSurface;
  final Color outline;
  final Color outlineSoft;
  final Color shadow;
  final Color brand;
  final Color icon;
  final Color positive;
  final Color negative;

  factory _SessionHighlightsPalette.fromTheme(ThemeData theme) {
    final brandTheme = theme.extension<AppBrandTheme>();
    final brand = brandTheme?.outline ?? theme.colorScheme.secondary;
    final surface = theme.scaffoldBackgroundColor;
    final error = theme.colorScheme.error;
    final brandAccent = brandTheme?.outlineGradient.colors.last;
    final negativeBase = brandAccent != null
        ? Color.alphaBlend(brandAccent.withOpacity(0.38), error)
        : error;
    final negative =
        Color.lerp(negativeBase, theme.colorScheme.onSurface, 0.08) ??
        negativeBase;

    return _SessionHighlightsPalette(
      surface: Color.alphaBlend(Colors.black.withOpacity(0.08), surface),
      card: surface.withOpacity(0.34),
      softSurface: surface.withOpacity(0.24),
      outline: Colors.white.withOpacity(0.10),
      outlineSoft: Colors.white.withOpacity(0.12),
      shadow: Colors.black.withOpacity(0.56),
      brand: brand,
      icon: theme.colorScheme.onSurface.withOpacity(0.74),
      positive: brand,
      negative: negative,
    );
  }
}

class _StorySessionViewModel {
  const _StorySessionViewModel({
    required this.dateText,
    required this.rewardLabel,
    required this.rewardDetailTitle,
    required this.penaltyDetailTitle,
    required this.rewardDetailEmptyMessage,
    required this.penaltyDetailEmptyMessage,
    required this.rulesetText,
    required this.exerciseText,
    required this.setsText,
    required this.durationText,
    required this.netXp,
    required this.netXpText,
    required this.gainsText,
    required this.penaltyText,
    required this.rewardRows,
    required this.penaltyRows,
    required this.challengeHighlights,
    required this.highlights,
  });

  final String dateText;
  final String rewardLabel;
  final String rewardDetailTitle;
  final String penaltyDetailTitle;
  final String rewardDetailEmptyMessage;
  final String penaltyDetailEmptyMessage;
  final String rulesetText;
  final String exerciseText;
  final String setsText;
  final String durationText;
  final int netXp;
  final String netXpText;
  final String gainsText;
  final String penaltyText;
  final List<_XpBreakdownItem> rewardRows;
  final List<_XpBreakdownItem> penaltyRows;
  final List<_ChallengeHighlightItem> challengeHighlights;
  final List<_HighlightItem> highlights;

  factory _StorySessionViewModel.fromSummary({
    required StorySessionSummary summary,
    required AppLocalizations loc,
  }) {
    final date = DateTime.tryParse(summary.dayKey);
    final dateText = date != null
        ? DateFormat.yMMMMd(loc.localeName).format(date)
        : summary.dayKey;

    final numberFormat = NumberFormat.decimalPattern(loc.localeName);

    final gains = summary.dailyXp.components
        .where((entry) => entry.amount > 0)
        .fold<int>(0, (sum, entry) => sum + entry.amount);
    final gainsResolved = gains > 0 ? gains : math.max(summary.dailyXp.xp, 0);
    final penaltiesResolved = summary.dailyXp.penaltySum.abs();
    final net =
        summary.dailyXp.netXpDelta ??
        (summary.dailyXp.xp + summary.dailyXp.penaltySum);
    final componentRows = _buildComponentItems(
      summary.dailyXp.components,
      loc,
      numberFormat,
    );
    final penaltyRows = _buildPenaltyItems(
      summary.dailyXp.penalties,
      loc,
      numberFormat,
    );
    final challengeHighlightsRaw = List<StoryChallengeHighlight>.from(
      summary.challengeHighlights,
    )..sort(_challengePriorityCompare);
    final challengeHighlights = challengeHighlightsRaw
        .map((challenge) {
          final target = math.max(0, challenge.target);
          final progress = math.max(0, challenge.progress);
          final ratio = target <= 0 ? 0.0 : (progress / target).clamp(0.0, 1.0);
          final accent = challenge.isCompleted
              ? const Color(0xFF85F9B7)
              : const Color(0xFF35D0FF);
          return _ChallengeHighlightItem(
            title: challenge.title.trim().isNotEmpty
                ? challenge.title.trim()
                : _challengeFallbackTitle(loc),
            goalText: _challengeGoalText(challenge, loc),
            progressText: loc.challengeProgressValue(progress, target),
            progressRatio: ratio,
            xpLabel: '+${numberFormat.format(challenge.xpReward)} XP',
            periodText: _challengePeriodText(challenge, loc),
            isCompleted: challenge.isCompleted,
            accent: accent,
          );
        })
        .toList(growable: false);

    final highlightsRaw =
        summary.achievements
            .where(
              (achievement) => achievement.type != StoryAchievementType.dailyXp,
            )
            .toList()
          ..sort(_achievementPriorityCompare);

    final highlights = highlightsRaw
        .map((achievement) {
          switch (achievement.type) {
            case StoryAchievementType.personalRecord:
              final name =
                  achievement.exerciseName ?? achievement.deviceName ?? 'PR';
              return _HighlightItem(
                icon: Icons.workspace_premium_rounded,
                title: _compactPrTitle(name, loc),
                subtitle: _prSubtitle(achievement, loc),
                accent: const Color(0xFFFFD166),
              );
            case StoryAchievementType.newExercise:
              final exercise = achievement.exerciseName ?? '—';
              final device = achievement.deviceName;
              return _HighlightItem(
                icon: Icons.bolt_rounded,
                title: _compactFirstExerciseTitle(exercise, loc),
                subtitle: device,
                accent: const Color(0xFF6DCBFF),
              );
            case StoryAchievementType.newDevice:
              return _HighlightItem(
                icon: Icons.fitness_center_rounded,
                title: _compactNewDeviceTitle(loc),
                subtitle: achievement.deviceName,
                accent: const Color(0xFF85F9B7),
              );
            case StoryAchievementType.dailyXp:
              return _HighlightItem(
                icon: Icons.auto_awesome,
                title: loc.storySessionDailyXpTitle,
                subtitle: null,
                accent: const Color(0xFFFFD166),
              );
          }
        })
        .toList(growable: false);

    return _StorySessionViewModel(
      dateText: dateText,
      rewardLabel: _shortRewardLabel(loc),
      rewardDetailTitle: _rewardDetailTitle(loc),
      penaltyDetailTitle: _penaltyDetailTitle(loc),
      rewardDetailEmptyMessage: _rewardDetailEmptyMessage(loc),
      penaltyDetailEmptyMessage: _penaltyDetailEmptyMessage(loc),
      rulesetText: _resolveRulesetText(summary.dailyXp, loc),
      exerciseText: numberFormat.format(summary.stats.exerciseCount),
      setsText: numberFormat.format(summary.stats.setCount),
      durationText: _formatDuration(summary.stats.duration),
      netXp: net,
      netXpText: _signedValue(net, numberFormat),
      gainsText: '${numberFormat.format(gainsResolved)} XP',
      penaltyText: '${numberFormat.format(penaltiesResolved)} XP',
      rewardRows: componentRows.where((item) => item.amount > 0).toList(),
      penaltyRows: penaltyRows,
      challengeHighlights: challengeHighlights,
      highlights: highlights,
    );
  }

  static List<_XpBreakdownItem> _buildComponentItems(
    List<StoryXpComponent> components,
    AppLocalizations loc,
    NumberFormat numberFormat,
  ) {
    return components
        .map(
          (component) => _XpBreakdownItem(
            title: _componentTitleForCode(component.code, loc),
            subtitle: _componentSubtitleFor(component, loc),
            amount: component.amount,
            valueText: '${_signedValue(component.amount, numberFormat)} XP',
            positive: component.amount >= 0,
          ),
        )
        .toList(growable: false);
  }

  static List<_XpBreakdownItem> _buildPenaltyItems(
    List<StoryXpPenalty> penalties,
    AppLocalizations loc,
    NumberFormat numberFormat,
  ) {
    return penalties
        .map(
          (penalty) => _XpBreakdownItem(
            title: _penaltyTitleForType(penalty.type, loc),
            subtitle: _penaltySubtitleFor(penalty, loc),
            amount: penalty.delta,
            valueText: '${_signedValue(penalty.delta, numberFormat)} XP',
            positive: penalty.delta >= 0,
          ),
        )
        .toList(growable: false);
  }

  static String _componentTitleForCode(String code, AppLocalizations loc) {
    switch (code) {
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

  static String? _componentSubtitleFor(
    StoryXpComponent component,
    AppLocalizations loc,
  ) {
    switch (component.code) {
      case 'base_daily':
        final day =
            _toInt(component.metadata['trainingDayIndex']) ??
            _toInt(component.metadata['day']);
        if (day != null && day > 0) {
          return loc.storySessionDailyXpComponentBaseSubtitle(day);
        }
        return null;
      case 'streak_bonus':
        final streak =
            _toInt(component.metadata['streakLength']) ??
            _toInt(component.metadata['streak']);
        if (streak != null && streak > 0) {
          return loc.storySessionDailyXpComponentStreakSubtitle(streak);
        }
        return null;
      case 'training_day_milestone':
        final milestoneDay =
            _toInt(component.metadata['milestoneDay']) ??
            _toInt(component.metadata['day']);
        if (milestoneDay != null && milestoneDay > 0) {
          return loc.storySessionDailyXpComponentMilestoneSubtitle(
            milestoneDay,
          );
        }
        return null;
      default:
        return null;
    }
  }

  static String _penaltyTitleForType(String type, AppLocalizations loc) {
    switch (type) {
      case 'streakBreakPenalty':
        return loc.storySessionDailyXpPenaltyStreakBreak;
      case 'missedWeekPenalty':
        return loc.storySessionDailyXpPenaltyMissedWeek;
      default:
        return loc.storySessionDailyXpPenaltyGeneric;
    }
  }

  static String? _penaltySubtitleFor(
    StoryXpPenalty penalty,
    AppLocalizations loc,
  ) {
    final idleDays = _toInt(penalty.metadata['idleDays']);
    final missedWeek = _toInt(penalty.metadata['missedWeekNumber']);
    if (penalty.type == 'missedWeekPenalty' &&
        missedWeek != null &&
        missedWeek > 0) {
      return loc.storySessionDailyXpPenaltyWeekLabel(missedWeek);
    }
    if (idleDays != null && idleDays > 0) {
      return loc.storySessionDailyXpPenaltyIdleDays(idleDays);
    }
    return null;
  }

  static String _resolveRulesetText(
    StoryDailyXp dailyXp,
    AppLocalizations loc,
  ) {
    final label = _rulesetLabel(loc);
    final rulesetId = dailyXp.rulesetId;
    if (rulesetId == null || rulesetId.isEmpty) {
      return '$label: -';
    }
    final version = dailyXp.rulesetVersion;
    if (version == null) {
      return '$label: $rulesetId';
    }
    return '$label: $rulesetId v$version';
  }

  static String _rewardDetailEmptyMessage(AppLocalizations loc) {
    final locale = loc.localeName.toLowerCase();
    if (locale.startsWith('de')) {
      return 'Keine Belohnungsdetails vorhanden.';
    }
    return 'No reward details available.';
  }

  static String _penaltyDetailEmptyMessage(AppLocalizations loc) {
    final locale = loc.localeName.toLowerCase();
    if (locale.startsWith('de')) {
      return 'Keine Strafen in dieser Session.';
    }
    return 'No penalties in this session.';
  }

  static String _rulesetLabel(AppLocalizations loc) {
    final locale = loc.localeName.toLowerCase();
    if (locale.startsWith('de')) {
      return 'Regelwerk';
    }
    return 'Ruleset';
  }

  static int? _toInt(dynamic raw) {
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim());
    return null;
  }

  static String _shortRewardLabel(AppLocalizations loc) {
    final locale = loc.localeName.toLowerCase();
    if (locale.startsWith('de')) {
      return 'Belohnung';
    }
    return 'Reward';
  }

  static String _rewardDetailTitle(AppLocalizations loc) {
    final locale = loc.localeName.toLowerCase();
    if (locale.startsWith('de')) {
      return 'Belohnung im Detail';
    }
    return 'Reward details';
  }

  static String _penaltyDetailTitle(AppLocalizations loc) {
    final locale = loc.localeName.toLowerCase();
    if (locale.startsWith('de')) {
      return 'Strafen im Detail';
    }
    return 'Penalty details';
  }

  static String _compactPrTitle(String name, AppLocalizations loc) {
    final locale = loc.localeName.toLowerCase();
    if (locale.startsWith('de')) {
      return 'Neuer PR: $name';
    }
    return 'New PR: $name';
  }

  static String _compactFirstExerciseTitle(
    String exercise,
    AppLocalizations loc,
  ) {
    final locale = loc.localeName.toLowerCase();
    if (locale.startsWith('de')) {
      return 'Erstes Mal: $exercise';
    }
    return 'First time: $exercise';
  }

  static String _compactNewDeviceTitle(AppLocalizations loc) {
    final locale = loc.localeName.toLowerCase();
    if (locale.startsWith('de')) {
      return 'Neues Geraet';
    }
    return 'New device';
  }

  static String _challengeFallbackTitle(AppLocalizations loc) {
    final locale = loc.localeName.toLowerCase();
    if (locale.startsWith('de')) {
      return 'Challenge';
    }
    return 'Challenge';
  }

  static String _challengeGoalText(
    StoryChallengeHighlight challenge,
    AppLocalizations loc,
  ) {
    final target = math.max(0, challenge.target);
    switch (challengeGoalTypeFromFirestore(challenge.goalType)) {
      case ChallengeGoalType.deviceSets:
        return loc.challengeDetailGoalDeviceSets(target);
      case ChallengeGoalType.workoutDays:
        return loc.challengeDetailGoalWorkoutFrequency(
          target,
          math.max(1, challenge.durationWeeks),
        );
      case ChallengeGoalType.totalReps:
        return loc.challengeDetailGoalTotalReps(target);
      case ChallengeGoalType.totalVolume:
        return loc.challengeDetailGoalTotalVolume(target);
      case ChallengeGoalType.deviceVariety:
        return loc.challengeDetailGoalDeviceVariety(target);
    }
  }

  static String _challengePeriodText(
    StoryChallengeHighlight challenge,
    AppLocalizations loc,
  ) {
    final until = DateFormat.Md(loc.localeName).format(challenge.end.toLocal());
    final locale = loc.localeName.toLowerCase();
    if (locale.startsWith('de')) {
      return 'bis $until';
    }
    return 'until $until';
  }

  static int _achievementPriorityCompare(
    StoryAchievement a,
    StoryAchievement b,
  ) {
    int priority(StoryAchievementType type) {
      switch (type) {
        case StoryAchievementType.personalRecord:
          return 0;
        case StoryAchievementType.newExercise:
          return 1;
        case StoryAchievementType.newDevice:
          return 2;
        case StoryAchievementType.dailyXp:
          return 3;
      }
    }

    final pa = priority(a.type);
    final pb = priority(b.type);
    if (pa != pb) return pa.compareTo(pb);
    final e1rmA = a.e1rm ?? 0;
    final e1rmB = b.e1rm ?? 0;
    return e1rmB.compareTo(e1rmA);
  }

  static int _challengePriorityCompare(
    StoryChallengeHighlight a,
    StoryChallengeHighlight b,
  ) {
    final completionA = a.isCompleted ? 1 : 0;
    final completionB = b.isCompleted ? 1 : 0;
    if (completionA != completionB) {
      return completionA.compareTo(completionB);
    }
    final ratioCompare = b.progressRatio.compareTo(a.progressRatio);
    if (ratioCompare != 0) {
      return ratioCompare;
    }
    return a.end.compareTo(b.end);
  }

  static String? _prSubtitle(
    StoryAchievement achievement,
    AppLocalizations loc,
  ) {
    final weight = achievement.prWeight;
    final reps = achievement.prReps;
    if (weight != null && reps != null && reps > 0) {
      final number = NumberFormat('#,##0.##', loc.localeName).format(weight);
      final repsText = NumberFormat.decimalPattern(loc.localeName).format(reps);
      return loc.storySessionNewPrSubtitle(number, repsText);
    }
    final e1rm = achievement.e1rm;
    if (e1rm != null && e1rm > 0) {
      return loc.storySessionNewPrFallback(e1rm.toStringAsFixed(1));
    }
    return null;
  }

  static String _signedValue(int value, NumberFormat format) {
    if (value > 0) return '+${format.format(value)}';
    if (value < 0) return '-${format.format(value.abs())}';
    return format.format(0);
  }

  static String _formatDuration(Duration duration) {
    final safeDuration = duration.isNegative ? Duration.zero : duration;
    return formatDurationHm(safeDuration);
  }
}

class _HighlightItem {
  const _HighlightItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accent;
}

class _ChallengeHighlightItem {
  const _ChallengeHighlightItem({
    required this.title,
    required this.goalText,
    required this.progressText,
    required this.progressRatio,
    required this.xpLabel,
    required this.periodText,
    required this.isCompleted,
    required this.accent,
  });

  final String title;
  final String goalText;
  final String progressText;
  final double progressRatio;
  final String xpLabel;
  final String? periodText;
  final bool isCompleted;
  final Color accent;
}

class _XpBreakdownItem {
  const _XpBreakdownItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.valueText,
    required this.positive,
  });

  final String title;
  final String? subtitle;
  final int amount;
  final String valueText;
  final bool positive;
}
