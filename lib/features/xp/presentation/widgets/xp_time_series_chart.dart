import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Defines the selectable time periods for the XP time series chart.
enum XpPeriod { last7Days, last30Days, total }

/// Represents the XP earned for a muscle group on a specific day.
class XpDailyEntry {
  final DateTime date;
  final int xp;

  const XpDailyEntry({required this.date, required this.xp});
}

/// A line chart that visualises the XP progression per muscle group by day.
///
/// The chart receives daily XP values and renders one point per calendar day
/// in the selected period. Dates without XP are rendered as 0 XP to maintain a
/// continuous timeline. Tooltips show the formatted date and XP value for the
/// touched point.
class XpTimeSeriesChart extends StatelessWidget {
  final List<XpDailyEntry> dailyXp;
  final XpPeriod period;
  final DateFormat dateFormatter;
  final DateTime referenceDate;

  const XpTimeSeriesChart({
    super.key,
    required this.dailyXp,
    required this.period,
    required this.dateFormatter,
    required this.referenceDate,
  });

  @override
  Widget build(BuildContext context) {
    if (dailyXp.isEmpty) {
      final theme = Theme.of(context);
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Noch keine XP',
            style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ) ??
                TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
          ),
        ),
      );
    }

    final normalizedReference =
        DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
    final sorted = dailyXp.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final aggregated = <DateTime, int>{};
    for (final entry in sorted) {
      final normalized =
          DateTime(entry.date.year, entry.date.month, entry.date.day);
      aggregated[normalized] = (aggregated[normalized] ?? 0) + entry.xp;
    }
    final earliest = DateTime(
      sorted.first.date.year,
      sorted.first.date.month,
      sorted.first.date.day,
    );
    final latest = DateTime(
      sorted.last.date.year,
      sorted.last.date.month,
      sorted.last.date.day,
    );

    DateTime endDate;
    switch (period) {
      case XpPeriod.last7Days:
        endDate = normalizedReference;
        break;
      case XpPeriod.last30Days:
        endDate = normalizedReference;
        break;
      case XpPeriod.total:
        endDate = latest;
        break;
    }

    DateTime startDate;
    if (period == XpPeriod.total) {
      startDate = earliest;
    } else {
      final days = period == XpPeriod.last7Days ? 6 : 29;
      startDate = endDate.subtract(Duration(days: days));
    }
    if (startDate.isAfter(endDate)) {
      startDate = endDate;
    }

    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);
    final totalDays = normalizedEnd.difference(normalizedStart).inDays;
    final dayCount = totalDays + 1;

    final spots = <FlSpot>[];
    var maxDailyXp = 0;
    for (var i = 0; i < dayCount; i++) {
      final day = normalizedStart.add(Duration(days: i));
      final xp = aggregated[day] ?? 0;
      maxDailyXp = math.max(maxDailyXp, xp);
      spots.add(FlSpot(i.toDouble(), xp.toDouble()));
    }

    final maxY = math.max(
      100.0,
      ((maxDailyXp / 50).ceil() * 50).toDouble(),
    );
    final labelInterval = math.max(1, (dayCount / 5).ceil());

    const mint = Color(0xFF00E676);
    const turquoise = Color(0xFF00BCD4);
    const amber = Color(0xFFFFC107);
    final gradientColors = [mint, turquoise, amber];

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (dayCount - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.round().clamp(0, dayCount - 1);
                  final day = normalizedStart.add(Duration(days: index));
                  final xp = aggregated[day] ?? 0;
                  return LineTooltipItem(
                    '${dateFormatter.format(day)}\n$xp XP',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(show: true, horizontalInterval: 50),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                reservedSize: 40,
                showTitles: true,
                interval: 50,
                getTitlesWidget: (value, meta) {
                  if (value < 0) return const SizedBox.shrink();
                  if (value % 50 != 0) return const SizedBox.shrink();
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= dayCount) {
                    return const SizedBox.shrink();
                  }
                  final isEdge = index == 0 || index == dayCount - 1;
                  if (!isEdge && index % labelInterval != 0) {
                    return const SizedBox.shrink();
                  }
                  final day = normalizedStart.add(Duration(days: index));
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      dateFormatter.format(day),
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              dotData: FlDotData(show: true),
              gradient: LinearGradient(colors: gradientColors),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
