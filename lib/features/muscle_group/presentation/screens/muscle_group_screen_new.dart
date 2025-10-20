import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/muscle_group_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/xp_provider.dart';
import '../../domain/models/muscle_group.dart';
import '../widgets/muscle_group_radar_chart.dart';
import '../../../../ui/muscles/muscle_group_display.dart';

class MuscleGroupScreenNew extends StatefulWidget {
  const MuscleGroupScreenNew({Key? key}) : super(key: key);

  @override
  State<MuscleGroupScreenNew> createState() => _MuscleGroupScreenNewState();
}

class _MuscleGroupScreenNewState extends State<MuscleGroupScreenNew> {
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
    final prov = context.watch<MuscleGroupProvider>();

    if (prov.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (prov.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Muskelgruppen')),
        body: Center(child: Text(prov.error!)),
      );
    }

    final xpProv = context.watch<XpProvider>();
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

    String _labelForRegion(MuscleRegion region) {
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
          label: _labelForRegion(region),
          percentage: percentageByRegion[region]!.clamp(0.0, 1.0),
        ),
    ];

    final localeName = Localizations.localeOf(context).toString();
    final numberFormat = NumberFormat.decimalPattern(localeName);

    final stats = [
      for (final region in orderedRegions)
        _MuscleStat(
          region: region,
          label: _labelForRegion(region),
          xp: regionXp[region] ?? 0,
          percentage: percentageByRegion[region] ?? 0,
        ),
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
                  final percentLabel = (stat.percentage * 100).toStringAsFixed(1);
                  return _MuscleStatTile(
                    label: stat.label,
                    xpLabel: '$xpLabel XP',
                    percentage: stat.percentage.clamp(0.0, 1.0),
                    percentageLabel: '$percentLabel %',
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
                Text(
                  percentageLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              xpLabel,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              child: LinearProgressIndicator(
                value: percentage.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
