import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:tapem/core/theme/design_tokens.dart';

class RankingGradientBackground extends StatelessWidget {
  const RankingGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0B1221),
            const Color(0xFF0E1C2F),
            theme.scaffoldBackgroundColor,
          ],
        ),
      ),
      child: child,
    );
  }
}

class RankingHeroCard extends StatelessWidget {
  const RankingHeroCard({
    super.key,
    required this.accent,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.startColor = const Color(0xFF13243E),
    this.midColor = const Color(0xFF1B355D),
    this.accentOpacity = 0.32,
    this.borderOpacity = 0.2,
    this.shadowOpacity = 0.34,
  });

  final Color accent;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color startColor;
  final Color midColor;
  final double accentOpacity;
  final double borderOpacity;
  final double shadowOpacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [startColor, midColor, accent.withOpacity(accentOpacity)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Colors.white.withOpacity(borderOpacity)),
        boxShadow: shadowOpacity <= 0
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(shadowOpacity),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: child,
    );
  }
}

class RankingSurfacePanel extends StatelessWidget {
  const RankingSurfacePanel({
    super.key,
    required this.child,
    required this.accent,
    this.padding = const EdgeInsets.all(AppSpacing.sm),
    this.borderOpacity = 0.24,
    this.shadowOpacity = 0.34,
  });

  final Widget child;
  final Color accent;
  final EdgeInsetsGeometry padding;
  final double borderOpacity;
  final double shadowOpacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface.withOpacity(0.95),
            theme.colorScheme.surface.withOpacity(0.84),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: accent.withOpacity(borderOpacity)),
        boxShadow: shadowOpacity <= 0
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(shadowOpacity),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: child,
    );
  }
}

class RankingHeroStatTile extends StatelessWidget {
  const RankingHeroStatTile({
    super.key,
    required this.label,
    required this.value,
    this.detail,
  });

  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.rajdhani(
              textStyle: theme.textTheme.labelSmall,
              color: Colors.white.withOpacity(0.78),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.orbitron(
              textStyle: theme.textTheme.titleSmall,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: 2),
            Text(
              detail!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.rajdhani(
                textStyle: theme.textTheme.labelSmall,
                color: Colors.white.withOpacity(0.74),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class RankingSegmentChip extends StatelessWidget {
  const RankingSegmentChip({
    super.key,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.chip - 4),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.chip - 4),
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withOpacity(0.95),
                      accent.withOpacity(0.68),
                    ],
                  )
                : null,
            color: selected
                ? null
                : theme.colorScheme.onSurface.withOpacity(0.04),
            border: Border.all(
              color: selected
                  ? accent.withOpacity(0.95)
                  : theme.colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: GoogleFonts.orbitron(
                textStyle: theme.textTheme.labelMedium,
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface.withOpacity(0.8),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RankingGoalSignalCard extends StatelessWidget {
  const RankingGoalSignalCard({
    super.key,
    required this.accent,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon = Icons.track_changes_rounded,
  });

  final Color accent;
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RankingSurfacePanel(
      accent: accent,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: accent.withOpacity(0.4)),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.rajdhani(
                    textStyle: theme.textTheme.bodyMedium,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface.withOpacity(0.75),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.orbitron(
                    textStyle: theme.textTheme.titleMedium,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.rajdhani(
                      textStyle: theme.textTheme.bodySmall,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.62),
                    ),
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

class RankingNextRankSignalCard extends StatelessWidget {
  const RankingNextRankSignalCard({
    super.key,
    required this.accent,
    required this.rank,
    required this.xpToNextRank,
    required this.participantCount,
    this.loading = false,
  });

  final Color accent;
  final int? rank;
  final int? xpToNextRank;
  final int participantCount;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final localeName = locale.toString();
    final numberFormat = NumberFormat.decimalPattern(localeName);
    final isDe = locale.languageCode.toLowerCase().startsWith('de');

    final title = isDe ? 'Aktueller Rang' : 'Current rank';
    String value;
    if (loading) {
      value = '...';
    } else if (rank == null) {
      value = '-';
    } else {
      value = '#$rank';
    }

    String subtitle;
    if (loading) {
      subtitle = isDe ? 'Lade Rangsignal...' : 'Loading rank signal...';
    } else if (rank == null) {
      subtitle = isDe ? 'Noch nicht in der Rangliste.' : 'Not yet ranked.';
    } else {
      final participants = numberFormat.format(participantCount);
      subtitle = isDe
          ? 'Aktuell Rang #$rank von $participants.'
          : 'Currently rank #$rank of $participants.';
    }

    return RankingGoalSignalCard(
      accent: accent,
      title: title,
      value: value,
      subtitle: subtitle,
      icon: Icons.trending_up_rounded,
    );
  }
}
