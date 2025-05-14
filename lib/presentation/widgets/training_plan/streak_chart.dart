// lib/presentation/widgets/training_plan/streak_chart.dart

import 'dart:math'; // ← hier hinzugefügt
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Zeichnet eine Linien-Chart, die den Verlauf der täglichen
/// Trainings-Streak über die Zeit zeigt.
///
/// [dates] im Format "YYYY-MM-DD", chronologisch oder unsortiert.
class StreakChart extends StatelessWidget {
  final List<String> dates;
  final double height;

  const StreakChart({
    Key? key,
    required this.dates,
    this.height = 200,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1) Datumsliste in DateTime umwandeln und sortieren
    final parsed = dates
        .map((s) => DateTime.parse(s))
        .toSet()
        .toList()
      ..sort();

    // 2) Streak-Berechnung: für jede Position die Länge der aktuellen Streak
    final spots = <FlSpot>[];
    int currentStreak = 0;
    DateTime? prevDate;
    for (int i = 0; i < parsed.length; i++) {
      final date = parsed[i];
      if (prevDate != null && date.difference(prevDate).inDays == 1) {
        currentStreak++;
      } else {
        currentStreak = 1;
      }
      spots.add(FlSpot(i.toDouble(), currentStreak.toDouble()));
      prevDate = date;
    }

    if (spots.isEmpty) {
      return Center(
        child: Text('Keine Trainingsdaten für Diagramm.'),
      );
    }

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(enabled: true),
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: max(1, spots.length ~/ 5).toDouble(),
                getTitlesWidget: (value, _) {
                  final idx = value.toInt().clamp(0, parsed.length - 1);
                  final d = parsed[idx];
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('${d.day}.${d.month}',
                        style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, interval: 1),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              dotData: FlDotData(show: true),
              color: Theme.of(context).colorScheme.primary,
            )
          ],
        ),
      ),
    );
  }
}
