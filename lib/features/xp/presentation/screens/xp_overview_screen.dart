import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_gradient_text.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';
import 'package:tapem/l10n/app_localizations.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/xp_provider.dart';
import '../../../../core/providers/muscle_group_provider.dart';
import '../../../muscle_group/domain/models/muscle_group.dart';
import '../widgets/xp_gauge.dart';
import '../widgets/xp_time_series_chart.dart';
// Graph and heatmap widgets were removed in the simplified design
import 'leaderboard_screen.dart';

/// A revamped XP overview screen that combines gauges, charts and a heatmap.
///
/// Users can see their progress for each muscle region, inspect their XP
/// evolution over time and open a dedicated leaderboard for each region via
/// the included button. The interface uses the dark theme and mint/turquoise
/// colours defined in the style guide.
class XpOverviewScreen extends StatefulWidget {
  const XpOverviewScreen({Key? key}) : super(key: key);

  @override
  State<XpOverviewScreen> createState() => _XpOverviewScreenState();
}

class _XpOverviewScreenState extends State<XpOverviewScreen> {
  XpPeriod _period = XpPeriod.last7Days;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final xpProv = context.read<XpProvider>();
    final muscleProv = context.read<MuscleGroupProvider>();
    final uid = auth.userId;
    final gymId = auth.gymCode;
    if (uid != null && gymId != null) {
      xpProv.watchDayXp(uid, DateTime.now());
      xpProv.watchMuscleXp(gymId, uid);
      xpProv.watchMuscleDailyXp(gymId, uid);
      xpProv.watchTrainingDays(uid);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        muscleProv.ensureLoaded(context);
      });
    }
  }

  String _regionLabel(
    MuscleRegion region,
    MuscleGroupProvider provider,
  ) {
    final group = provider.groups.firstWhereOrNull((g) => g.region == region);
    if (group != null && group.name.trim().isNotEmpty) {
      return group.name.trim();
    }
    final raw = region.name;
    if (raw.isEmpty) return raw;
    return raw[0].toUpperCase() + raw.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final xpProv = context.watch<XpProvider>();
    final muscleProv = context.watch<MuscleGroupProvider>();
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final borderColor =
        brandTheme?.outline.withOpacity(0.22) ?? theme.colorScheme.onSurface.withOpacity(0.12);
    final highlightGradient = brandTheme?.gradient ?? AppGradients.brandGradient;
    final locale = Localizations.localeOf(context).toString();
    final numberFormatter = NumberFormat.decimalPattern(locale);
    final dateFormatter = DateFormat.Md(locale);
    final now = DateTime.now();
    final referenceDate = DateTime(now.year, now.month, now.day);

    DateTime? parseDayKey(String key) {
      if (key.isEmpty) return null;
      try {
        final parts = key.split('-');
        if (parts.length == 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
        return DateTime.parse(key);
      } catch (_) {
        return null;
      }
    }

    // Map region→total XP by summing all muscle group entries and mapping to
    // their region via MuscleGroupProvider.
    final Map<MuscleRegion, int> regionXp = {
      for (final region in MuscleRegion.values) region: 0,
    };
    final regionDailyXp = <MuscleRegion, Map<DateTime, int>>{
      for (final region in MuscleRegion.values) region: <DateTime, int>{},
    };

    final muscleDailyXp = xpProv.muscleDailyXp;
    final regionCache = <String, MuscleRegion?>{};

    for (final entry in xpProv.muscleXp.entries) {
      final region = regionCache.putIfAbsent(entry.key, () {
        final group = muscleProv.groups.firstWhereOrNull(
          (g) => g.id == entry.key,
        );
        if (group != null) {
          return group.region;
        }
        return MuscleRegion.values.firstWhereOrNull(
          (r) => r.name == entry.key,
        );
      });
      if (region != null) {
        regionXp[region] = (regionXp[region] ?? 0) + entry.value;
      }
    }

    muscleDailyXp.forEach((dayKey, muscleMap) {
      final parsed = parseDayKey(dayKey);
      if (parsed == null) {
        return;
      }
      final normalized = DateTime(parsed.year, parsed.month, parsed.day);
      muscleMap.forEach((muscleId, value) {
        if (value == 0) return;
        final region = regionCache.putIfAbsent(muscleId, () {
          final group = muscleProv.groups.firstWhereOrNull(
            (g) => g.id == muscleId,
          );
          if (group != null) {
            return group.region;
          }
          return MuscleRegion.values.firstWhereOrNull(
            (r) => r.name == muscleId,
          );
        });
        if (region != null) {
          final map = regionDailyXp[region]!;
          map[normalized] = (map[normalized] ?? 0) + value;
        }
      });
    });

    final regionDailyEntries = <MuscleRegion, List<XpDailyEntry>>{};
    for (final region in MuscleRegion.values) {
      final entries = regionDailyXp[region]!.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      regionDailyEntries[region] = [
        for (final entry in entries)
          XpDailyEntry(date: entry.key, xp: entry.value),
      ];
    }

    final regions = MuscleRegion.values.toList()
      ..sort((a, b) => (regionXp[b] ?? 0).compareTo(regionXp[a] ?? 0));
    const xpPerLevel = LevelService.xpPerLevel;

    final regionLevel = <MuscleRegion, int>{};
    final regionXpInLevel = <MuscleRegion, int>{};

    for (final region in regions) {
      final total = regionXp[region] ?? 0;
      var level = (total ~/ xpPerLevel) + 1;
      if (level > LevelService.maxLevel) {
        level = LevelService.maxLevel;
      }
      var xpInLevel = total % xpPerLevel;
      if (level >= LevelService.maxLevel) {
        xpInLevel = 0;
      }
      regionLevel[region] = level;
      regionXpInLevel[region] = xpInLevel;
    }

    void openLeaderboard(MuscleRegion region) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LeaderboardScreen(
            title: loc.xpOverviewLeaderboardTitle(_regionLabel(region, muscleProv)),
          ),
        ),
      );
    }

    Widget buildSurfaceCard(Widget child, {EdgeInsetsGeometry? padding}) {
      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.32),
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.sm),
          child: child,
        ),
      );
    }

    Widget buildRegionChartsCard() {
      return buildSurfaceCard(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.xpOverviewPeriodLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.72),
                              fontWeight: FontWeight.w600,
                            ) ??
                            TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.72),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loc.muscleGroupTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.background.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<XpPeriod>(
                      value: _period,
                      dropdownColor: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                      iconEnabledColor: highlightGradient.colors.first,
                      items: [
                        DropdownMenuItem(
                          value: XpPeriod.last7Days,
                          child: Text(loc.xpOverviewPeriodLast7Days),
                        ),
                        DropdownMenuItem(
                          value: XpPeriod.last30Days,
                          child: Text(loc.xpOverviewPeriodLast30Days),
                        ),
                        DropdownMenuItem(
                          value: XpPeriod.total,
                          child: Text(loc.xpOverviewPeriodTotal),
                        ),
                      ],
                      onChanged: (value) => setState(() => _period = value ?? _period),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Column(
              children: [
                for (final region in regions)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _regionLabel(region, muscleProv),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Level ${regionLevel[region]}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.62),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${numberFormatter.format(regionXpInLevel[region] ?? 0)} ${loc.xpOverviewTableHeaderXp}',
                            style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      XpTimeSeriesChart(
                        dailyXp: regionDailyEntries[region] ??
                            const <XpDailyEntry>[],
                        period: _period,
                        dateFormatter: dateFormatter,
                        referenceDate: referenceDate,
                      ),
                      if (region != regions.last)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          child: Divider(
                            color: theme.dividerColor.withOpacity(0.3),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      );
    }

    Widget buildGaugeCard() {
      return buildSurfaceCard(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.muscleGroupTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                final gaugeSize = maxWidth > 620
                    ? 156.0
                    : maxWidth > 480
                        ? 140.0
                        : 120.0;
                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final region in regions)
                      XpGauge(
                        currentXp: regionXpInLevel[region] ?? 0,
                        level: regionLevel[region] ?? 1,
                        label: _regionLabel(region, muscleProv),
                        size: gaugeSize,
                        onTap: () => openLeaderboard(region),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
      );
    }

    Widget buildTableCard() {
      return buildSurfaceCard(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${loc.muscleGroupTitle} ${loc.xpOverviewTableHeaderXp}',
              style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.82),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    loc.xpOverviewTableHeaderMuscleGroup,
                    style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.64),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Text(
                  'Level / ${loc.xpOverviewTableHeaderXp}',
                  style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.64),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, thickness: 1),
            for (final region in regions) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _regionLabel(region, muscleProv),
                        style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Level ${regionLevel[region]}',
                          style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.62),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${numberFormatter.format(regionXpInLevel[region] ?? 0)} ${loc.xpOverviewTableHeaderXp}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.72),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (region != regions.last) const Divider(height: 1, thickness: 0.6),
            ],
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: BrandGradientText(
          loc.xpOverviewTitle,
          style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ) ??
              const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: AppFontSizes.title,
              ),
          textAlign: TextAlign.center,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.lg,
          ),
          children: [
            buildGaugeCard(),
            buildTableCard(),
            buildRegionChartsCard(),
          ],
        ),
      ),
    );
  }
}
