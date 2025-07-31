import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tapem/l10n/app_localizations.dart';

import 'package:tapem/core/providers/history_provider.dart';
import 'package:tapem/features/history/domain/models/workout_log.dart';

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

    // Gruppieren und Chart-Logik
    final sessionsMap = <String, List<WorkoutLog>>{};
    for (var log in prov.logs) {
      sessionsMap.putIfAbsent(log.sessionId, () => []).add(log);
    }
    final sessionEntries =
        sessionsMap.entries.toList()..sort((a, b) {
          return b.value.first.timestamp.compareTo(a.value.first.timestamp);
        });

    final dates = <DateTime>[];
    final values = <double>[];
    for (var e in sessionEntries) {
      final logs = [...e.value]
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      dates.add(logs.first.timestamp);
      final e1rms = logs.map((l) => l.weight * (1 + l.reps / 30));
      values.add(e1rms.reduce(max));
    }

    if (values.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.historyTitle(widget.deviceId))),
        body: const Center(child: Text('Keine Daten')),
      );
    }

    final spots =
        values
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value))
            .toList();
    final minY = values.reduce(min) * 0.9;
    final maxY = values.reduce(max) * 1.1;

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

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ExpansionTile(
                      title: Text(
                        titleDate,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      children:
                          logs
                              .map(
                                (log) => ListTile(
                                  title: Text(
                                    '${log.weight} kg × ${log.reps} Wdh.',
                                  ),
                                  subtitle: Row(
                                    children: [
                                      if (log.rir != null)
                                        Text('RIR ${log.rir}'),
                                      if (log.note != null &&
                                          log.note!.isNotEmpty) ...[
                                        if (log.rir != null)
                                          const SizedBox(width: 8),
                                        Expanded(child: Text(log.note!)),
                                      ],
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
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
}
