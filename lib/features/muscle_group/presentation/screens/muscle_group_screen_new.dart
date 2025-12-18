import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/muscle_group_provider.dart';
import '../../../../core/providers/xp_provider.dart';
import '../../../rank/domain/services/level_service.dart';
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

    if (prov.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (prov.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Muskelgruppen')),
        body: Center(child: Text(prov.error!)),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Muskelgruppen')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Verteilung deiner XP',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (totalXp <= 0)
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Sammle erste Trainingseinheiten, um deine Muskelverteilung zu sehen.',
                    ),
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
                const SizedBox(height: 24),
                Text(
                  'Details nach Muskelgruppe',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
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
                  );
                }),
              ],
            ],
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

class _MuscleStatTile extends StatelessWidget {
  const _MuscleStatTile({
    required this.label,
    required this.levelLabel,
    required this.totalXpLabel,
    required this.shareLabel,
    required this.levelProgress,
    required this.progressLabel,
    required this.maxedOut,
  });

  final String label;
  final String levelLabel;
  final String totalXpLabel;
  final String shareLabel;
  final double levelProgress;
  final String progressLabel;
  final bool maxedOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Text(
                    levelLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$totalXpLabel · $shareLabel',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              child: LinearProgressIndicator(
                value: levelProgress.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  maxedOut
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              progressLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: maxedOut
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
