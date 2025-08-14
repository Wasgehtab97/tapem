import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tapem/l10n/app_localizations.dart';

import 'package:tapem/core/providers/history_provider.dart';
import 'package:tapem/features/history/domain/models/workout_log.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';
import 'package:tapem/features/training_details/presentation/widgets/session_exercise_card.dart';

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
      // jetzt mit benannten Parametern
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
    if (e1rmPoints.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.historyTitle(widget.deviceId))),
        body: const Center(child: Text('Keine Daten')),
      );
    }
    final dates = e1rmPoints.map((e) => e.date).toList();
    final values = e1rmPoints.map((e) => e.value).toList();
    final spots = values
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    final minY = values.reduce((a, b) => a < b ? a : b) * 0.9;
    final maxY = values.reduce((a, b) => a > b ? a : b) * 1.1;

    final sessionPoints = prov.sessionsChart;
    final sessionDates = sessionPoints.map((e) => e.date).toList();
    final sessionValues = sessionPoints.map((e) => e.value).toList();
    final sessionSpots = sessionValues
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    final sessionsMaxY = sessionValues.isEmpty
        ? 1.0
        : sessionValues.reduce((a, b) => a > b ? a : b) * 1.1;

    // Gruppieren der Logs für die Listendarstellung
    final sessionsMap = <String, List<WorkoutLog>>{};
    for (var log in prov.logs) {
      sessionsMap.putIfAbsent(log.sessionId, () => []).add(log);
    }
    final sessionEntries = sessionsMap.entries.toList()
      ..sort((a, b) {
        return b.value.first.timestamp.compareTo(a.value.first.timestamp);
      });

    final localeString = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(title: Text(loc.historyTitle(widget.deviceId))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.historyChartTitle,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY - minY) / 5,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= dates.length) {
                            return const SizedBox();
                          }
                          final d = dates[i];
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat.Md(localeString).format(d),
                              style: textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: (maxY - minY) / 5,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
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
            const SizedBox(height: 16),
            Text(
              loc.historyOverviewTitle,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _kpiBadge(loc.historyWorkouts, prov.workoutCount.toString()),
                _kpiBadge(loc.historySetsAvg,
                    prov.setsPerSessionAvg.toStringAsFixed(1)),
                _kpiBadge(
                    loc.historyHeaviest, '${prov.heaviest.toStringAsFixed(1)} kg'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              loc.historySessionsChartTitle,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: sessionsMaxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: sessionsMaxY / 5,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= sessionDates.length) {
                            return const SizedBox();
                          }
                          final d = sessionDates[i];
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat.Md(localeString).format(d),
                              style: textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: sessionsMaxY / 5,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
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
            const SizedBox(height: 16),
            Text(
              loc.historyListTitle,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: sessionEntries.length,
                itemBuilder: (_, idx) {
                  final logs = [...sessionEntries[idx].value]
                    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
                  final titleDate = DateFormat.yMMMMd(
                    localeString,
                  ).format(logs.first.timestamp);

                  final sets = logs
                      .map((l) => SessionSet(weight: l.weight, reps: l.reps))
                      .toList();
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ExpansionTile(
                      title: Text(
                        titleDate,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      children: [
                        SessionExerciseCard(
                          deviceName: widget.deviceId,
                          sets: sets,
                          padding: const EdgeInsets.all(12),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiBadge(String label, String value) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
