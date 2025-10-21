import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/core/providers/xp_provider.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/features/muscle_group/presentation/widgets/muscle_group_radar_chart.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/muscles/muscle_group_display.dart';

class RankMuscleLevelSection extends StatefulWidget {
  const RankMuscleLevelSection({super.key});

  @override
  State<RankMuscleLevelSection> createState() => _RankMuscleLevelSectionState();
}

class _RankMuscleLevelSectionState extends State<RankMuscleLevelSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final muscleProv = context.read<MuscleGroupProvider>();
      final auth = context.read<AuthProvider>();
      final xpProv = context.read<XpProvider>();
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
    final muscleProv = context.watch<MuscleGroupProvider>();
    final loc = AppLocalizations.of(context)!;

    if (muscleProv.isLoading) {
      return const _RankSectionLoading();
    }

    if (muscleProv.error != null) {
      return _RankSectionError(message: muscleProv.error!);
    }

    final xpProv = context.watch<XpProvider>();
    final groups = muscleProv.groups;

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
      final group = groups.firstWhereOrNull((g) => g.id == entry.key);
      MuscleRegion? region;
      if (group != null) {
        region = group.region;
      } else {
        region = MuscleRegion.values.firstWhereOrNull(
          (r) => r.name == entry.key,
        );
      }
      if (region != null) {
        regionXp[region] = (regionXp[region] ?? 0) + entry.value.toDouble();
      }
    }

    final totalXp = regionXp.values.fold<double>(0, (sum, value) => sum + value);
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

    final stats = [
      for (final region in orderedRegions)
        _MuscleStat(
          region: region,
          label: labelForRegion(region),
          xp: regionXp[region] ?? 0,
          percentage: percentageByRegion[region] ?? 0,
        ),
    ];

    final chartExtent = math.max(
      280.0,
      math.min(MediaQuery.of(context).size.width - 32, 420.0),
    );

    final theme = Theme.of(context);
    final surfaceVariant =
        theme.colorScheme.surfaceVariant.withOpacity(theme.brightness == Brightness.dark ? 0.35 : 0.65);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.rankMuscleLevel,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              loc.xpOverviewTitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (totalXp <= 0)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: const Text(
                  'Sammle erste Trainingseinheiten, um deine Muskelverteilung zu sehen.',
                ),
              )
            else ...[
              Center(
                child: SizedBox(
                  height: chartExtent,
                  width: chartExtent,
                  child: MuscleGroupRadarChart(entries: chartEntries),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Details nach Muskelgruppe',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              ...stats.map((stat) {
                final xpLabel = numberFormat.format(stat.xp.round());
                final percentLabel = (stat.percentage * 100).toStringAsFixed(1);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: _MuscleStatTile(
                    label: stat.label,
                    xpLabel: '$xpLabel XP',
                    percentage: stat.percentage.clamp(0.0, 1.0),
                    percentageLabel: '$percentLabel %',
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _RankSectionLoading extends StatelessWidget {
  const _RankSectionLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _RankSectionError extends StatelessWidget {
  const _RankSectionError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onErrorContainer,
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
  });

  final MuscleRegion region;
  final String label;
  final double xp;
  final double percentage;
}

class _MuscleStatTile extends StatelessWidget {
  const _MuscleStatTile({
    required this.label,
    required this.xpLabel,
    required this.percentage,
    required this.percentageLabel,
  });

  final String label;
  final String xpLabel;
  final double percentage;
  final String percentageLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.onSurface.withOpacity(0.7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              xpLabel,
              style: theme.textTheme.bodyMedium?.copyWith(color: secondary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          percentageLabel,
          style: theme.textTheme.bodySmall?.copyWith(color: secondary),
        ),
      ],
    );
  }
}
