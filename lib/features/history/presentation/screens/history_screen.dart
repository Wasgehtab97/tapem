import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:tapem/core/providers/history_provider.dart';
import 'package:tapem/core/utils/nice_scale.dart';
import 'package:tapem/features/history/domain/models/workout_log.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';
import 'package:tapem/features/training_details/presentation/widgets/session_exercise_card.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/widgets/brand_gradient_card.dart';
import 'package:tapem/core/theme/brand_surface_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';

class HistoryScreen extends StatefulWidget {
  final String deviceId;
  const HistoryScreen({Key? key, required this.deviceId}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadHistory(
            context: context,
            deviceId: widget.deviceId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final prov = context.watch<HistoryProvider>();
    final smallStyle = textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(0.6),
      fontSize: 10,
    );

    if (prov.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (prov.error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.historyTitle(widget.deviceId))),
        body: Center(child: Text('${loc.errorPrefix}: ${prov.error}')),
      );
    }

    final e1rmPoints = prov.e1rmChart;
    final sessionPoints = prov.sessionsChart;
    final localeString = Localizations.localeOf(context).toString();

    final e1rmValues = e1rmPoints.map((e) => e.value).toList();
    final e1rmScale = NiceScale.fromValues(e1rmValues,
        tickCount: 6, clampMinZero: true);
    final e1rmSpots = e1rmValues
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    final e1rmDateInterval =
        e1rmPoints.isEmpty ? 1 : (e1rmPoints.length / 6).ceil().clamp(1, e1rmPoints.length);

    final sessionValues = sessionPoints.map((e) => e.value).toList();
    final sessionScale = NiceScale.fromValues(sessionValues,
        tickCount: 6, forceMinZero: true);
    final sessionSpots = sessionValues
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    final sessionDateInterval = sessionPoints.isEmpty
        ? 1
        : (sessionPoints.length / 6).ceil().clamp(1, sessionPoints.length);

    final sessionsMap = <String, List<WorkoutLog>>{};
    for (var log in prov.logs) {
      sessionsMap.putIfAbsent(log.sessionId, () => []).add(log);
    }
    final sessionEntries = sessionsMap.entries.toList()
      ..sort((a, b) {
        return b.value.first.timestamp.compareTo(a.value.first.timestamp);
      });

    Widget buildE1rmChart() {
      if (e1rmPoints.isEmpty) {
        return SizedBox(
            height: 200,
            child: Center(child: Text(loc.historyNoData, style: textTheme.bodySmall)));
      }
      final dates = e1rmPoints.map((e) => e.date).toList();
      return Semantics(
        label: loc.historyE1rmChartSemantics,
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: e1rmScale.min,
              maxY: e1rmScale.max,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: e1rmScale.tickSpacing,
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  axisNameWidget: Text(loc.historyAxisDate, style: smallStyle),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: e1rmDateInterval.toDouble(),
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= dates.length) {
                        return const SizedBox();
                      }
                      final d = dates[i];
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          DateFormat.Md(localeString).format(d),
                          style: smallStyle,
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: Text(loc.historyAxisE1rm, style: smallStyle),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: e1rmScale.tickSpacing,
                    getTitlesWidget: (value, meta) => Text(
                      value.toStringAsFixed(0),
                      style: smallStyle,
                    ),
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: e1rmSpots,
                  isCurved: true,
                  curveSmoothness: 0.2,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
              lineTouchData: LineTouchData(enabled: false),
            ),
          ),
        ),
      );
    }

    Widget buildSessionsChart() {
      if (sessionPoints.isEmpty) {
        return SizedBox(
            height: 200,
            child: Center(child: Text(loc.historyNoData, style: textTheme.bodySmall)));
      }
      final dates = sessionPoints.map((e) => e.date).toList();
      return Semantics(
        label: loc.historySessionsChartSemantics,
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: sessionScale.min,
              maxY: sessionScale.max,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: sessionScale.tickSpacing,
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  axisNameWidget: Text(loc.historyAxisDate, style: smallStyle),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: sessionDateInterval.toDouble(),
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= dates.length) {
                        return const SizedBox();
                      }
                      final d = dates[i];
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          DateFormat.Md(localeString).format(d),
                          style: smallStyle,
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: Text(loc.historyAxisSessions, style: smallStyle),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: sessionScale.tickSpacing,
                    getTitlesWidget: (value, meta) => Text(
                      value.toStringAsFixed(0),
                      style: smallStyle,
                    ),
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: sessionSpots,
                  isCurved: true,
                  curveSmoothness: 0.2,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
              lineTouchData: LineTouchData(enabled: false),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(loc.historyTitle(widget.deviceId))),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    loc.historyOverviewTitle,
                    style:
                        textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _kpiRing(loc.historyWorkouts, prov.workoutCount.toString()),
                      _kpiRing(loc.historySetsAvg,
                          prov.setsPerSessionAvg.toStringAsFixed(1)),
                      _kpiRing(loc.historyHeaviest,
                          '${prov.heaviest.toStringAsFixed(1)} kg'),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.historyChartTitle,
                    style:
                        textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  buildE1rmChart(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.historySessionsChartTitle,
                    style:
                        textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  buildSessionsChart(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Text(
                loc.historyListTitle,
                style:
                    textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, idx) {
                final logs = [...sessionEntries[idx].value]
                  ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
                final titleDate = DateFormat.yMMMMd(localeString)
                    .format(logs.first.timestamp);

                final sets = logs
                    .map((l) => SessionSet(weight: l.weight, reps: l.reps))
                    .toList();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _HistoryExpansionTile(
                    title: titleDate,
                    child: SessionExerciseCard(
                      deviceName: widget.deviceId,
                      sets: sets,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                );
              },
              childCount: sessionEntries.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _kpiRing(String label, String value) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: $value',
      child: SizedBox(
        width: 80,
        height: 80,
        child: BrandGradientCard(
          borderRadius: BorderRadius.circular(40),
          padding: EdgeInsets.zero,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onPrimary.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryExpansionTile extends StatefulWidget {
  final String title;
  final Widget child;
  const _HistoryExpansionTile({required this.title, required this.child});

  @override
  State<_HistoryExpansionTile> createState() => _HistoryExpansionTileState();
}

class _HistoryExpansionTileState extends State<_HistoryExpansionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.extension<BrandSurfaceTheme>();
    final baseRadius = surface?.radius as BorderRadius? ?? BorderRadius.circular(AppRadius.card);
    final bottomRadius = BorderRadius.only(
      bottomLeft: baseRadius.bottomLeft,
      bottomRight: baseRadius.bottomRight,
    );
    final onPrimary = theme.colorScheme.onPrimary;

    return Column(
      children: [
        BrandGradientHeader(
          expanded: _expanded,
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: onPrimary),
                ),
              ),
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: onPrimary,
              ),
            ],
          ),
        ),
        if (_expanded)
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: bottomRadius,
            ),
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: widget.child,
          ),
      ],
    );
  }
}

