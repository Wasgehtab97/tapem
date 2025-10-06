import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';

/// Defines the selectable time periods for the XP time series chart.
enum XpPeriod { last7Days, last30Days, total }

/// A line chart that visualises the XP progression per session.
///
/// The chart expects a chronological list of XP values where each entry
/// represents the accumulated XP within the current level after completing a
/// session. Level resets at 1000 XP are therefore reflected as drops back to
/// 0. Tooltips show the session index and XP value for each point. Colours
/// follow the mint→turquoise→amber gradient defined in the design guidelines.
class XpTimeSeriesChart extends StatelessWidget {
  /// Ordered list of XP values per session. The first entry represents the
  /// baseline (0 XP) and each following value reflects the XP after a session
  /// has been completed, already applying the level reset at 1000 XP.
  final List<int> xpHistory;

  /// Total number of sessions completed for the respective muscle group.
  final int totalSessions;

  /// The selected time period for the chart. Determines how many points are
  /// shown.
  final XpPeriod period;

  const XpTimeSeriesChart({
    Key? key,
    required this.xpHistory,
    required this.totalSessions,
    required this.period,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (xpHistory.isEmpty) {
      return const SizedBox(height: 200);
    }

    // Determine how many sessions should be displayed for the selected period.
    int? sessionLimit;
    switch (period) {
      case XpPeriod.last7Days:
        sessionLimit = 7;
        break;
      case XpPeriod.last30Days:
        sessionLimit = 30;
        break;
      case XpPeriod.total:
        sessionLimit = null;
        break;
    }

    final requiredLength = sessionLimit != null ? sessionLimit + 1 : xpHistory.length;
    final startIndex = xpHistory.length > requiredLength
        ? xpHistory.length - requiredLength
        : 0;
    final visibleHistory = xpHistory.sublist(startIndex);
    final baseSessionIndex = totalSessions - (visibleHistory.length - 1);

    final spots = <FlSpot>[];
    for (var i = 0; i < visibleHistory.length; i++) {
      spots.add(FlSpot(i.toDouble(), visibleHistory[i].toDouble()));
    }

    String getFormattedLabel(int index) {
      if (index < 0 || index >= visibleHistory.length) return '';
      final sessionNumber = baseSessionIndex + index;
      if (index == 0 && sessionNumber == 0) {
        return 'S0';
      }
      return 'S$sessionNumber';
    }

    // Colour of the line: start with mint and end with amber.
    const mint = Color(0xFF00E676);
    const turquoise = Color(0xFF00BCD4);
    const amber = Color(0xFFFFC107);
    final gradientColors = [mint, turquoise, amber];

    final maxY = LevelService.xpPerLevel.toDouble();
    final lineMaxX = spots.length > 1 ? (spots.length - 1).toDouble() : 1.0;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: lineMaxX,
          minY: 0,
          maxY: maxY,
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final idx = spot.x.toInt();
                  final xp = idx >= 0 && idx < visibleHistory.length
                      ? visibleHistory[idx]
                      : 0;
                  final sessionNumber = baseSessionIndex + idx;
                  return LineTooltipItem(
                    'Session $sessionNumber\n$xp XP',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(show: true, horizontalInterval: 250),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                reservedSize: 40,
                showTitles: true,
                interval: 250,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() % 250 != 0) return const SizedBox.shrink();
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
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  return Text(
                    getFormattedLabel(index),
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
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
