import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/muscle_group_provider.dart';
import '../../../../core/providers/xp_provider.dart';
import '../../../../core/theme/app_brand_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../rank/domain/services/level_service.dart';
import '../../../rank/presentation/widgets/ranking_ui.dart';
import '../../domain/models/muscle_group.dart';
import '../widgets/muscle_group_radar_chart.dart';
import '../../../../ui/muscles/muscle_group_display.dart';

class MuscleGroupScreenNew extends ConsumerStatefulWidget {
  const MuscleGroupScreenNew({Key? key}) : super(key: key);

  @override
  ConsumerState<MuscleGroupScreenNew> createState() =>
      _MuscleGroupScreenNewState();
}

class _MuscleGroupScreenNewState extends ConsumerState<MuscleGroupScreenNew> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final muscleProv = ref.read(muscleGroupProvider);
      final auth = ref.read(authControllerProvider);
      final xpProv = ref.read(xpProvider);
      muscleProv.loadGroups(context);
      final uid = auth.userId;
      final gym = auth.gymCode;
      if (uid != null && gym != null) {
        xpProv.watchMuscleXp(gym, uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = ref.watch(muscleGroupProvider);
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final accent = brandTheme?.outline ?? theme.colorScheme.secondary;

    if (prov.isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B1221),
        appBar: AppBar(
          title: Text(
            'Muskelranking',
            style: GoogleFonts.orbitron(
              textStyle: theme.textTheme.titleLarge,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (prov.error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B1221),
        appBar: AppBar(
          title: Text(
            'Muskelranking',
            style: GoogleFonts.orbitron(
              textStyle: theme.textTheme.titleLarge,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        body: Center(
          child: Text(
            prov.error!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      );
    }

    final xpProv = ref.watch(xpProvider);
    final groups = prov.groups;

    const orderedRegions = [
      MuscleRegion.brust,
      MuscleRegion.schulter,
      MuscleRegion.nacken,
      MuscleRegion.ruecken,
      MuscleRegion.bizeps,
      MuscleRegion.trizeps,
      MuscleRegion.bauch,
      MuscleRegion.quadrizeps,
      MuscleRegion.hamstrings,
      MuscleRegion.gluteus,
      MuscleRegion.waden,
    ];

    final regionXp = <MuscleRegion, double>{
      for (final region in orderedRegions) region: 0,
    };

    for (final entry in xpProv.muscleXp.entries) {
      final grp = groups.firstWhereOrNull((g) => g.id == entry.key);
      MuscleRegion? region;
      if (grp != null) {
        region = grp.region;
      } else {
        region = MuscleRegion.values.firstWhereOrNull(
          (r) => r.name == entry.key,
        );
      }
      if (region != null) {
        regionXp[region] = (regionXp[region] ?? 0) + entry.value.toDouble();
      }
    }

    double totalXp = 0;
    for (final value in regionXp.values) {
      totalXp += value;
    }

    final percentageByRegion = <MuscleRegion, double>{
      for (final region in orderedRegions)
        region: totalXp > 0 ? (regionXp[region]! / totalXp) : 0,
    };

    String labelForRegion(MuscleRegion region) {
      final regionGroups = groups.where((g) => g.region == region);
      final canonical = regionGroups.firstWhereOrNull(
        (g) => g.name.trim().toLowerCase() == region.name.toLowerCase(),
      );
      final fallback = canonical ?? regionGroups.firstOrNull;
      return displayNameForMuscleGroup(region, fallback);
    }

    final chartEntries = [
      for (final region in orderedRegions)
        MuscleRadarEntry(
          label: labelForRegion(region),
          percentage: percentageByRegion[region]!.clamp(0.0, 1.0),
        ),
    ];

    final localeName = Localizations.localeOf(context).toString();
    final numberFormat = NumberFormat.decimalPattern(localeName);

    const xpPerLevel = LevelService.xpPerLevel;
    const maxLevel = LevelService.maxLevel;

    final stats = [
      for (final region in orderedRegions)
        () {
          final xpValue = (regionXp[region] ?? 0).toDouble();
          final xpTotal = xpValue.round();
          var level = (xpTotal ~/ xpPerLevel) + 1;
          if (level > maxLevel) {
            level = maxLevel;
          }
          final reachedMaxLevel = level >= maxLevel;
          final xpInLevel = reachedMaxLevel ? 0 : xpTotal % xpPerLevel;
          final levelProgress = reachedMaxLevel
              ? 1.0
              : (xpInLevel / xpPerLevel).clamp(0.0, 1.0);
          return _MuscleStat(
            region: region,
            label: labelForRegion(region),
            xp: xpValue,
            percentage: percentageByRegion[region] ?? 0,
            level: level,
            xpInLevel: xpInLevel,
            levelProgress: levelProgress,
            reachedMaxLevel: reachedMaxLevel,
          );
        }(),
    ];

    final chartExtent = math.max(
      280.0,
      math.min(MediaQuery.of(context).size.width - 32, 420.0),
    );

    final orderedStats = [...stats]..sort((a, b) => b.xp.compareTo(a.xp));
    final strongest = orderedStats.isEmpty ? null : orderedStats.first;
    final weakest = orderedStats.isEmpty ? null : orderedStats.last;
    final nextLevelTarget = orderedStats
        .where((stat) => !stat.reachedMaxLevel)
        .fold<_MuscleNextLevelTarget?>(null, (best, stat) {
          final xpToNext = LevelService.xpPerLevel - stat.xpInLevel;
          if (best == null || xpToNext < best.xpToNextLevel) {
            return _MuscleNextLevelTarget(
              label: stat.label,
              nextLevel: stat.level + 1,
              xpToNextLevel: xpToNext,
            );
          }
          return best;
        });
    final isDe = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase().startsWith('de');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Muskelranking',
          style: GoogleFonts.orbitron(
            textStyle: theme.textTheme.titleLarge,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
      body: RankingGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MuscleHeroCard(
                  totalXpLabel: numberFormat.format(totalXp.round()),
                  strongestLabel: strongest?.label ?? '-',
                  weakestLabel: weakest?.label ?? '-',
                  accent: accent,
                ),
                const SizedBox(height: AppSpacing.md),
                RankingGoalSignalCard(
                  accent: accent,
                  title: isDe
                      ? 'Nächstes Muskel-Level in'
                      : 'Next muscle level in',
                  value: nextLevelTarget == null
                      ? 'Max'
                      : '${numberFormat.format(nextLevelTarget.xpToNextLevel)} XP',
                  subtitle: nextLevelTarget == null
                      ? (isDe
                            ? 'Alle Muskelgruppen sind auf Max-Level.'
                            : 'All muscle groups are at max level.')
                      : (isDe
                            ? '${nextLevelTarget.label} -> Level ${nextLevelTarget.nextLevel}'
                            : '${nextLevelTarget.label} -> Level ${nextLevelTarget.nextLevel}'),
                  icon: Icons.insights_rounded,
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
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
                    border: Border.all(color: accent.withOpacity(0.24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.34),
                        blurRadius: 22,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verteilung deiner XP',
                        style: GoogleFonts.orbitron(
                          textStyle: theme.textTheme.titleMedium,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (totalXp <= 0)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withOpacity(
                              0.04,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppRadius.button,
                            ),
                            border: Border.all(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.1,
                              ),
                            ),
                          ),
                          child: Text(
                            'Sammle erste Trainingseinheiten, um deine Muskelverteilung zu sehen.',
                            style: GoogleFonts.rajdhani(
                              textStyle: theme.textTheme.bodyLarge,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        Center(
                          child: SizedBox(
                            height: chartExtent,
                            width: chartExtent,
                            child: MuscleGroupRadarChart(entries: chartEntries),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Details nach Muskelgruppe',
                  style: GoogleFonts.orbitron(
                    textStyle: theme.textTheme.titleMedium,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...stats.map((stat) {
                  final xpLabel = numberFormat.format(stat.xp.round());
                  final shareLabel =
                      '${(stat.percentage * 100).toStringAsFixed(1)} % Anteil';
                  final level = stat.level;
                  final isMaxLevel = stat.reachedMaxLevel;
                  final progressLabel = isMaxLevel
                      ? 'Maximales Level erreicht'
                      : 'Fortschritt zu Level ${level + 1}: '
                            '${numberFormat.format(stat.xpInLevel)} / '
                            '${numberFormat.format(LevelService.xpPerLevel)} XP';
                  return _MuscleStatTile(
                    label: stat.label,
                    levelLabel: 'Level $level',
                    totalXpLabel: '$xpLabel XP',
                    shareLabel: shareLabel,
                    levelProgress: stat.levelProgress,
                    progressLabel: progressLabel,
                    maxedOut: isMaxLevel,
                    accent: accent,
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MuscleStat {
  const _MuscleStat({
    required this.region,
    required this.label,
    required this.xp,
    required this.percentage,
    required this.level,
    required this.xpInLevel,
    required this.levelProgress,
    required this.reachedMaxLevel,
  });

  final MuscleRegion region;
  final String label;
  final double xp;
  final double percentage;
  final int level;
  final int xpInLevel;
  final double levelProgress;
  final bool reachedMaxLevel;
}

class _MuscleNextLevelTarget {
  const _MuscleNextLevelTarget({
    required this.label,
    required this.nextLevel,
    required this.xpToNextLevel,
  });

  final String label;
  final int nextLevel;
  final int xpToNextLevel;
}

class _MuscleHeroCard extends StatelessWidget {
  const _MuscleHeroCard({
    required this.totalXpLabel,
    required this.strongestLabel,
    required this.weakestLabel,
    required this.accent,
  });

  final String totalXpLabel;
  final String strongestLabel;
  final String weakestLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return RankingHeroCard(
      accent: accent,
      shadowOpacity: 0,
      child: Row(
        children: [
          Expanded(
            child: RankingHeroStatTile(label: 'Gesamt XP', value: totalXpLabel),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: RankingHeroStatTile(
              label: 'Staerkste Zone',
              value: strongestLabel,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: RankingHeroStatTile(
              label: 'Schwaechste Zone',
              value: weakestLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _MuscleStatTile extends StatelessWidget {
  const _MuscleStatTile({
    required this.label,
    required this.levelLabel,
    required this.totalXpLabel,
    required this.shareLabel,
    required this.levelProgress,
    required this.progressLabel,
    required this.maxedOut,
    required this.accent,
  });

  final String label;
  final String levelLabel;
  final String totalXpLabel;
  final String shareLabel;
  final double levelProgress;
  final String progressLabel;
  final bool maxedOut;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface.withOpacity(0.95),
            theme.colorScheme.surface.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.rajdhani(
                    textStyle: theme.textTheme.titleMedium,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  borderRadius: const BorderRadius.all(Radius.circular(999)),
                  border: Border.all(color: accent.withOpacity(0.4)),
                ),
                child: Text(
                  levelLabel,
                  style: GoogleFonts.orbitron(
                    textStyle: theme.textTheme.labelMedium,
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$totalXpLabel · $shareLabel',
            style: GoogleFonts.rajdhani(
              textStyle: theme.textTheme.bodyMedium,
              color: theme.colorScheme.onSurface.withOpacity(0.68),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            child: LinearProgressIndicator(
              value: levelProgress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                maxedOut ? theme.colorScheme.tertiary : accent,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            progressLabel,
            style: GoogleFonts.rajdhani(
              textStyle: theme.textTheme.bodySmall,
              color: maxedOut ? theme.colorScheme.tertiary : accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
