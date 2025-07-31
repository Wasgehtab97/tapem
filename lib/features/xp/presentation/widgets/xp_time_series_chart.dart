import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Defines the selectable time periods for the XP time series chart.
enum XpPeriod { last7Days, last30Days, total }

/// A line chart that visualises the XP progression over time.
///
/// It takes a map of DateTime keys to integer XP values and draws a smooth
/// line with dots at each point. The chart automatically sorts the input
/// data by date. A tooltip appears when hovering or tapping on a point,
/// showing the date and XP value. Colours follow the mint→turquoise→amber
/// gradient defined in the design guidelines.
class XpTimeSeriesChart extends StatelessWidget {
  /// Mapping of dates to XP values. Only the dates relevant for the current
  /// period will be displayed.
  final Map<DateTime, int> data;

  /// The selected time period for the chart. Determines how many points are
  /// shown and how the x-axis labels are formatted.
  final XpPeriod period;

  const XpTimeSeriesChart({Key? key, required this.data, required this.period})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Prepare a sorted list of entries for the selected period.
    final now = DateTime.now();
    DateTime? cutoff;
    switch (period) {
      case XpPeriod.last7Days:
        cutoff = now.subtract(const Duration(days: 6));
        break;
      case XpPeriod.last30Days:
        cutoff = now.subtract(const Duration(days: 29));
        break;
      case XpPeriod.total:
        cutoff = null;
        break;
    }
    final entries =
        data.entries
            .where((e) => cutoff == null || !e.key.isBefore(cutoff))
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    final spots = <FlSpot>[];
    for (int i = 0; i < entries.length; i++) {
      final xp = entries[i].value;
      spots.add(FlSpot(i.toDouble(), xp.toDouble()));
    }

    // Determine axis labels.
    String getFormattedLabel(int index) {
      if (index < 0 || index >= entries.length) return '';
      final date = entries[index].key;
      if (period == XpPeriod.last7Days) {
        return '${date.day}.${date.month}';
      } else if (period == XpPeriod.last30Days) {
        return '${date.day}.${date.month}';
      } else {
        return '${date.month}/${date.year % 100}';
      }
    }

    // Colour of the line: start with mint and end with amber.
    const mint = Color(0xFF00E676);
    const turquoise = Color(0xFF00BCD4);
    const amber = Color(0xFFFFC107);
    final gradientColors = [mint, turquoise, amber];

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: spots.isNotEmpty ? (spots.length - 1).toDouble() : 0,
          minY: 0,
          maxY:
              spots.isNotEmpty
                  ? (spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) *
                      1.2)
                  : 1000,
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final idx = spot.x.toInt();
                  final date = entries[idx].key;
                  final xp = entries[idx].value;
                  return LineTooltipItem(
                    '${date.day}.${date.month}.${date.year}\n$xp XP',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(show: true, horizontalInterval: 500),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                reservedSize: 40,
                showTitles: true,
                interval: 500,
                getTitlesWidget: (value, meta) {
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
                  return Text(
                    getFormattedLabel(value.toInt()),
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
