import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Defines the selectable time periods for the XP time series chart.
enum XpPeriod { last7Days, last30Days, total }

/// Represents XP delta on a specific calendar day.
class XpDailyEntry {
  final DateTime date;
  final int xp;

  const XpDailyEntry({required this.date, required this.xp});
}

/// A line chart that visualises cumulative XP progression over time.
///
/// The chart receives day-based XP deltas and renders one point per calendar
/// day in the selected period. Dates without XP keep the previous cumulative
/// value, resulting in a flat line instead of dropping to zero.
class XpTimeSeriesChart extends StatelessWidget {
  final List<XpDailyEntry> dailyXp;
  final XpPeriod period;
  final DateFormat dateFormatter;
  final DateTime referenceDate;
  final int? anchorTotalXp;

  const XpTimeSeriesChart({
    super.key,
    required this.dailyXp,
    required this.period,
    required this.dateFormatter,
    required this.referenceDate,
    this.anchorTotalXp,
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
            style:
                theme.textTheme.bodySmall?.copyWith(
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

    final normalizedReference = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    final sorted = dailyXp.toList()..sort((a, b) => a.date.compareTo(b.date));
    final aggregated = <DateTime, int>{};
    for (final entry in sorted) {
      final normalized = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      aggregated[normalized] = (aggregated[normalized] ?? 0) + entry.xp;
    }
    final loggedTotalXp = aggregated.values.fold<int>(0, (sum, xp) => sum + xp);
    final baselineOffset = anchorTotalXp == null
        ? 0
        : (anchorTotalXp! - loggedTotalXp);
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
        // Total should end at the latest XP event to avoid a long, confusing
        // flat line when there are training breaks.
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

    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);
    final totalDays = normalizedEnd.difference(normalizedStart).inDays;
    final dayCount = totalDays + 1;

    final preStartTotal =
        aggregated.entries
            .where((entry) => entry.key.isBefore(normalizedStart))
            .fold<int>(0, (sum, entry) => sum + entry.value) +
        baselineOffset;

    final spots = <FlSpot>[];
    var runningTotal = preStartTotal;
    var maxCumulativeXp = preStartTotal;
    var minCumulativeXp = preStartTotal;
    for (var i = 0; i < dayCount; i++) {
      final day = normalizedStart.add(Duration(days: i));
      runningTotal += aggregated[day] ?? 0;
      maxCumulativeXp = math.max(maxCumulativeXp, runningTotal);
      minCumulativeXp = math.min(minCumulativeXp, runningTotal);
      spots.add(FlSpot(i.toDouble(), runningTotal.toDouble()));
    }

    final yPadding = math.max(
      10,
      ((maxCumulativeXp - minCumulativeXp) * 0.12).ceil(),
    );
    final rawMinY = math.max(0.0, (minCumulativeXp - yPadding).toDouble());
    final rawMaxY = math.max(
      rawMinY + 20,
      (maxCumulativeXp + yPadding).toDouble(),
    );
    final yInterval = _niceAxisInterval(rawMaxY - rawMinY);
    final minY = (rawMinY / yInterval).floorToDouble() * yInterval;
    final maxY = (rawMaxY / yInterval).ceilToDouble() * yInterval;
    final labelInterval = math.max(1, (dayCount / 5).ceil());
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );

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
          minY: minY,
          maxY: maxY,
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.round().clamp(0, dayCount - 1);
                  final day = normalizedStart.add(Duration(days: index));
                  final dayDelta = aggregated[day] ?? 0;
                  final total = spot.y.round();
                  final dayDeltaLabel = dayDelta >= 0
                      ? '+${numberFormat.format(dayDelta)}'
                      : numberFormat.format(dayDelta);
                  return LineTooltipItem(
                    '${dateFormatter.format(day)}\n${numberFormat.format(total)} XP ($dayDeltaLabel)',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(show: true, horizontalInterval: yInterval),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                reservedSize: 52,
                showTitles: true,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  if (value < minY - 0.001 || value > maxY + 0.001) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    numberFormat.format(value.round()),
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
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
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
              isCurved: false,
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

double _niceAxisInterval(double range) {
  if (range <= 0) return 10;
  final raw = range / 5;
  final magnitude = math
      .pow(10, (math.log(raw) / math.ln10).floor())
      .toDouble();
  final normalized = raw / magnitude;
  double factor;
  if (normalized <= 1) {
    factor = 1;
  } else if (normalized <= 2) {
    factor = 2;
  } else if (normalized <= 2.5) {
    factor = 2.5;
  } else if (normalized <= 5) {
    factor = 5;
  } else {
    factor = 10;
  }
  return math.max(1, factor * magnitude);
}
