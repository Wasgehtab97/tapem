import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        muscleProv.loadGroups(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final xpProv = context.watch<XpProvider>();
    final muscleProv = context.watch<MuscleGroupProvider>();
    final loc = AppLocalizations.of(context)!;

    // Map region→total XP by summing all muscle group entries and mapping to
    // their region via MuscleGroupProvider.
    final Map<MuscleRegion, int> regionXp = {};
    for (final entry in xpProv.muscleXp.entries) {
      MuscleRegion? region;
      final group = muscleProv.groups.firstWhereOrNull(
        (g) => g.id == entry.key,
      );
      if (group != null) {
        region = group.region;
      } else {
        // Fallback: try to interpret the key as a region name.
        region = MuscleRegion.values.firstWhereOrNull(
          (r) => r.name == entry.key,
        );
      }
      if (region != null) {
        regionXp[region] = (regionXp[region] ?? 0) + entry.value as int;
      }
    }

    // No time series or heatmap calculation needed in the simplified design.

    void openLeaderboard(MuscleRegion region) {
      // Fetch entries callback: aggregate XP per user for this region.
      Future<List<LeaderboardEntry>> fetchEntries(XpPeriod period) async {
        // This is a placeholder implementation. In a real app you would
        // delegate to a repository or cloud function that aggregates XP
        // per user for the selected muscle region and period.
        // For now, return an empty list.
        return [];
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => LeaderboardScreen(
                title: loc.xpOverviewLeaderboardTitle(region.name),
                fetchEntries: fetchEntries,
              ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(loc.xpOverviewTitle),
        backgroundColor: const Color(0xFF121212),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time period selector and chart.
            Row(
              children: [
                Text(
                  loc.xpOverviewPeriodLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(width: 8),
                DropdownButton<XpPeriod>(
                  value: _period,
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: const TextStyle(color: Colors.white),
                  underline: const SizedBox.shrink(),
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
                  onChanged:
                      (value) => setState(() => _period = value ?? _period),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              loc.muscleGroupTitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            // Wrap gauges for each region.
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final region in MuscleRegion.values)
                  XpGauge(
                    currentXp: regionXp[region] ?? 0,
                    level: ((regionXp[region] ?? 0) / 1000).floor(),
                    label: region.name,
                    size: 100,
                    onTap: () => openLeaderboard(region),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            DataTable(
              columns: [
                DataColumn(label: Text(loc.xpOverviewTableHeaderMuscleGroup)),
                DataColumn(label: Text(loc.xpOverviewTableHeaderXp)),
              ],
              rows: [
                for (final region in MuscleRegion.values)
                  DataRow(
                    cells: [
                      DataCell(Text(region.name)),
                      DataCell(Text('${regionXp[region] ?? 0}')),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
